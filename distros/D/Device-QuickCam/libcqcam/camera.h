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

// definitions for the camera_t class and global #define constants
// (see the official CQC specs for what these constants all mean)

#ifndef CAMERA_H
#define CAMERA_H

#include "port.h"
#include "config.h"

#include <stdio.h>

class camera_t {
public:
  camera_t(int iport = DEFAULT_PORT, int idetect = DEFAULT_DETECT_MODE);
  ~camera_t();

  unsigned char *get_frame(void);

// width/height functions for the something closer to what the user actually
// will see: e.g., set_width(100) when decimation=1 and bpp=32 will actually
// set_cam_width(25).  If you don't know why, don't mess with it.  :)
  int set_width(int iwidth);
  int set_height(int iheight);

// all interface commands return -1 on failure and >= 0 on success
  int set_brightness(int ibrightness);    // 11
  int set_top(int itop);                  // 13
  int set_left(int ileft);                // 15
  int get_version(void);                  // 23
  int set_black_level(int iblack_level);  // 29
  int set_white_level(int iwhite_level);  // 31
  int set_hue(int ihue);                  // 33
  int set_saturation(int isaturation);    // 35
  int set_contrast(int icontrast);        // 37
  int get_status(void);                   // 41
  int set_speed(int ispeed);              // 45

// pseudo-interface commands - set parameters without sending values
// to the camera.  These don't need any return values.
  int set_bpp(int ibpp);
  void set_decimation(int idecimation);
  void set_port_mode(int iport_mode);
  void set_red(int ired);
  void set_green(int igreen);
  void set_blue(int iblue);

  // inspectors
  int get_pix_height(void) const;
  int get_pix_width(void) const;
  int get_red(void) const;
  int get_green(void) const;
  int get_blue(void) const;
  int get_bpp(void) const;
  int get_decimation(void) const;
  int get_brightness(void) const;
  int get_white_level(void) const;
  int get_black_level(void) const;
  int get_top(void) const;
  int get_left(void) const;
  int get_saturation(void) const;
  int get_hue(void) const;
  int get_contrast(void) const;
  int get_port_mode(void) const;

  void reset(void);      // reset the camera
  int load_ram_table(unsigned char *table) const;  // doesn't work yet!!

private:
  int detect_port_mode(void);

  // these four functions all use hardware width and height values.  Please
  // use set_height/set_width and get_pix_height/get_pix_width to get/set
  // the image size in pixels.
  int set_cam_height(int iheight);        // 17
  int set_cam_width(int iwidth);          // 19
  int get_height(void) const;
  int get_width(void) const;

  int probe(int iport, int idetect);  // probe the three standard I/O ports

// in detection routines, 1 = camera present; 0 = no camera
  int detect(int idetect);   // front-end for the two detection modes
  int p_detect(void);    // Patrick's check: look for a QC "heartbeat."  If
                         // one isn't found, reset() and try again.
  int k_detect(void);    // Kenny Root's check: reset() and check the version

  void set_ack(int i) const;  // set/clear PCAck.
                              // i=0 sets it soft low (volt high)
                              // i=1 sets is soft high (volt low)
  int get_rdy1(void) const;   // returns the status of CamRdy1
  int get_rdy2(void) const;   // returns the status of CamRdy2 (for bi_dir)

  int write_data(int data) const;  // atomic write and echo-read
  int read_param(void) const;      // atomic read
  int set(int command, int parameter) const;  // send a command with a parameter
  int get(int command) const;                 // send a command to get a value
  int read_bytes(unsigned char *buf, int ntrans);   // read a number of chunks
                                                    // of 1 or 3 bytes each
  port_t *port;                         // port structure handling raw I/O

// camera values that need to be kept on hand or aren't stored inside the
// camera
  int height, width, top, left;  // these are physical-level things, which
                                 // only vaguely resemble the size of the
                                 // frame returned.
  int bpp, decimation, port_mode, brightness, red, green, blue;
  int white_level, black_level, saturation, hue, contrast, bw;
};

// For explanations of all the constants below, see the QuickCam specs from
// Connectix

#define QC_SEND_FRAME 7
#define QC_BRIGHTNESS 11
#define QC_TOP 13
#define QC_LEFT 15
#define QC_HEIGHT 17
#define QC_WIDTH 19
#define QC_VERSION 23
#define QC_LOAD_RAM 27
#define QC_BLACK 29
#define QC_WHITE 31
#define QC_HUE 33
#define QC_SATURATION 35
#define QC_CONTRAST 37
#define BWQC_CONTRAST 25
#define QC_STATUS 41
#define QC_SPEED 45

#define QC_UNI_DIR 0
#define QC_BI_DIR 1
#define QC_1_1 0
#define QC_2_1 2
#define QC_4_1 4
#define BWQC_1_1 0
#define BWQC_2_1 4
#define BWQC_4_1 8
#define QC_16BPP 8
#define QC_32BPP 16
#define QC_24BPP 24
#define BWQC_6BPP 2
#define BWQC_4BPP 0
#define QC_TEST_PATTERN 64
#define BWQC_TEST_PATTERN 32

#define QC_STAT_RAM_DL 2
#define QC_STAT_BLACK_BAL 64
#define QC_STAT_BUSY 128

#define CQC_VERSION "version 0.91\nby Patrick Reynolds <reynolds@cs.duke.edu>\n"

#endif
