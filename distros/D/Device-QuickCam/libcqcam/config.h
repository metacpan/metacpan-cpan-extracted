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

// compile-time configuration
// nearly everything here can be overridden at run-time

#ifndef CONFIG_H
#define CONFIG_H

// DEFAULT_DETECT_MODE (-d)
// which detection mode to use by default (see camera.h for details)
//   0 = no detection
//   1 = okay if either succeeds    (default)
//   2 = try Patrick's scheme only
//   3 = try Kenny's scheme only
//   4 = okay only if both schemes succeed
// 2 and 3 are faster than 1, but are less likely to succeed.  Is 4 even 
// worth having?  :)
#define DEFAULT_DETECT_MODE 1

// DEFAULT_PORT (-P)
// which port to find the camera on (0 = probe 0x378, 0x278, and 0x3bc)
#define DEFAULT_PORT 0

// PRIVATE_CMAP_DEFAULT (-p, xcqcam only)
// use a private colormap by default in 8-bpp mode?  1=yes, 0=no
#define PRIVATE_CMAP_DEFAULT 0

// AUTO_ADJ_DEFAULT (-a)
// automatically adjust brightness and color balance on startup?  1=yes, 0=no
#define AUTO_ADJ_DEFAULT 1

// DEFAULT_SHM (-m, xcqcam only)
// use the MIT shared-memory (SHM) extension?
// 1=yes, 0=no
#define DEFAULT_SHM 1

// DEFAULT_BPP (-32)
// use 24 or 32 bits per pixel?
#define DEFAULT_BPP 24

// DEFAULT_BW_BPP
// use 4 or 6 bits per pixel?
#define DEFAULT_BW_BPP 6

// DEFAULT_DECIMATION (-s)
// use 1:1, 2:1, or 4:1 decimation bits per pixel?
#define DEFAULT_DECIMATION 1

// DESPECKLE
// define it if you want auto-despeckling.  Despeckling can cause a very 
// small amount of blurring in some pictures.  (Better than the speckles,
// I promise :)
#define DESPECKLE

#endif
