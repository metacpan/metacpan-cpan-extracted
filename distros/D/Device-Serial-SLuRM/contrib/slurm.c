#include "slurm.h"

#include <stdbool.h>

enum {
  SLURM_SYNC = 0x55,
};

enum {
  SLURM_PKT_META   = 0x00,
    SLURM_PKT_META_RESET    = 0x01,
    SLURM_PKT_META_RESETACK = 0x02,

  SLURM_PKT_NOTIFY = 0x10,

  SLURM_PKT_REQUEST = 0x30,

  SLURM_PKT_RESPONSE = 0xB0,
  SLURM_PKT_ACK      = 0xC0,
  SLURM_PKT_ERR      = 0xE0,
};

static uint8_t _crc8_update(uint8_t *crcp, uint8_t x)
{
  uint16_t crc = (*crcp ^ x) << 8;

  for(uint8_t bit = 0; bit < 8; bit++) {
    if(crc & 0x8000)
      crc ^= 0x8380;
    crc <<= 1;
  }

  *crcp = crc >> 8;
  return x;
}

#ifdef SLURM_MULTIDROP
static uint8_t node_id;

void slurm_configure(uint8_t _id) { node_id = _id; }
#endif

/* Shared stateboard */
static struct {
  enum {
    CMDSTATE_FREE,
    CMDSTATE_EXECUTING,
    CMDSTATE_RESPONDED,
    CMDSTATE_ERRORED,
  } state : 4;
  unsigned int seqno : 4;
  uint8_t resp[16];
  uint8_t resplen;
} cmdslots[4];   // TODO: Make 4 configurable somehow

static int8_t alloc_cmdslot(void)
{
  for(uint8_t i = 0; i < sizeof(cmdslots)/sizeof(cmdslots[0]); i++)
    if(cmdslots[i].state == CMDSTATE_FREE)
      return i;
  return -1;
}

static int8_t find_cmdslot(uint8_t seqno)
{
  for(uint8_t i = 0; i < sizeof(cmdslots)/sizeof(cmdslots[0]); i++)
    if(cmdslots[i].state != CMDSTATE_FREE && cmdslots[i].seqno == seqno)
      return i;
  return -1;
}

/* Transmitter */

static struct {
  uint8_t seqno;

  unsigned int need_send_resetack : 1;

  uint8_t need_retx_cmdslot;
} tx;

static void transmit(uint8_t pktctrl, uint8_t b[], uint8_t len)
{
  do_slurm_tx_start();

  do_slurm_send(SLURM_SYNC); // not part of the CRC

  uint8_t crc = 0;

  /* Header */
  do_slurm_send(_crc8_update(&crc, pktctrl));
#ifdef SLURM_MULTIDROP
  do_slurm_send(_crc8_update(&crc, node_id));
#endif
  do_slurm_send(_crc8_update(&crc, len));
  do_slurm_send(_crc8_update(&crc, crc));

  /* Payload */
  for(uint8_t i = 0; i < len; i++)
    do_slurm_send(_crc8_update(&crc, b[i]));
  do_slurm_send(crc);

  do_slurm_tx_stop();
}

__attribute__((weak)) void do_slurm_tx_start(void) { }
__attribute__((weak)) void do_slurm_tx_stop (void) { }

void slurm_notify(uint8_t b[], uint8_t len)
{
  tx.seqno++; tx.seqno &= 0x0F;

  uint8_t pktctrl = SLURM_PKT_NOTIFY | tx.seqno;

  // TODO: Transmit this twice with more of a delay inbetween
  transmit(pktctrl, b, len);
  transmit(pktctrl, b, len);
}

void slurm_respond(uint8_t seqno, uint8_t b[], uint8_t len)
{
  uint8_t pktctrl = SLURM_PKT_RESPONSE | seqno; // not tx.seqno

  int8_t cmdi = find_cmdslot(seqno);
  if(cmdi != -1) {
    cmdslots[cmdi].state = CMDSTATE_RESPONDED;
    cmdslots[cmdi].resplen = len;
    for(uint8_t i = 0; i < len; i++)
      cmdslots[cmdi].resp[i] = b[i];
  }

  transmit(pktctrl, b, len);
}

