#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <gpslib/magellan.h>
#include <gpslib/serial.h>
#include <gpslib/gps.h>


/* Global Data */

#define MY_CXT_KEY "GPS::Magellan::_guts" XS_VERSION


typedef struct {
    /* Put Global Data in here */
    int Serial;		/* you can access this elsewhere as MY_CXT.Serial */
} my_cxt_t;

START_MY_CXT

int Serial;
int handshaking;


MODULE = GPS::Magellan		PACKAGE = GPS::Magellan		

BOOT:
{
    MY_CXT_INIT;
    /* If any of the fields in the my_cxt_t struct need
       to be initialised, do it here.
     */
}


int
ClosePort()


SV *
magellan_findmessage(Prefix)
    char * Prefix
    PREINIT:
        char msg[MAXLEN] = "";
        int rc;
    CODE:
        if(Prefix == NULL || ! strcmp(Prefix, "")){
            croak("magellan_findmessage(): need PREFIX.\n");
            XSRETURN_UNDEF;
        }
        rc = MagFindMessage(Prefix, (char *)&msg, MAXLEN);
        if(rc){
            XSRETURN_UNDEF;
        }
        RETVAL = newSVpv(msg, 0);
    OUTPUT:
        RETVAL

int
OpenPort(port)
	char *	port

int
ReadMessage(Message, MaxLen)
	char *	Message
	int	MaxLen

int
MagWriteMessageSum(Message)
	char *	Message

int
MagWriteMessageNoAck(Message)
	char *	Message


int
WriteMessage(Message)
	char *	Message

int
magellan_del_waypoint(wptname)
	char *	wptname

MWpt *
magellan_dl_waypoints(cmd)
	char *	cmd

void
magellan_handoff()

void
magellan_handon()

int
magellan_init()

void
magellan_ul_waypoints(FName)
	char *	FName

void
magellan_get_linked_list(List)
    MWpt *List
    PREINIT:
        MWpt *Cur;
        SV *sv_coord;
    PPCODE:
        if(List == NULL){
            croak("magellan_get_linked_list(): got NULL.\n");
            XSRETURN_UNDEF;
        }

        Cur = List->Next;

        while (Cur != NULL) {
            sv_coord = sv_newmortal();
            sv_setref_pv(sv_coord, "MWptPtr", (void *) Cur);
            XPUSHs(sv_coord);
            Cur = Cur->Next;
        }



MODULE = GPS::Magellan		PACKAGE = MWpt		

MWpt *
_to_ptr(THIS)
	MWpt THIS = NO_INIT
    PROTOTYPE: $
    CODE:
	if (sv_derived_from(ST(0), "MWpt")) {
	    STRLEN len;
	    char *s = SvPV((SV*)SvRV(ST(0)), len);
	    if (len != sizeof(THIS))
		croak("Size %d of packed data != expected %d",
			len, sizeof(THIS));
	    RETVAL = (MWpt *)s;
	}   
	else
	    croak("THIS is not of type MWpt");
    OUTPUT:
	RETVAL

MWpt
new(CLASS)
	char *CLASS = NO_INIT
    PROTOTYPE: $
    CODE:
	Zero((void*)&RETVAL, sizeof(RETVAL), char);
    OUTPUT:
	RETVAL

MODULE = GPS::Magellan		PACKAGE = MWptPtr		

double
Latitude(THIS, __value = NO_INIT)
	MWpt * THIS
	double __value
    PROTOTYPE: $;$
    CODE:
	if (items > 1)
	    THIS->Latitude = __value;
	RETVAL = THIS->Latitude;
    OUTPUT:
	RETVAL

char
LatDir(THIS, __value = NO_INIT)
	MWpt * THIS
	char __value
    PROTOTYPE: $;$
    CODE:
	if (items > 1)
	    THIS->LatDir = __value;
	RETVAL = THIS->LatDir;
    OUTPUT:
	RETVAL

double
Longitude(THIS, __value = NO_INIT)
	MWpt * THIS
	double __value
    PROTOTYPE: $;$
    CODE:
	if (items > 1)
	    THIS->Longitude = __value;
	RETVAL = THIS->Longitude;
    OUTPUT:
	RETVAL

char
LongDir(THIS, __value = NO_INIT)
	MWpt * THIS
	char __value
    PROTOTYPE: $;$
    CODE:
	if (items > 1)
	    THIS->LongDir = __value;
	RETVAL = THIS->LongDir;
    OUTPUT:
	RETVAL

long
Altitude(THIS, __value = NO_INIT)
	MWpt * THIS
	long __value
    PROTOTYPE: $;$
    CODE:
	if (items > 1)
	    THIS->Altitude = __value;
	RETVAL = THIS->Altitude;
    OUTPUT:
	RETVAL

char
AltType(THIS, __value = NO_INIT)
	MWpt * THIS
	char __value
    PROTOTYPE: $;$
    CODE:
	if (items > 1)
	    THIS->AltType = __value;
	RETVAL = THIS->AltType;
    OUTPUT:
	RETVAL

char *
Name(THIS, __value = NO_INIT)
	MWpt * THIS
	char *__value
    PROTOTYPE: $;$
    CODE:
	if (items > 1)
	    strcpy(THIS->Name, __value);
	RETVAL = THIS->Name;
    OUTPUT:
	RETVAL

char *
Desc(THIS, __value = NO_INIT)
	MWpt * THIS
	char *__value
    PROTOTYPE: $;$
    CODE:
	if (items > 1)
	    strcpy(THIS->Desc,  __value);
	RETVAL = THIS->Desc;
    OUTPUT:
	RETVAL

char
Icon(THIS, __value = NO_INIT)
	MWpt * THIS
	char __value
    PROTOTYPE: $;$
    CODE:
	if (items > 1)
	    THIS->Icon = __value;
	RETVAL = THIS->Icon;
    OUTPUT:
	RETVAL

struct mWpT *
Next(THIS, __value = NO_INIT)
	MWpt * THIS
	struct mWpT * __value
    PROTOTYPE: $;$
    CODE:
	if (items > 1)
	    THIS->Next = __value;
	RETVAL = THIS->Next;
    OUTPUT:
	RETVAL

void
Dump(THIS)
	MWpt * THIS
    CODE:
        fprintf(stderr, "----------------------\n");
        fprintf(stderr, "WPT: %s\n", THIS->Name);
        fprintf(stderr, "----------------------\n");
        fprintf(stderr, "Desc:      %s\n", THIS->Desc);
        fprintf(stderr, "Latitude:  %08.3f\n", THIS->Latitude);
        fprintf(stderr, "LatDir:    %08.3f\n", THIS->LatDir);
        fprintf(stderr, "Longitude: %08.3f\n", THIS->Longitude);
        fprintf(stderr, "LongDir:   %08.3f\n", THIS->LongDir);
        fprintf(stderr, "Altitude:  %08.3f\n", THIS->Altitude);
        fprintf(stderr, "AltType:   %08.3f\n", THIS->AltType);
        fprintf(stderr, "Icon:      %c\n", THIS->Icon);
        fprintf(stderr, "----------------------\n");

