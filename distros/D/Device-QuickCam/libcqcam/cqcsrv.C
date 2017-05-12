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

#include <fcntl.h>
#include <errno.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/time.h>

#include "cqcsrv.h"
#include "camera.h"

static int quit = 0;

static void go_away(int s) {
  quit = 1;
  fprintf(stderr, "Signal %d\n", s);
  if (s == SIGPIPE) signal(s, go_away);
}

static int get_param(int fd, int *p) {
  int n;
  switch (n = read(fd, p, sizeof(*p))) {
    case -1:
      perror("read");
      return -1;
    case 0:
      fprintf(stderr, "read: EOF\n");
      return -1;
    case sizeof(*p):
      return 0;
    default:
      fprintf(stderr, "read: %d characters\n", n);
      return -1;
  }
}

static int serve(int infd, int outfd, int port=0, int detect=1) {
  unsigned char command;
  int parameter;
  unsigned char *scan;
  camera_t cam(port, detect);
  int n = 0;
  
  struct timeval start, end;

#ifndef LYNX
  setgid(getgid());
  setuid(getuid());
#endif

  while (!quit) {
    while (!quit && (n = read(infd, &command, 1) > 0)) {
      alarm(10);
      switch (command) {
        case CQCSRV_GET_FRAME:
          gettimeofday(&start, 0);
          scan = cam.get_frame();
          gettimeofday(&end, 0);
          end.tv_sec--;  end.tv_usec += 1000000;
#ifdef DEBUG
          fprintf(stderr, "Frame time: %ld.%06ld\n",
            end.tv_sec - start.tv_sec + (end.tv_usec - start.tv_usec)/1000000,
            (end.tv_usec - start.tv_usec) % 1000000);
#endif
          parameter = cam.get_bpp();
          write(outfd, &parameter, sizeof(parameter));
          parameter = cam.get_pix_width();
          write(outfd, &parameter, sizeof(parameter));
          parameter = cam.get_pix_height();
          write(outfd, &parameter, sizeof(parameter));
          write(outfd, scan,
            cam.get_pix_width()*cam.get_pix_height()*((cam.get_bpp()==32)?1:3));
          delete[] scan;
          break;
        case CQCSRV_SET_TOP:
          if (get_param(infd, &parameter) < 0) return -1;
          cam.set_top(parameter);
          break;
        case CQCSRV_SET_LEFT:
          if (get_param(infd, &parameter) < 0) return -1;
          cam.set_left(parameter);
          break;
        case CQCSRV_SET_WIDTH:
          if (get_param(infd, &parameter) < 0) return -1;
          cam.set_width(parameter);
          break;
        case CQCSRV_SET_HEIGHT:
          if (get_param(infd, &parameter) < 0) return -1;
          cam.set_height(parameter);
          break;
        case CQCSRV_SET_BLACK:
          if (get_param(infd, &parameter) < 0) return -1;
          cam.set_black_level(parameter);
          break;
        case CQCSRV_SET_WHITE:
          if (get_param(infd, &parameter) < 0) return -1;
          cam.set_white_level(parameter);
          break;
        case CQCSRV_SET_HUE:
          if (get_param(infd, &parameter) < 0) return -1;
          cam.set_hue(parameter);
          break;
        case CQCSRV_SET_SATURATION:
          if (get_param(infd, &parameter) < 0) return -1;
          cam.set_saturation(parameter);
          break;
        case CQCSRV_SET_CONTRAST:
          if (get_param(infd, &parameter) < 0) return -1;
          cam.set_contrast(parameter);
          break;
        case CQCSRV_SET_BRIGHTNESS:
          if (get_param(infd, &parameter) < 0) return -1;
          cam.set_brightness(parameter);
          break;
        case CQCSRV_SET_BPP:
          if (get_param(infd, &parameter) < 0) return -1;
          cam.set_bpp(parameter);
          break;
        case CQCSRV_SET_DECIMATION:
          if (get_param(infd, &parameter) < 0) return -1;
          cam.set_decimation(parameter);
          break;
      }
      alarm(0);
    }
    if (n < 0) {
      perror("read");
      return -1;
    }
  }
#ifdef DEBUG
  fprintf(stderr, "Camera server: clean shutdown\n");
#endif
  return 0;
}

int init_server(int *infd, int *outfd) {
  int cmd[2], img[2];
  if (pipe(cmd) < 0) { perror("pipe"); return -1; }
  if (pipe(img) < 0) { perror("pipe"); return -1; }
  int n = fork();
  if (n < 0) { perror("fork"); return -1; }
  if (n) {
    if (close(cmd[0]) < 0) { perror("close"); return -1; }
    if (close(img[1]) < 0) { perror("close"); return -1; }
    *infd = img[0];
    *outfd = cmd[1];
    return n;
  }
  else {
    if (close(cmd[1]) < 0) { perror("close"); return -1; }
    if (close(img[0]) < 0) { perror("close"); return -1; }
    signal(SIGPIPE, SIG_IGN);

    exit(serve(cmd[0], img[1]));
  }
}

int send_command(int fd, unsigned char command, int parameter) {
  if (write(fd, &command, 1) < 0) { perror("write"); return -1; }
  if (write(fd, &parameter, sizeof(parameter)) < 0) { perror("write"); return -1; }
  return 0;
}

int send_get_frame(int fd) {
  unsigned char foo = CQCSRV_GET_FRAME;
  if (write(fd, &foo, 1) < 0) { perror("write"); return -1; }
  return 0;
}
