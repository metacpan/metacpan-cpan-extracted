/* libcqcam - shared Color Quickcam routines
 * Copyright (C) 1996-1998 by Patrick Reynolds
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "config.h"

#ifdef QNX
#include <stdlib.h>
#include <time.h>
#define usleep(us) { timespec ts={ (us)/1000000L, (us)%1000000L*1000 }; \
                     nanosleep(&ts, NULL); }
#endif // QNX

#include "port.h"
#include "camera.h"

camera_t::camera_t(int iport, int idetect) {
  if (probe(iport, idetect)) {
    fprintf(stderr, "No camera found.\n");
    exit(1);                    // not much point in recovering here
  }
  bw = 0;
  detect_port_mode();
  reset();
  set_speed(2);
  set_hue(110);
  set_saturation(100);
  set_contrast(104);
  set_black_level(130);
  set_brightness(150);
  set_top(1);
  set_left(11);
  set_bpp(bw ? DEFAULT_BW_BPP : DEFAULT_BPP);
  set_cam_height(240);
  set_cam_width(160);
  set_white_level(130);
  set_decimation(2);
  set_red(128);
  set_green(128);
  set_blue(128);
}

camera_t::~camera_t() {
  delete port;
}

void camera_t::reset(void) {
  // set the initial port state Reset_N = 1, PCAck = 1
  port->write_control(0x0c);

  // now perform the reset
  port->write_control(0x08);  // drop the Reset_N bit
  usleep(10000);              // delay 10 ms
  port->write_control(0x0c);  // raise the Reset_N bit
  usleep(10000);              // delay 10 ms to let the reset take place
}

int camera_t::set_brightness(int ibrightness) {
  brightness = ibrightness;
  //fprintf(stderr, "brightness <- %d\n", ibrightness);
  return set(QC_BRIGHTNESS, ibrightness);
}
int camera_t::set_top(int itop) {
  if (itop < 1 || itop > 240) {
#ifdef DEBUG
    fprintf(stderr, "Invalid top row: %d\n", itop);
#endif
    return -1;
  }
  top = itop;
  return set(QC_TOP, itop);
}
int camera_t::set_left(int ileft) {
  if (ileft < 0 || ileft > 160) {
#ifdef DEBUG
    fprintf(stderr, "Invalid left column: %d\n", ileft);
#endif
    return -1;
  }
  left = ileft;
  return set(QC_LEFT, ileft);
}

int camera_t::set_height(int iheight) {
  int cam_height = iheight * decimation / ((bpp==32)?2:1);
  if (cam_height < 4) {
    cam_height = 4;
#ifdef DEBUG
    fprintf(stderr, "Invalid height: %d (using %d instead)\n",
      iheight, cam_height * ((bpp==32)?2:1) / decimation);
#endif
  }
  else if (cam_height > 240) {
    cam_height = 240;
#ifdef DEBUG
    fprintf(stderr, "Invalid height: %d (using %d instead)\n",
      iheight, cam_height * ((bpp==32)?2:1) / decimation);
#endif
  }
  return set_cam_height(cam_height);
}

int camera_t::set_width(int iwidth) {
  int cam_width = iwidth * decimation / ((bpp==32)?4:2);
  if (cam_width < 4) {
    cam_width = 4;
#ifdef DEBUG
    fprintf(stderr, "Invalid width: %d (using %d instead)\n",
      iwidth, cam_width * ((bpp==32)?4:2) / decimation);
#endif
  }
  else if (cam_width > 160) {
    cam_width = 160;
#ifdef DEBUG
    fprintf(stderr, "Invalid width: %d (using %d instead)\n",
      iwidth, cam_width * ((bpp==32)?4:2) / decimation);
#endif
  }
  if (cam_width % 2) {
    cam_width++;
#ifdef DEBUG
    fprintf(stderr, "Invalid width: %d (using %d instead)\n",
      iwidth, cam_width * ((bpp==32)?4:2) / decimation);
#endif
  }
  return set_cam_width(cam_width);
}

int camera_t::set_cam_width(int iwidth) {
  width = iwidth;
  return set(QC_WIDTH, width);
}

int camera_t::set_cam_height(int iheight) {
  height = iheight;
  return set(QC_HEIGHT, height);
}

int camera_t::get_version(void) {
  int temp = get(QC_VERSION);
  read_param();  // ignore the port-connector version byte
  return temp;
}
int camera_t::set_black_level(int iblack_level) {
  if (bw) return -1;
  black_level = iblack_level;
  int temp = set(QC_BLACK, iblack_level);
  while (get_status() & QC_STAT_BLACK_BAL == QC_STAT_BLACK_BAL) ;
  return temp;
}
int camera_t::set_white_level(int iwhite_level) {
  white_level = iwhite_level;
  return set(QC_WHITE, iwhite_level);
}
int camera_t::set_hue(int ihue) {
  if (bw) return -1;
  hue = ihue;
  return set(QC_HUE, ihue);
}
int camera_t::set_saturation(int isaturation) {
  if (bw) return -1;
  saturation = isaturation;
  return set(QC_SATURATION, isaturation);
}
int camera_t::set_contrast(int icontrast) {
  contrast = icontrast;
  return set(bw ? BWQC_CONTRAST : QC_CONTRAST, icontrast);
}
int camera_t::get_status(void) {
  if (bw) return 0;
  return get(QC_STATUS);
}
int camera_t::set_speed(int ispeed) {
  if (bw) return -1;
  return set(QC_SPEED, ispeed);
}

int camera_t::set_bpp(int ibpp) {
  if (bw) {
    if (ibpp != 4 && ibpp != 6) return -1;
    bpp = ibpp;
    return 0;
  }
  else {
    if (ibpp != 24 && ibpp != 32) return -1;
    if (bpp == 24 && ibpp == 32) {
      set_cam_width(width/2);
      set_cam_height(height/2);
    }
    else if (bpp == 32 && ibpp == 24) {
      int twidth = width * 2;
      int theight = height * 2;
      if (twidth > 160)
        twidth = 160;
      if (theight > 240)
        theight = 240;
      set_cam_width(twidth);
      set_cam_height(theight);
    }
    bpp = ibpp;
    return 0;
  }
}
void camera_t::set_decimation(int idecimation) { decimation = idecimation; }
void camera_t::set_port_mode(int iport_mode) { port_mode = iport_mode; }
void camera_t::set_red(int ired) { red = ired; }
void camera_t::set_green(int igreen) { green = igreen; }
void camera_t::set_blue(int iblue) { blue = iblue; }

int camera_t::detect_port_mode(void) {
  int ok = 0;

  // try to set the bi_dir bit
  port->setbit_control(0x20);

  // wait to let the change sink in, if it can
  usleep(30000);
  port->write_data(0x55);
  if (port->read_data() != 0x55) ++ok;
  port->write_data(0xaa);
  if (port->read_data() != 0xaa) ++ok;

  if (ok) {  // it's bi-dir
#ifdef DEBUG
  fprintf(stderr, "bi-dir port detected\n");
#endif
    set_port_mode(QC_BI_DIR);
    // go back to uni_dir before returning
    port->clearbit_control(0xf0);
    usleep(30000);
    return QC_BI_DIR;
  }
  else {       // bit write failed, so it's not bi_dir
#ifdef DEBUG
  fprintf(stderr, "uni-dir port detected\n");
#endif
    set_port_mode(QC_UNI_DIR);
    return QC_UNI_DIR;
  }
}
    

int camera_t::get_height(void) const {
  return (bpp == 32) ? height*2 : height;
}
int camera_t::get_pix_height(void) const {
  return height / decimation * ((bpp == 32) ? 2 : 1);
}
int camera_t::get_width(void) const {
  return (bpp == 32) ? width*2 : width;
}
int camera_t::get_pix_width(void) const {
  return width * 2 / decimation * ((bpp == 32) ? 2 : 1);
}
int camera_t::get_red(void) const { return red; }
int camera_t::get_green(void) const { return green; }
int camera_t::get_blue(void) const { return blue; }
int camera_t::get_bpp(void) const { return bpp; }
int camera_t::get_decimation(void) const { return decimation; }
int camera_t::get_port_mode(void) const { return port_mode; }
int camera_t::get_brightness(void) const { return brightness; }
int camera_t::get_black_level(void) const { return black_level; }
int camera_t::get_white_level(void) const { return white_level; }
int camera_t::get_top(void) const { return top; }
int camera_t::get_left(void) const { return left; }
int camera_t::get_saturation(void) const { return saturation; }
int camera_t::get_hue(void) const { return hue; }
int camera_t::get_contrast(void) const { return contrast; }

inline void camera_t::set_ack(int i) const {
  // note: a software raise in the PCAck bit is a lowering in the pin
  // voltage.  The QC specs refer to the PCAck pin by voltage, not
  // software level.
  if (i)
    port->setbit_control(0x08);     // soft raise
  else
    port->clearbit_control(0x08);   // soft lower
}

inline int camera_t::get_rdy1(void) const {
  return ((port->read_status() & 0x08) == 0x08);  // is CamRdy1 set?
}

inline int camera_t::get_rdy2(void) const {
  return ((port->read_data() & 0x01) == 0x01);    // is CamRdy2 set?
}

int camera_t::probe(int iport, int idetect) {
  int ioports[] = {0x378, 0x278, 0x3bc, 0};
  int i = 0;

  if (iport != 0) {             // user specified a port to try
    port = new port_t(iport);   // attempt the suggested port
    if (*port)
      if (detect(idetect)) {      // look for a camera
#ifdef DEBUG
        fprintf(stderr, "camera found on port 0x%x\n", ioports[i]);
#endif
        return 0;                 // camera found, exit
      }
#ifdef DEBUG
    fprintf(stderr, "camera not found on port 0x%x\n", iport);
#endif
    delete port;                  // camera not found.  Dispose of
    return 1;                     // port and return a failure
  }

  // user didn't suggest a port; let's scan for one
  while (ioports[i] != 0) {
    port = new port_t(ioports[i]);  // set the current port to attempt
    if (*port)
      if (detect(idetect)) {          // look for a camera
#ifdef DEBUG
        fprintf(stderr, "camera found on port 0x%x\n", ioports[i]);
#endif
        return 0;                     // camera found, exit
      }
#ifdef DEBUG
      fprintf(stderr, "camera not found on port 0x%x\n", ioports[i]);
#endif
      delete port;                  // camera not found.  Dispose of
      i++;                          // the current port and try another
  }
  return 1;                         // no camera
}

int camera_t::detect(int idetect) {
  switch (idetect) {
    case 0:
#ifdef DEBUG
      fprintf(stderr,
        "Skipping detection routines; assuming Color Quickcam.\n");
#endif
      return 1;                                  // unconditional success
    case 1:  return (p_detect() || k_detect());  // either/or
    case 2:  return (p_detect());                // Patrick's only (default)
    case 3:  return (k_detect());                // Kenny's only
    case 4:  return (p_detect() && k_detect());  // both
    default: fprintf(stderr, "Bad detection mode: %d\n", idetect);
             exit(1);
  }
  return 0;  // unreachable, but can prevent compiler warnings, maybe
}

int camera_t::p_detect(void) {
  int stat, ostat, count = 0, i;

  // set the initial port state Reset_N = 1, PCAck = 1
  port->write_control(0x0c);

  // look for a "heartbeat"
  // this isn't pretty.  There should be a usleep(1000) in there to make
  // this happen for a quarter second at a consistent speed on any 
  // computer...  But usleep() has too much overhead, so this loop took 5.0
  // seconds instead of 0.25.  We're going without a delay loop for now, so
  // this may break (cause false negatives) on > i586 machines

  ostat = stat = port->read_status();
  for (i=1;i<=250;i++) {
    stat = port->read_status();
    if (ostat != stat) {
      if (++count >= 3) return 1;
      ostat = stat;
    }
  }

  // count didn't reach 3.  There's no camera out there, it seems...
  // But, let's issue a reset and try again before we give up.  The
  // color qc won't display a "heartbeat" until it's been reset.
  reset();

  // look for a "heartbeat" again
  count = 0;
  ostat = stat = port->read_status();
  for (i=1;i<=250;i++) {
    stat = port->read_status();
    if (ostat != stat) {
      if (++count >= 3) return 1;
      ostat = stat;
    }
  }

  // still nothing.  admit defeat
  return 0;
}

int camera_t::k_detect(void) {
  reset();
  int in_data, counter;

  port->write_data(QC_VERSION);
  set_ack(0);
  counter = 0;
  while (++counter < 1000 && !get_rdy1()) ;        // wait 1000 cycles
  if (counter == 1000)
    return 0;                                      // timed out, no camera
  in_data = (port->read_status() & 0xf0);          // read high nybble
  set_ack(1);
  counter = 0;
  while (++counter < 1000 && get_rdy1()) ;         // wait 1000 cycles
  if (counter == 1000)
    return 0;                                      // timed out, no camera
  in_data |= ((port->read_status() & 0xf0) >> 4);  // read low nybble
  if (in_data != QC_VERSION)
    return 0;                           // failed ack (unlikely), no camera
  // we seem to have a camera...
  read_param();  // get (but ignore) camera version
  read_param();  // get (but ignore) connector version
  return 1;      // camera found
}

int camera_t::load_ram_table(unsigned char *table) const {
  if (write_data(QC_LOAD_RAM) == -1) return -1;
  for (int i=0; i<4095; i++) {
    if (!(i%32)) {
      fprintf(stderr, ".");  fflush(stderr);
    }
    if (write_data(table[i]) == -1) return -1;
  }
  port->setbit_control(0x02);                        // soft lower
  if (write_data(table[4095]) == -1) {
    port->clearbit_control(0x02);                    // soft raise
    return -1;
  }
  port->clearbit_control(0x02);                      // soft raise
  return 0;
}

int camera_t::write_data(int data) const {
  int in_data;
  port->write_data(data);                          // send data on cmd[0..7]
  set_ack(0);
  while (!get_rdy1()) ;
  in_data = (port->read_status() & 0xf0);          // read high nybble
  set_ack(1);
  while (get_rdy1()) ;
  in_data |= ((port->read_status() & 0xf0) >> 4);  // read low nybble
  if (data != in_data) {
#ifdef DEBUG
    fprintf(stderr, "camera write error: written=%d read=%d\n", data, in_data);
#endif
    return 1;
  }
  else
    return 0;
}

int camera_t::read_param(void) const {
  int in_data;
  set_ack(0);
  while (!get_rdy1()) ;
  in_data = port->read_status() & 0xf0;            // read high nybble
  set_ack(1);
  while (get_rdy1()) ;
  in_data |= ((port->read_status() & 0xf0) >> 4);  // read low nybble
  return in_data;
}

int camera_t::set(int command, int parameter) const {
  if (write_data(command))
    return -1;
  if (write_data(parameter))
    return -1;
  return 0;
}

int camera_t::get(int command) const {
  if (write_data(command))
    return -1;
  return read_param();
}

// if the camera is in 24bpp (millions) mode, returns a buffer of 24-bit 
// data in the form R G B R G B R G B
// if the camera is in 32bpp (billions) mode, returns a buffer of 32-bit
// data in the form BG1G2R BG1G2R.  I've provided a 32->24 enlargement
// algorithm in imager.C; use or replace it as you see fit.

unsigned char *camera_t::get_frame(void) {
  int lines, pixelsperline, bitsperxfer, tdecimation, tbpp;
  int bytes;                     // number of bytes read this read
  unsigned char *retbuf, buf[6] = {0, 0, 0, 0, 0, 0};

  while (get_status() & QC_STAT_BUSY == QC_STAT_BUSY) ;

  switch (bpp) {
    case 24: tbpp = QC_24BPP; break;
    case 32: tbpp = QC_32BPP; break;
//    case 16: // VIDEC compression... can't ever support this
    case 16: tbpp = QC_16BPP; break;
    case 6:  tbpp = BWQC_6BPP; break;
    case 4:  tbpp = BWQC_4BPP; break;
    default: fprintf(stderr, "get_frame(): unsupported bpp %d\n", bpp);
             exit(1);
  }
  switch (decimation) {
    case 1: tdecimation = bw ? BWQC_1_1 : QC_1_1; break;
    case 2: tdecimation = bw ? BWQC_2_1 : QC_2_1; break;
    case 4: tdecimation = bw ? BWQC_4_1 : QC_4_1; break;
    default: fprintf(stderr, "get_frame(): unsupported decimation %d\n",
               decimation);
             exit(1);
  }
  if (set(QC_SEND_FRAME, (port_mode | tdecimation | tbpp) + (bw ? 0 : 1))) {
  // parameter must be + one, because the QC specs said so
    fprintf(stderr, "get_frame(): bad SEND_FRAME echo\n");
    exit(1);
  }

  lines = height / decimation;
  pixelsperline = width * 2 / decimation;
  bitsperxfer = (port_mode == QC_BI_DIR) ? 24 : 8;

#ifdef DEBUG
  fprintf(stderr, "Scanning (%dx%d): %s-directional port, %d bpp, ",
    get_pix_width(), get_pix_height(),
    ((port_mode == QC_BI_DIR) ? "bi" : "uni"), bpp);
  fprintf(stderr, "decimation=%d, bright=%d\n", decimation, brightness);
#endif

  if (port_mode == QC_BI_DIR) {
    // turn the port around
    port->setbit_control(0x20);
    usleep(3000);                   // make sure the port is really flipped
    set_ack(0);
    while (!get_rdy1()) ;
    set_ack(1);
    while (get_rdy1()) ;
  }
  retbuf = new unsigned char[lines * pixelsperline * bpp / 8];
  if (!retbuf) {
    fprintf(stderr, "malloc(): Out of memory allocating %d bytes\n",
      lines * pixelsperline * bpp / 8);
    exit(1);
  }
  // do the actual reads
  bytes = read_bytes(retbuf, lines * pixelsperline * bpp / bitsperxfer);
  if (bytes <= 0) {
    fprintf(stderr, "read_bytes(): read error: %d\n", bytes);
    exit(1);
  }
  // Now do the EOF handshake
  do {
    // read out the 0x7E padding bytes
    bytes = read_bytes(buf, 1);
  } while (buf[bytes-1] == 0x7e); 

  if (port_mode == QC_BI_DIR) {
    if ((buf[0] != 0xe) || (buf[1] != 0x0) || (buf[2] != 0xf)) {
      port->clearbit_control(0xf0);
      usleep(1000);
#ifdef DEBUG
      fprintf(stderr, "Failed EOF handshake.  Using 'reset.'\n");
#endif
      reset();
      return retbuf;
    } 
    // turn the port back around
    set_ack(0);
    while (!get_rdy1());
    port->clearbit_control(0x20);
    usleep(1000);
    set_ack(1);
    while (get_rdy1());
  }
  else {
    read_bytes(buf+1, 2);
    if ((buf[0] != 0xe) || (buf[1] != 0x0) || (buf[2] != 0xf)) {
#ifdef DEBUG
      fprintf(stderr, "Failed EOF handshake.  Using 'reset.'\n");
#endif
      reset();
      return retbuf;
    }
  }

  if (write_data(0)) {
#ifdef DEBUG
    fprintf(stderr, "Failed EOF handshake.  Using 'reset.'\n");
#endif
    reset();
  }

  return retbuf;
}

int camera_t::read_bytes(unsigned char *buf, int ntrans) {
  int nbytes = 0;
  unsigned int hi, lo, hi2, lo2;

  if (port_mode == QC_BI_DIR) {
    set_ack(0);
    for ( ; ntrans>0; ntrans--) {
      int data;
      do { data = port->read_data(); } while (!(data & 0x01));
      lo = (data & 0xff) >> 1;
      hi = ((port->read_status() >> 3) & 0x1f) ^ 0x10;
      set_ack(1);
      buf[nbytes+0] = lo | ((hi & 0x01) << 7);
      do { data = port->read_data(); } while (data & 0x01);
      lo2 = (data & 0xff) >> 1;
      hi2 = ((port->read_status() >> 3) & 0x1f) ^ 0x10;
      set_ack(0);
      buf[nbytes+1] = ((hi & 0x1e) << 3) | ((hi2 & 0x1e) >> 1);
      buf[nbytes+2] = lo2 | ((hi2 & 0x01) << 7);
      nbytes += 3;
    } 
  }
  else {                                     // port_mode == QC_UNI_DIR
    set_ack(0);
    for ( ; ntrans>0; ntrans--) {
      int s;
      do { s = port->read_status(); } while (!(s & 0x08));
      hi = s & 0xf0;         // read high nybble
      set_ack(1);
      do { s = port->read_status(); } while (s & 0x08);
      lo = (s & 0xf0) >> 4;  // read low nybble
      set_ack(0);
      hi ^= 0x80;           // kludge to flip Nybble3 pin, which color QC sets
      lo ^= 8;              // incorrectly
      buf[nbytes+0] = lo | hi;
      nbytes += 1;
    }
  }
  return nbytes;
}
