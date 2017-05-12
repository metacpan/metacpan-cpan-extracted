/*
    GPSUTIL a program to interact with NMEA compatable and other supported
      GPS units.

    Copyright (C) 2000  Brian J. Hennings

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

    I can be contacted at hennings@cs.uakron.edu or by US mail at:

    Brian Hennings
    114 Rex Ave.
    Wintersville, OH 43953
*/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "gps.h"
#include "serial.h"
#include "magellan.h"

#define DEBUG 1

extern int          handshaking;

/***********************/
/* Function Prototypes */
/***********************/
unsigned char MChecksum (char *Data);

/*****************************************************************************
 * MChecksum () - Takes a complete Megellan message and computes the
 *     checksum value.  **NOTE**  The Protocol document v1.0 is incorrect
 *     about the checksum value -- it DOES NOT include the $ or the *
 *****************************************************************************/
unsigned char MChecksum (char *Data)
{unsigned char CheckVal;
 int           len, idx;

 CheckVal = 0;
 len = strlen (Data) - 1;  //Don't include the '*' at end of message!

//idx starts at 1 becuase the '$' isn't part of the checksum!
 for (idx = 1; idx < len; idx++) {
   CheckVal = CheckVal ^ Data[idx];   //The ^ is an XOR in C
 } /*End of for*/

 return CheckVal;
} /*End of MChecksum ()*/

/*****************************************************************************
 * MPChecksum () - Computes the checksum using the characters (skipping the
 *     first one) through the specified length.
 *****************************************************************************/
unsigned char MPChecksum (char *Data, int length, int offset)
{unsigned char CheckVal = 0;
 int           idx;

 for (idx = offset; idx < length; idx++) {
   CheckVal ^= Data[idx];
 } /*End of for*/

 return CheckVal;
} /*End of MPChecksum ()*/

/*****************************************************************************
 * MagWriteMessageNoAck () - Write a message and don't check for an ACK
 *****************************************************************************/
int MagWriteMessageNoAck (char *Message)
{char          buf[MAXLEN];
 unsigned char Check;

 Check = MPChecksum (Message, strlen (Message), 0);
 sprintf (buf, "$%s*%02X", Message, Check);

 if (DEBUG > 2)
   printf ("MagWriteMessageNoAck: Sending %s\n", buf);

 return WriteMessage (buf);
} /*End of MagWriteMessageNoAck ()*/

/*****************************************************************************
 * MagFindMessage () - Used to call the FindMessage routine and support
 *     handshaking.
 *****************************************************************************/
int MagFindMessage (char *Prefix, char *Msg, int MaxLen)
{char          buf[MAXLEN];
 int           Status;

 Status = FindMessage (Prefix, Msg, MaxLen);

 if ((Status == NO_DATA_RETURNED) && handshaking) {

   if (DEBUG)
     printf ("MagFindMessage: got no data returned error and in hand shaking mode, retrying\n");

   sprintf (buf, "PMGNCSM,00");
   MagWriteMessageNoAck (buf);

   /* We failed to get any data, send a NO ACK and try again! */
   Status = FindMessage (Prefix, Msg, MaxLen);
 } /*End of if*/

 return Status;
} /*End of MagFindMessage ()*/

/*****************************************************************************
 * MagWriteMessageSum () - Write a message and look for its ACK.  If the ack's
 *     checksum doesn't match, resend the message.
 *****************************************************************************/
int MagWriteMessageSum (char *Message)
{char          buf[MAXLEN],
               Msg[MAXLEN];
 int           rc, rv, loopcount,
               Done = FALSE,
               foundsum;
 unsigned char Check;

 Check = MPChecksum (Message, strlen (Message), 0);
 sprintf(buf, "$%s*%02X", Message, Check);

  loopcount = 0;
  while (!Done) {
    loopcount++;
    rv = WriteMessage(buf);

    if (DEBUG > 2)
      printf ("MagWriteMessageSum: Sending %s\n", buf);

    if (!handshaking)
      Done = TRUE;

    if (loopcount > MAXLOOP)
      Done = TRUE;
  /*
   * If we're in handshaking mode, look for the checksum message
   * coming back.  Verify it matches the one we just computed for
   * the message we sent.   While they differ, retransmit.
   */

    if (rv >= 0 && handshaking) {
      rc = MagFindMessage ("$PMGNCSM", Msg, MAXLEN);
      foundsum = strtol (Msg+9, NULL, 16);
      if (Check == foundsum) {
        Done = TRUE;
      } /*End of if (Check)*/
      else {
        if (DEBUG > 4) {
          printf("***Retrying: Found %x Wanted %x\n",
                 foundsum, Check);
        } /*End of if (DEBUG)*/
      } /*End of else*/
    } /*End of if (rv)*/
  } /*End of while*/

  return rv;
} /*End of MagWriteMessageSum ()*/

/*****************************************************************************
 * AddWpt () - Adds a waypoint to a linked list.  Note -- due to the fun
 *     involved with double pointers, I decided for easier to follow code to
 *     expect an empty list to contain 1 element with the name string NULL.
 *****************************************************************************/
