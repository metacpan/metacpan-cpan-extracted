/* $Id: test4.c  
 *
 * Copyright (C) 2007, Chad Phillips <chad@chadphillips.org>
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

int
main (int argc, char **argv)
{
  wiimote_t wiimote = WIIMOTE_INIT;

  if (argc < 2)
    {
      fprintf (stderr, "Usage: test4 BDADDR\n");
      exit (1);
    }

  /* Print help information. */

  printf ("test4 - libcwiimote test application\n\n");
  printf (" Will scan MII slots and save them as files\n");
  printf ("Press buttons 1 and 2 on the wiimote now to connect.\n");

  /* Connect the wiimote specified on the command line. */

  if (wiimote_connect (&wiimote, argv[1]) < 0)
    {
      fprintf (stderr, "unable to open wiimote: %s\n", wiimote_get_error ());
      exit (1);
    }

  const char save_name[] = "wiimotefullmemorydump.txt";

  int slot = 0;

  /* Loop through all 10 mii slots.  Save used slots to filename slot_X.mii */
  while (slot < 10)
    {
      char save_name[10];
      sprintf (save_name, "slot_%d.mii", slot);
      int slotinuse = wiimote_mii_slot_state (&wiimote, slot);
      if (slotinuse)
	{
	  printf ("mii slot %d is in use \n", slot);
	  if (wiimote_mii_dump (&wiimote, save_name, slot) == WIIMOTE_OK)
	    {
	      printf ("Saved mii slot %d . \n", slot);
	    }
	}
      else
	{
	  printf ("mii slot %d is empty \n", slot);
	}
      slot++;
    }

  // Do a dump of all the memory on the wiimote
  wiimote_mii_dump_all (&wiimote, save_name);
  return 0;

}
