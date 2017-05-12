/* $Id: test1.c 53 2007-03-10 14:46:36Z bja $ 
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
#include <math.h>

#include "wiimote.h"
#include "wiimote_api.h"

int main(int argc, char **argv)
{
	wiimote_t wiimote = WIIMOTE_INIT;
	wiimote_report_t report = WIIMOTE_REPORT_INIT;
	
	if (argc < 2) {
		fprintf(stderr, "Usage: test1 BDADDR\n");
		exit(1);
	}
	
	/* Print help information. */
	
	printf("test1 - libwiimote test application\n\n");
	printf(" A    - Enable accelerometer\n");
	printf(" B    - Enable ir-sensor\n");
	printf(" 1    - Enable rumble\n");
	printf(" +    - Increment leds\n");
	printf(" -    - Decrement leds\n");
	printf(" Home - Exit\n\n");
	printf("Press buttons 1 and 2 on the wiimote now to connect.\n");
	
	/* Connect the wiimote specified on the command line. */
	
	if (wiimote_connect(&wiimote, argv[1]) < 0) {
		fprintf(stderr, "unable to open wiimote: %s\n", wiimote_get_error());
		exit(1);
	}

	/* Activate the first led on the wiimote. It will take effect on the
	   next call to wiimote_update. */

	wiimote.led.one  = 1;

	while (wiimote_is_open(&wiimote)) {
		
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
		
		/* To see if a specific key has been pressed you can either test
		   a specific member of the 'keys' structure, or compare them all
		   at once with a bit mask. See wiimote_event.h for details. */ 
		
		if (wiimote.keys.bits & WIIMOTE_KEY_1) {
			/* This will activate the rumble feature on the next update.
			   The wiimote will rumble until the 'one' key is released. */		
			wiimote.rumble = 1;
		}
		else {
			/* Disable rumble on the next update. */ 
			wiimote.rumble = 0;
		}

		/* Prepare and send a status report request. */
					
		if (wiimote.keys.two) {
			report.channel = WIIMOTE_RID_STATUS;
			if (wiimote_report(&wiimote, &report, sizeof (report.status)) < 0) {
				wiimote_perror("unable to get status report");
			}
		}

		/* Activate the IR-sensor when the 'B' key is pressed. */

		if (wiimote.keys.b) {
			wiimote.mode.ir = 1;
		}
		else {
			wiimote.mode.ir = 0;
		}

		/* Activate the accelerometer when the 'A' key is pressed. */

		if (wiimote.keys.a) {
			wiimote.mode.acc = 1;
		}
		else {
			wiimote.mode.acc = 0;
		}

		/* Change the LEDs on the wiimote when the plus and minus keys
		   are pressed. */

		if (wiimote.keys.plus) {
			wiimote.led.bits += 1;
		}

		if (wiimote.keys.minus) {
			wiimote.led.bits -= 1;
		}
		
		/* Print the current state of the wiimote. */

		fprintf(stderr, "MODE %02x\n", wiimote.mode.bits);

		fprintf(stderr, "BAT %02x\n", wiimote.battery);
		
		fprintf(stderr, "KEYS %04x one=%d two=%d a=%d b=%d <=%d >=%d ^=%d v=%d h=%d +=%d -=%d\n",
			wiimote.keys.bits, 
			wiimote.keys.one,
			wiimote.keys.two,
			wiimote.keys.a,
			wiimote.keys.b,
			wiimote.keys.left,
			wiimote.keys.right,
			wiimote.keys.up,
			wiimote.keys.down,
			wiimote.keys.home,
			wiimote.keys.plus,
			wiimote.keys.minus);
			
		fprintf(stderr, "JOY1 joyx=%03d joyy=%03d x=%03d y=%03d z=%03d keys.z=%d keys.c=%d\n", 
			wiimote.ext.nunchuk.joyx,
			wiimote.ext.nunchuk.joyy,
			wiimote.ext.nunchuk.axis.x,
			wiimote.ext.nunchuk.axis.y,
			wiimote.ext.nunchuk.axis.z,
			wiimote.ext.nunchuk.keys.z,
			wiimote.ext.nunchuk.keys.c);

		fprintf(stderr, "JOY2 joyx=%03d joyy=%03d\n", 
			wiimote.ext.classic.joyx1,
			wiimote.ext.classic.joyy1);


		fprintf(stderr, "JOY3 joyx=%03d joyy=%03d\n", 
			wiimote.ext.classic.joyx2,
			wiimote.ext.classic.joyy2);

		fprintf(stderr, "AXIS x=%03d y=%03d z=%03d\n", 
			wiimote.axis.x,
			wiimote.axis.y,
			wiimote.axis.z);

#ifdef _ENABLE_TILT
		fprintf(stderr, "TILT x=%.3f y=%.3f z=%.3f\n", 
			wiimote.tilt.x,
			wiimote.tilt.y,
			wiimote.tilt.z);
#endif

#ifdef _ENABLE_FORCE		
		fprintf(stderr, "FORCE x=%.3f y=%.3f z=%.3f (sum=%.3f)\n", 
			wiimote.force.x,
			wiimote.force.y,
			wiimote.force.z,
			sqrt(wiimote.force.x*wiimote.force.x+wiimote.force.y*wiimote.force.y+wiimote.force.z*wiimote.force.z));
#endif
		fprintf(stderr, "IR1 x=%04d y=%04d ss=%d\n",
			wiimote.ir1.x,
			wiimote.ir1.y,
			wiimote.ir1.size);

		fprintf(stderr, "IR2 x=%04d y=%04d ss=%d\n",
			wiimote.ir2.x,
			wiimote.ir2.y,
			wiimote.ir2.size);

		fprintf(stderr, "IR3 x=%04d y=%04d ss=%d\n",
			wiimote.ir3.x,
			wiimote.ir3.y,
			wiimote.ir3.size);
			
		fprintf(stderr, "IR4 x=%04d y=%04d ss=%d\n",
			wiimote.ir4.x,
			wiimote.ir4.y,
			wiimote.ir4.size);
								
		fprintf(stderr, "\n");
	}
	return 0;
}