void slurm_responderr(uint8_t seqno, uint8_t b[], uint8_t len)
{
  uint8_t pktctrl = SLURM_PKT_ERR | seqno; // not tx.seqno

  int8_t cmdi = find_cmdslot(seqno);
  if(cmdi != -1) {
    cmdslots[cmdi].state = CMDSTATE_ERRORED;
    cmdslots[cmdi].resplen = len;
    for(uint8_t i = 0; i < len; i++)
      cmdslots[cmdi].resp[i] = b[i];
  }

  transmit(pktctrl, b, len);
}

/* Receiver */

#ifdef SLURM_MULTIDROP
#  define HEADERLEN 4
#  define IDX_LEN   2
#else
#  define HEADERLEN 3
#  define IDX_LEN   1
#endif

static struct {
  enum {
    STATE_IDLE,
    STATE_RECV_HEADER,
    STATE_RECV_PAYLOAD,
  } state;

  /* Big enough for header+crc+16 byte payload+crc */
  uint8_t len;
  uint8_t buf[HEADERLEN+16+1];
  uint8_t crc;

  uint8_t seqno;
} rx = {
  .state = STATE_IDLE,
};

static void on_recv(uint8_t pktctrl, uint8_t b[], uint8_t len)
{
  uint8_t seqno = pktctrl & 0x0F;
  pktctrl &= 0xF0;

  if(!pktctrl) {
    switch(seqno) {
      case SLURM_PKT_META_RESET:
      case SLURM_PKT_META_RESETACK:
        if(!len)
          return;
        rx.seqno = (b[0] & 0x0F) | 0x80;
        if(seqno == SLURM_PKT_META_RESETACK)
          break;

        for(uint8_t i = 0; i < sizeof(cmdslots)/sizeof(cmdslots[0]); i++)
          cmdslots[i].state = CMDSTATE_FREE;
        tx.need_send_resetack = 1;
        on_slurm_need_tasks();
        break;
    }
    return;
  }

  bool is_dup = false;
  if(!(pktctrl & 0x80)) {
    // Suppress duplicates for non-META initiator packets
    if(rx.seqno) {
      int8_t seqdiff = seqno - (rx.seqno & 0x0F);
      if(seqdiff < 0) seqdiff += 16;
      if(!seqdiff || seqdiff > 8)
        is_dup = true;
    }

    if(!is_dup)
      rx.seqno = seqno | 0x80; // top bit set to indicate valid
  }

  int8_t cmdi;

  switch(pktctrl) {
    case SLURM_PKT_NOTIFY:
      if(is_dup)
        return;

      on_slurm_notify(b, len);
      break;

    case SLURM_PKT_REQUEST:
      if(is_dup) {
        cmdi = find_cmdslot(seqno);
        if(cmdi < 0)
          return;
        if(cmdslots[cmdi].state < CMDSTATE_RESPONDED)
          return;

        tx.need_retx_cmdslot |= (1 << cmdi);
        on_slurm_need_tasks();
        return;
      }

      cmdi = alloc_cmdslot();
      if(cmdi < 0)
        ; // TODO: send an EBUSY error and don't handle it

      cmdslots[cmdi].state = CMDSTATE_EXECUTING;
      cmdslots[cmdi].seqno = seqno;

      on_slurm_request(seqno, b, len);
      break;

    case SLURM_PKT_ACK:
      cmdi = find_cmdslot(seqno);
      if(cmdi < 0)
        break;

      cmdslots[cmdi].state = CMDSTATE_FREE;
      break;
  }
}

