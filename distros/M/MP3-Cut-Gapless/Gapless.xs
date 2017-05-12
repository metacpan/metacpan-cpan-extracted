#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "common.c"
#include "mp3cut.c"

MODULE = MP3::Cut::Gapless		PACKAGE = MP3::Cut::Gapless

void
__init(HV *self)
PPCODE:
{
  SV *pv = NEWSV(0, sizeof(mp3cut));
  mp3cut *mp3c = (mp3cut *)SvPVX(pv);
  
  SvPOK_only(pv);
  
  Newz(0, mp3c->buf, sizeof(Buffer), Buffer);
  Newz(0, mp3c->mllt_buf, sizeof(Buffer), Buffer);
  Newz(0, mp3c->first_frame, sizeof(mp3frame), mp3frame);
  Newz(0, mp3c->curr_frame, sizeof(mp3frame), mp3frame);
  Newz(0, mp3c->xilt_frame, sizeof(xiltframe), xiltframe);
  Newz(0, mp3c->xilt_frame->tag, sizeof(Buffer), Buffer);
  
  buffer_init(mp3c->buf, MP3_BLOCK_SIZE);
  buffer_init(mp3c->mllt_buf, MP3_BLOCK_SIZE);
  
  _mp3cut_init(self, mp3c);
  
  XPUSHs( sv_2mortal( sv_bless(
    newRV_noinc(pv),
    gv_stashpv("MP3::Cut::Gapless::XS", 1)
  ) ) );
}

int
read(HV *self, SV *buf, SV *buf_size)
CODE:
{
  mp3cut *mp3c = (mp3cut *)SvPVX(SvRV(*(my_hv_fetch(self, "_mp3c"))));
  
  RETVAL = _mp3cut_read(self, mp3c, buf, SvIV(buf_size));
}
OUTPUT:
  RETVAL

void
__reset_read(HV *self)
CODE:
{
  mp3cut *mp3c = (mp3cut *)SvPVX(SvRV(*(my_hv_fetch(self, "_mp3c"))));
  
  mp3c->next_processed_frame = 0;
}

void
__cleanup(HV *self, mp3cut *mp3c)
CODE:
{
  Safefree(mp3c->first_frame);
  Safefree(mp3c->curr_frame);
  buffer_free(mp3c->xilt_frame->tag);
  Safefree(mp3c->xilt_frame->tag);
  Safefree(mp3c->xilt_frame);
  buffer_free(mp3c->buf);
  Safefree(mp3c->buf);
  buffer_free(mp3c->mllt_buf);
  Safefree(mp3c->mllt_buf);
}
