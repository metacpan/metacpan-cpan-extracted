/* $Id: test3.c 54 2007-03-10 14:54:20Z bja $ 
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

#include "wiimote.h"
#include "wiimote_api.h"

wiimote_t wiimote[4];

int main(int argc, char **argv)
{
    int nmotes = 0;
    int i = 0;
	
    /* Print help information. */
	
    printf("test3 - multiple libwiimote test application\n\n");
    printf(" 1    - Enable rumble\n");
    printf(" Home - Exit\n\n");
    printf("Press buttons 1 and 2 on the wiimote now to connect.\n");

    /* Discover at most four wiimote devices. */

    nmotes = wiimote_discover(wiimote, 4);
    if (nmotes == 0) {
	wiimote_error("no wiimotes were found");
	exit(1);
    }

    for (i=0; i<nmotes; i++) {
	printf("found: %s\n", wiimote[i].link.r_addr);
    }

    /* Connect to the discovered wiimotes and set the leds to
       identify the order in which they were discovered. */
	
    for (i=0; i<nmotes; i++) {
	if (wiimote_connect(&wiimote[i], wiimote[i].link.r_addr) < 0) {
	    fprintf(stderr, "unable to open wiimote: %s\n", wiimote_get_error());
	}
	else {
	    wiimote[i].led.bits  = 1 << i;
	    printf("connected to %s on %s\n", wiimote[i].link.r_addr, wiimote[i].link.l_addr);
	}
    }

    int alive = 1;

    while (alive) {

	/* Run loop for as long as at least one wiimote is connected. */

	alive = 0;

	for (i=0; i<nmotes; i++) {

	    if (wiimote_is_open(&wiimote[i])) {
		alive = 1;
	    }
	    else {
		continue;
	    }

	    if (!wiimote_pending(&wiimote[i])) {
		continue;
	    }

	    if (wiimote_update(&wiimote[i]) < 0) {
		wiimote_disconnect(&wiimote[i]);
		continue;
	    }

	    /* Disconnect the i:th wiimote if home key is pressed. */

	    if (wiimote[i].keys.home) {
		wiimote_disconnect(&wiimote[i]);
	    }

	    /* Enable rumble on i:th wiimote if the 1-key is pressed. */

	    if (wiimote[i].keys.one) {
		wiimote[i].rumble = 1;
	    }
	    else {
		wiimote[i].rumble = 0;
	    }

	    /* Print the current state of the i:th wiimote. */

	    fprintf(stderr, "KEYS[%d] %04x one=%d two=%d a=%d b=%d <=%d >=%d ^=%d v=%d h=%d +=%d -=%d\n",
		    i,
		    wiimote[i].keys.bits, 
		    wiimote[i].keys.one,
		    wiimote[i].keys.two,
		    wiimote[i].keys.a,
		    wiimote[i].keys.b,
		    wiimote[i].keys.left,
		    wiimote[i].keys.right,
		    wiimote[i].keys.up,
		    wiimote[i].keys.down,
		    wiimote[i].keys.home,
		    wiimote[i].keys.plus,
		    wiimote[i].keys.minus);
	}

	usleep(50000);
    }

    return 0;
}