#ifdef SLURM_MULTIDROP_BCAST
static void on_recv_bcast(uint8_t pktctrl, uint8_t b[], uint8_t len)
{
  uint8_t seqno = pktctrl & 0x0F;
  pktctrl &= 0xF0;

  static uint8_t last_seqno;
  if(last_seqno && (seqno == (last_seqno & 0x0F)))
    // duplicate
    return;

  switch(pktctrl) {
    case SLURM_PKT_NOTIFY:
      on_slurm_notify(b, len);
      break;

    // ignore others
  }
}
#endif

void isr_slurm_recv(uint8_t b)
{
  switch(rx.state) {
    case STATE_IDLE:
      if(b == 0x55) {
        rx.state = STATE_RECV_HEADER;
        rx.len = 0;
        rx.crc = 0;
      }
      break;

    case STATE_RECV_HEADER:
      rx.buf[rx.len] = b;
      rx.len++;
      if(rx.len == HEADERLEN) {
        if(rx.crc != b)
          goto abort;

        rx.state = STATE_RECV_PAYLOAD;
      }
      _crc8_update(&rx.crc, b);
      break;

    case STATE_RECV_PAYLOAD:
      rx.buf[rx.len] = b;
      rx.len++;
      if(rx.len < rx.buf[IDX_LEN] + HEADERLEN + 1) {
        _crc8_update(&rx.crc, b);
        break;
      }

      if(rx.crc != b)
        goto abort;

#ifdef SLURM_MULTIDROP
      if((rx.buf[1] & 0x80) && ((rx.buf[1] & 0x7F) == node_id))
#endif
        on_recv(rx.buf[0], rx.buf + HEADERLEN, rx.buf[IDX_LEN]);
#ifdef SLURM_MULTIDROP_BCAST
      else if((rx.buf[1] & 0x80) && ((rx.buf[1] & 0x7F) == SLURM_MULTIDROP_BCAST))
        on_recv_bcast(rx.buf[0], rx.buf + HEADERLEN, rx.buf[IDX_LEN]);
#endif

      rx.state = STATE_IDLE;
      break;
  }

  return;

abort:
  // TODO: Scan the buffer to see if we have a valid 0x55 in there somewhere,
  // and if so we can resume from that point perhaps
  rx.state = STATE_IDLE;
}

// empty default implementations
__attribute__((weak)) void on_slurm_notify(uint8_t b[], uint8_t len) {}
__attribute__((weak)) void on_slurm_request(uint8_t seqno, uint8_t b[], uint8_t len) {}

/* Background task runner */

void slurm_do_tasks(void)
{
  if(tx.need_send_resetack) {
    transmit(SLURM_PKT_META_RESETACK, (uint8_t[]){tx.seqno}, 1);
    tx.need_send_resetack = 0;
  }

  if(tx.need_retx_cmdslot) {
    // TODO: ATOMICs
    uint8_t need_retx = tx.need_retx_cmdslot; tx.need_retx_cmdslot = 0;

    for(uint8_t cmdi = 0; cmdi < sizeof(cmdslots)/sizeof(cmdslots[0]); cmdi++) {
      if(!(need_retx & (1 << cmdi)))
        continue;

      uint8_t pktctrl = cmdslots[cmdi].seqno;
      switch(cmdslots[cmdi].state) {
        case CMDSTATE_FREE:
        case CMDSTATE_EXECUTING:
          break;

        case CMDSTATE_RESPONDED: pktctrl |= SLURM_PKT_RESPONSE; break;
        case CMDSTATE_ERRORED:   pktctrl |= SLURM_PKT_ERR;      break;
      }
      transmit(pktctrl, cmdslots[cmdi].resp, cmdslots[cmdi].resplen);
    }
  }
}

void slurm_reset(void)
{
  tx.seqno = 0;

  transmit(SLURM_PKT_META_RESET, (uint8_t[]){tx.seqno}, 1);
  transmit(SLURM_PKT_META_RESET, (uint8_t[]){tx.seqno}, 1);
}
