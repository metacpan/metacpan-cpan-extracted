/* $Id: test2.c 15 2007-01-09 01:19:31Z bja $ 
 *
 * Copyright (C) 2007, Joel Andersson <bja@kth.se>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/time.h>
#include <time.h>

#include "wiimote.h"
#include "wiimote_api.h"

int main(int argc, char **argv)
{
	wiimote_t wiimote = WIIMOTE_INIT;
	
	/* The sample to play (4-bit signed integer). */
	
	uint8_t sample[20] = {
		0x3c,0x3c,0x3c,0x3c,0x3c,0x3c,0x3c,0x3c,0x3c,0x3c,
		0x3c,0x3c,0x3c,0x3c,0x3c,0x3c,0x3c,0x3c,0x3c,0x3c
	};

	if (argc < 2) {
		fprintf(stderr, "Usage: test2 BDADDR\n");
		exit(1);
	}
	
	/* Print help information. */
	
	printf("\n");
	printf("TEST2 - SPEAKER TEST\n\n");
	printf(" A      - Play sample\n");
	printf(" TILT_X - Modulate frequency\n");
	printf(" TILT_Y - Modulate volume\n");
	printf(" HOME   - Exit\n\n");
	printf("Press buttons 1 and 2 on the wiimote now to connect.\n");
	
	/* Connect the wiimote specified on the command line. */
	
	if (wiimote_connect(&wiimote, argv[1]) < 0) {
		fprintf(stderr, "unable to open wiimote: %s\n", wiimote_get_error());
		exit(1);
	}

	/* Activate the first led on the wiimote. It will take effect on the
	   next call to wiimote_update. */

	wiimote.led.one  = 1;
	wiimote.mode.acc = 1;
	
	wiimote_speaker_init(&wiimote, WIIMOTE_FMT_S4, 0xff);

	while (wiimote_is_open(&wiimote)) {
		
		struct timeval tv;
		uint32_t timeout = 0;
		uint32_t t;

		/* The wiimote_update function is used to synchronize the wiimote
		   object with the real wiimote. It should be called as often as
		   possible in order to minimize latency. */
		
		if (wiimote_update(&wiimote) < 0) {
			wiimote_disconnect(&wiimote);
			break;
		}
		
		/* The wiimote object has member 'keys' which keep track of the
		   current key state. */
		
		if (wiimote.keys.home) {
			wiimote_disconnect(&wiimote);
		}
		
		if (wiimote.keys.a) {
			gettimeofday(&tv,NULL);
			t = (tv.tv_sec * 1e6 + tv.tv_usec) / 1e3;
			if (t > timeout) {
				wiimote_speaker_freq(&wiimote, wiimote.tilt.x+90);
				wiimote_speaker_volume(&wiimote, wiimote.tilt.y);
				wiimote_speaker_play(&wiimote, sample, 20);
				timeout = t + 100;
			}
		}
	}
	
	return 0;
}
