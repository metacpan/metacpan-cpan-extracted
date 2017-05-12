#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define SD_JOURNAL_SUPPRESS_LOCATION
#include <systemd/sd-journal.h>

MODULE = Linux::Systemd::Journal::Write	PACKAGE = Linux::Systemd::Journal::Write

PROTOTYPES: DISABLE

NO_OUTPUT int
__sd_journal_print(int pri, const char *msg, ...)
    CODE:
        RETVAL = sd_journal_print( pri, "%s", msg );
    POSTCALL:
        if (RETVAL < 0)
             croak("Error %d while sending message", RETVAL);

NO_OUTPUT int
__sd_journal_perror(const char *msg)
    CODE:
        RETVAL = sd_journal_perror(msg );
    POSTCALL:
        if (RETVAL < 0)
             croak("Error %d while sending message", RETVAL);

NO_OUTPUT int
__sd_journal_send(AV *data)
    CODE:
        int array_size = av_len(data) + 1;
        struct iovec iov[array_size];

        for (int i = 0; i < array_size; i++) {
            SV *s = av_shift(data);
            char *str = SvPV(s, SvLEN(s));
            iov[i].iov_base = str;
            iov[i].iov_len = strlen(str);
        }

        RETVAL = sd_journal_sendv(iov, array_size);
    POSTCALL:
        if (RETVAL < 0)
             croak("Error sending message: %s", strerror(RETVAL));

