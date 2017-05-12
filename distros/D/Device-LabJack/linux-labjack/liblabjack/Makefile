#
# Makefile for liblabjack
#
# Copyright (c) 2003 Eric Sorton <erics@cfl.rr.com>
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 2 of the License, or (at your option)
# any later version.
#

liblabjack.so : ljackul.o
	$(CC) -o liblabjack.so -IPA -shared ljackul.c

clean:
	rm -f *.o *.so
