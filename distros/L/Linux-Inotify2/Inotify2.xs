#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <unistd.h>
#include <fcntl.h>

#include <sys/inotify.h>

MODULE = Linux::Inotify2                PACKAGE = Linux::Inotify2

PROTOTYPES: ENABLE

BOOT:
{
        HV *stash = gv_stashpv ("Linux::Inotify2", 0);

        newCONSTSUB (stash, "IN_ACCESS"       , newSViv (IN_ACCESS));
        newCONSTSUB (stash, "IN_MODIFY"       , newSViv (IN_MODIFY));
        newCONSTSUB (stash, "IN_ATTRIB"       , newSViv (IN_ATTRIB));
        newCONSTSUB (stash, "IN_CLOSE_WRITE"  , newSViv (IN_CLOSE_WRITE	));
        newCONSTSUB (stash, "IN_CLOSE_NOWRITE", newSViv (IN_CLOSE_NOWRITE));
        newCONSTSUB (stash, "IN_OPEN"         , newSViv (IN_OPEN));
        newCONSTSUB (stash, "IN_MOVED_FROM"   , newSViv (IN_MOVED_FROM));
        newCONSTSUB (stash, "IN_MOVED_TO"     , newSViv (IN_MOVED_TO));
        newCONSTSUB (stash, "IN_CREATE"       , newSViv (IN_CREATE));
        newCONSTSUB (stash, "IN_DELETE"       , newSViv (IN_DELETE));
        newCONSTSUB (stash, "IN_DELETE_SELF"  , newSViv (IN_DELETE_SELF));
        newCONSTSUB (stash, "IN_MOVE_SELF"    , newSViv (IN_MOVE_SELF));
        newCONSTSUB (stash, "IN_UNMOUNT"      , newSViv (IN_UNMOUNT));
        newCONSTSUB (stash, "IN_Q_OVERFLOW"   , newSViv (IN_Q_OVERFLOW));
        newCONSTSUB (stash, "IN_IGNORED"      , newSViv (IN_IGNORED));
        newCONSTSUB (stash, "IN_CLOSE"        , newSViv (IN_CLOSE));
        newCONSTSUB (stash, "IN_MOVE"         , newSViv (IN_MOVE));
        newCONSTSUB (stash, "IN_ONLYDIR"      , newSViv (IN_ONLYDIR));
        newCONSTSUB (stash, "IN_DONT_FOLLOW"  , newSViv (IN_DONT_FOLLOW));
        newCONSTSUB (stash, "IN_MASK_ADD"     , newSViv (IN_MASK_ADD));
        newCONSTSUB (stash, "IN_ISDIR"        , newSViv (IN_ISDIR));
        newCONSTSUB (stash, "IN_ONESHOT"      , newSViv (IN_ONESHOT));
        newCONSTSUB (stash, "IN_ALL_EVENTS"   , newSViv (IN_ALL_EVENTS));
}

int
inotify_init ()

void
inotify_close (int fd)
	CODE:
        close (fd);

int
inotify_add_watch (int fd, char *name, U32 mask)

int
inotify_rm_watch (int fd, U32 wd)

int
inotify_blocking (int fd, I32 blocking)
  	CODE:
        fcntl (fd, F_SETFL, blocking ? 0 : O_NONBLOCK);

void
inotify_read (int fd, int size = 8192)
	PPCODE:
{
	char buf [size], *cur, *end;
        int got = read (fd, buf, size);

        if (got < 0)
          if (errno != EAGAIN && errno != EINTR)
            croak ("Linux::Inotify2: read error while reading events");
          else
            XSRETURN_EMPTY;

        cur = buf;
        end = buf + got;

        while (cur < end)
          {
            struct inotify_event *ev = (struct inotify_event *)cur;
            cur += sizeof (struct inotify_event) + ev->len;

            while (ev->len > 0 && !ev->name [ev->len - 1])
              --ev->len;
            
            HV *hv = newHV ();
            hv_store (hv, "wd",     sizeof ("wd")     - 1, newSViv (ev->wd), 0);
            hv_store (hv, "mask",   sizeof ("mask")   - 1, newSViv (ev->mask), 0);
            hv_store (hv, "cookie", sizeof ("cookie") - 1, newSViv (ev->cookie), 0);
            hv_store (hv, "name",   sizeof ("name")   - 1, newSVpvn (ev->name, ev->len), 0);

            XPUSHs (sv_2mortal (newRV_noinc ((SV *)hv)));
          }
}


