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

// routines for starting an image server in a separate process
// useful for programs with an interface or multiple clients

#ifndef CQCSRV_H
#define CQCSRV_H

#define CQCSRV_GET_FRAME 1
#define CQCSRV_SET_TOP 2
#define CQCSRV_SET_LEFT 3
#define CQCSRV_SET_WIDTH 4
#define CQCSRV_SET_HEIGHT 5
#define CQCSRV_SET_BLACK 6
#define CQCSRV_SET_WHITE 7
#define CQCSRV_SET_HUE 8
#define CQCSRV_SET_SATURATION 9
#define CQCSRV_SET_CONTRAST 10
#define CQCSRV_SET_BRIGHTNESS 11
#define CQCSRV_SET_BPP 12
#define CQCSRV_SET_DECIMATION 13

int send_command(int fd, unsigned char command, int parameter);
int send_get_frame(int fd);
int init_server(int *infd, int *outfd);

#endif