static void AddWpt (char *Msg, MWpt *List)
{MWpt *Node = NULL, *At = NULL;
 int idx;
 char msg[20];

 Node = (MWpt *) malloc (sizeof (MWpt));

 if (Node == NULL) {
   printf ("Panic!!!  malloc (MWPT) failed!\n");
   exit (-99);
 }

 Node->Desc[0] = '\0';

 idx =  sscanf (Msg, "%[^,],%le,%c,%le,%c,%ld,%c,%[^,],%[^,],%c",msg,
                &Node->Latitude, &Node->LatDir,
                &Node->Longitude, &Node->LongDir,
                &Node->Altitude, &Node->AltType,
                Node->Name, Node->Desc,&Node->Icon);

 if (idx < 9)
   Node->Icon = 'a';

 Node->Next = NULL;

 if (List->Name[0] == '\0') {
   memcpy (List, Node, sizeof (MWpt));
   free (Node);
 }
 else {
   At = List;
   while (At->Next != NULL){
/*       fprintf(stderr, "DEBUG At = %p, At->Next=%p\n", At, At->Next); */
     At = At->Next;
   }
   At->Next = Node;
 }

} /*End of AddWpt ()*/

/*****************************************************************************
 * magellan_handon () - Sends a hand shaking on
 *****************************************************************************/
void magellan_handon ()
{
 MagWriteMessageSum ("PMGNCMD,HANDON");
 handshaking = 1;

} /*End of magellan_handon ()*/

/*****************************************************************************
 * magellan_handoff () - Sends a hand shaking off
 *****************************************************************************/
void magellan_handoff ()
{char Msg[MAXLEN];

 handshaking = 0;
 MagWriteMessageSum ("PMGNCMD,HANDOFF");
 MagFindMessage ("$PMGNCSM,3E", Msg, MAXLEN);

} /*End of magellan_handoff ()*/

/*****************************************************************************
 * magellan_del_waypoint () - Deletes a waypoint with the specified name
 *****************************************************************************/
int magellan_del_waypoint (char *wptname)
{char Msg[MAXLEN];
 int  rc;

 sprintf(Msg, "PMGNDWP,%s",wptname);
 MagWriteMessageNoAck (Msg);
 rc = MagFindMessage ("$PMGN", Msg, MAXLEN);
 printf ("%s ", wptname);

 if (strncmp(Msg+9, "UNABLE",6) == 0) {
  printf ("not ");
 } /*End of if*/

 printf ("deleted.\n");

 return (rc);
} /*End of magellan_del_waypoint ()*/

/*****************************************************************************
 * magellan_send_waypoint () - Sends a single waypoint to the GPS receiver.
 *****************************************************************************/
int magellan_send_waypoint (MWpt Point)
{char Tmp[MAXLEN];
 int  RetVal = 0;

 if (DEBUG > 2) {
   printf ("Uploading Waypoint: %-8s %08.3f%c %09.3f%c %07ld%c %-30s %c\n",
           Point.Name, Point.Latitude, Point.LatDir, Point.Longitude,
           Point.LongDir, Point.Altitude, Point.AltType, Point.Desc,
           Point.Icon);
 } /*End of if*/

 sprintf (Tmp, "PMGNWPL,%04.3f,%c,%05.3f,%c,%07ld,%c,%s,%s,%c",
          Point.Latitude, Point.LatDir, Point.Longitude, Point.LongDir,
          Point.Altitude, Point.AltType, Point.Name, Point.Desc,
          Point.Icon);
 MagWriteMessageSum(Tmp);

 return RetVal;
} /*End of magellan_send_waypoint ()*/

/*****************************************************************************
 * magellan_dl_waypoints () - Creates a linked list of all waypoints stored on the
 *     GPS receiver.
 *****************************************************************************/
MWpt * magellan_dl_waypoints (char *cmd)
{char          Tmp[MAXLEN], Msg[MAXLEN], Old[MAXLEN];
 int           len, Done = FALSE, ECnt, rc, RetVal = 0;
 unsigned char ComputedCheck;
 char          *MsgType[3 + 1]; /* 3 chars type, 1 NULL */

 MWpt *List = (MWpt *) malloc (sizeof (MWpt));

 memset(List, 0, sizeof(MWpt));

 ECnt = 0;

 magellan_handon ();

 sprintf(Tmp, "PMGNCMD,%s", cmd);
 MagWriteMessageSum (Tmp);

 while (!Done) {
   rc = MagFindMessage ("$PMGN", Msg, MAXLEN);
   if (rc == 0) {
     ECnt = 0;
     if (DEBUG > 0)
       printf ("Received: %s\n", Msg);
     strcpy (Old, Msg);

     if ((Msg[5] == 'C') && (Msg[6] == 'S') && (Msg[7] == 'M')) {
       continue;
     }

     strncpy((char *)MsgType, Msg+5, 3);

     if(strcmp((char *)MsgType, "TRK") && strcmp((char *)MsgType, "WPL")){
       continue;
     }
     fprintf(stderr, "adding new: %s (%p -> %p)\n", Msg, List, Msg);
     AddWpt (Msg, List);

     len = strlen (Msg);
     ComputedCheck = MPChecksum(Msg, len-3, 1);
     sprintf (Tmp, "PMGNCSM,%02X", ComputedCheck);
     MagWriteMessageNoAck (Tmp);

     printf("%s\n", Msg);

     if (strcmp (Old, "$PMGNCMD,END*3D") == 0) {
       Done = TRUE;
     }
   } /*End of if*/
   else {
     ECnt++;
     if (ECnt > MAXERR) {
       Done = TRUE;
       RetVal = -1;
     }
   }
 }
 magellan_handoff();

 return List;
} /*End of MAgellanDLWPts ()*/

