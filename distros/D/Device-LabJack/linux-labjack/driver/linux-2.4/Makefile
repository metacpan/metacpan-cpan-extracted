#
# Makefile for labjack
#
# Copyright (c) 2003 Eric Sorton <erics@cfl.rr.com>
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 2 of the License, or (at your option)
# any later version.
#
# NOTE: You must change KERNEL_HEADERS to match the location of the kernel
#       headers on your system.  This varies by distribution and no path is
#       correct for all systems.
#

KERNEL_HEADERS=/usr/src/linux-2.4.21-37.EL/include

CFLAGS= -D__KERNEL__ -DMODULE -DMODVERSIONS -Wall -Wstrict-prototypes -O2 -fomit-frame-pointer \
	-fno-strict-aliasing -pipe -fno-strength-reduce -falign-loops=2 -falign-jumps=2 \
	-falign-functions=2 -I$(KERNEL_HEADERS) -include $(KERNEL_HEADERS)/linux/modversions.h

labjack.o : labjack.c

clean:
	rm -f *.o
