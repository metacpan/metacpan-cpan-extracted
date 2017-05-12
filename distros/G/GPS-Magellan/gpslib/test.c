
#include <stdio.h>
#include <stdlib.h>
#include <signal.h>

#include "serial.h"
#include "magellan.h"

#define PORT   "/dev/ttyS0"

#define CMD_HANDOFF     "HANDOFF"
#define CMD_HANDON      "HANDON"
#define CMD_VERSION     "VERSION"
#define CMD_TRACK       "TRACK"
#define CMD_WAYPOINT    "WAYPOINT"

int handshaking;
int Serial;

void SigHndlr (int Val)
{
 ClosePort ();
 exit (-1);
}

int main () {
    MWpt  *wplist, *wpt;

    if (OpenPort (PORT) != 0) {
        fprintf (stderr, "Unable to open serial port (%s)\n", PORT);
        return -1;
    }

    signal (SIGINT, SigHndlr);

    magellan_init();
  
    wplist = magellan_dl_waypoints(CMD_WAYPOINT);

    for( wpt = wplist; wpt != NULL; wpt = wpt->Next ){
        printf("%-8s %08.3f%c %09.3f%c %07ld%c %-30s %c\n",
            wpt->Name, wpt->Latitude, wpt->LatDir, wpt->Longitude,
            wpt->LongDir, wpt->Altitude, wpt->AltType, wpt->Desc,
            wpt->Icon);

    }
    
    magellan_free_waypoints (wplist);

    ClosePort ();

    return 0;

}
