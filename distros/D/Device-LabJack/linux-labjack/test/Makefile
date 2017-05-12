#
# Makefile for labjack test applications
#
# Copyright (c) 2003 Eric Sorton <erics@cfl.rr.com>
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 2 of the License, or (at your option)
# any later version.
#

all: firmware-revision analog-outs list-all
	
firmware-revision: firmware-revision.c
	$(CC) $< -o $@ -I../liblabjack/ -L../liblabjack/ -llabjack -lm

analog-outs: analog-outs.c
	$(CC) $< -o $@ -I../liblabjack/ -L../liblabjack/ -llabjack -lm

list-all: list-all.c
	$(CC) $< -o $@ -I../liblabjack/ -L../liblabjack/ -llabjack -lm

clean:
	rm -f firmware-revision analog-outs list-all
