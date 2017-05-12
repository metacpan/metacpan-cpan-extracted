#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <systemd/sd-daemon.h>

MODULE = Linux::Systemd::Daemon	PACKAGE = Linux::Systemd::Daemon

PROTOTYPES: DISABLE

NO_OUTPUT int
notify(const char *state)
    CODE:
        RETVAL = sd_notify( 0, state );
    POSTCALL:
        if (RETVAL < 0)
             croak("Error %d while sending notification", RETVAL);