/*****************************************************************************
 * FixStr () - A quick function to remove all trailing spaces at the end of a
 *     string.
 *****************************************************************************/
static void FixStr (char *Str)
{int Len, idx;

 Len = strlen (Str) - 1;
 for (idx = Len; idx >= 0; idx--)
   if (Str[idx] == ' ')
     Str[idx] = '\0';
   else
     break;

} /*End of FixStr ()*/

/*****************************************************************************
 * RestoreWPts () - Sends all waypoints in the file to the GPS unit.
 *****************************************************************************/
void magellan_ul_waypoints (char *FName)
{MWpt Coord;
 int  idx, Done = FALSE;
 char InChar, Tmp[25];
 FILE *IFile;

 if (strcmp (FName, "-") == 0)
   IFile = stdin;
 else {
   if ((IFile = fopen (FName, "r")) == NULL) {
     printf ("Unable to open input file!\n");
     return;
   } /*End of if*/
 } /*End of if*/

 magellan_handon();
 while (!Done) {
   InChar = fgetc (IFile);
   if (InChar == '\n')
     InChar = fgetc (IFile);
   if (InChar == EOF)
     break;
   if (InChar == '#') {
     while (fgetc (IFile) != '\n');  //Lines that start with # are skipped!
   } /*End of if*/
   else
     ungetc (InChar, IFile);

   for (idx = 0; idx < 8; idx++)
     Tmp[idx] = fgetc (IFile);
   Tmp[idx] = '\0';
   FixStr (Tmp);
   strcpy (Coord.Name, Tmp);
   fgetc (IFile);                    //Space between each column.
   for (idx = 0; idx < 8; idx++)
     Tmp[idx] = fgetc (IFile);
   Tmp[idx] = '\0';
   Coord.Latitude = atof (Tmp);
   Coord.LatDir = fgetc (IFile);
   fgetc (IFile);                    //Space between each column.
   for (idx = 0; idx < 9; idx++)
     Tmp[idx] = fgetc (IFile);
   Tmp[idx] = '\0';
   Coord.Longitude = atof (Tmp);
   Coord.LongDir = fgetc (IFile);
   fgetc (IFile);                    //Space between each column.
   for (idx = 0; idx < 7; idx++)
     Tmp[idx] = fgetc (IFile);
   Tmp[idx] = '\0';
   Coord.Altitude = atol (Tmp);
   Coord.AltType = fgetc (IFile);
   fgetc (IFile);                    //Space between each column.
   for (idx = 0; idx < 30; idx++)
     Tmp[idx] = fgetc (IFile);
   Tmp[idx] = '\0';
   FixStr (Tmp);
   strcpy (Coord.Desc, Tmp);
   fgetc (IFile);                    //Space between each column.
   Coord.Icon = fgetc (IFile);
   while (fgetc (IFile) != '\n');    //Skip rest of line.

   magellan_send_waypoint (Coord);
 } /*End of while*/
 magellan_handoff();

} /*End of RestoreWPts ()*/

/*****************************************************************************
 * magellan_init () - Used to determine that a Megellan GPS is attached to the
 *    specified port.
 *****************************************************************************/
int magellan_init ()
{char Msg[MAXLEN];
 int  RVal;

 handshaking = 0;
// MagWriteMessageSum ("PMGNCMD,STOP");
 MagWriteMessageSum ("PMGNCMD,HANDOFF");
 MagWriteMessageSum ("PMGNCMD,VERSION");
 RVal = MagFindMessage ("$PMGNVER", Msg, MAXLEN);

 if (RVal == 0) {
   if (DEBUG > 0)
      printf ("Found: %s\n", Msg);

   return 0;
 } /*End of if*/

 return -1;
} /*End of magellan_init ()*/

/*****************************************************************************
 * magellan_free_waypoints () - Simple function to free up memory allocated during building
 *     a waypoint list.
 *****************************************************************************/
int magellan_free_waypoints (MWpt *List)
{MWpt *Cur, *Tmp;

 Cur = List->Next;
 while (Cur != NULL) {
   Tmp = Cur;
   Cur = Cur->Next;
   free (Tmp);
 }

 return 0;
} /*End of magellan_free_waypoints ()*/

