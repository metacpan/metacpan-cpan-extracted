#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <errno.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>
#include <sys/inotify.h>

#define LE_INOTIFY_READ_BUFFER 16384

MODULE = Linux::Event::Kernel::Inotify    PACKAGE = Linux::Event::Kernel::Inotify

PROTOTYPES: DISABLE

int
_new_fd()
    CODE:
        RETVAL = inotify_init1(IN_NONBLOCK | IN_CLOEXEC);
        if (RETVAL < 0)
            croak("inotify_init1: %s", Strerror(errno));
    OUTPUT:
        RETVAL

int
_add_watch(fd, path, mask)
        int fd
        const char *path
        UV mask
    CODE:
        RETVAL = inotify_add_watch(fd, path, (uint32_t)mask);
        if (RETVAL < 0)
            croak("inotify_add_watch %s: %s", path, Strerror(errno));
    OUTPUT:
        RETVAL

SV *
_add_watch_create(fd, path, mask)
        int fd
        const char *path
        UV mask
    PREINIT:
        int wd;
    CODE:
        wd = inotify_add_watch(fd, path, (uint32_t)mask | IN_MASK_CREATE);
        if (wd >= 0) {
            RETVAL = newSViv(wd);
        } else if (errno == EEXIST) {
            RETVAL = newSV(0);
        } else {
            croak("inotify_add_watch %s: %s", path, Strerror(errno));
        }
    OUTPUT:
        RETVAL

int
_rm_watch(fd, wd)
        int fd
        int wd
    CODE:
        if (inotify_rm_watch(fd, wd) == 0)
            RETVAL = 1;
        else if (errno == EINVAL)
            RETVAL = 0;
        else
            croak("inotify_rm_watch: %s", Strerror(errno));
    OUTPUT:
        RETVAL

SV *
_read_events(fd)
        int fd
    PREINIT:
        union {
            struct inotify_event align;
            char bytes[LE_INOTIFY_READ_BUFFER];
        } storage;
        char *buffer = storage.bytes;
        ssize_t got;
        size_t offset;
        AV *events;
    CODE:
        do {
            got = read(fd, buffer, sizeof(storage.bytes));
        } while (got < 0 && errno == EINTR);

        events = newAV();

        if (got < 0) {
            if (errno != EAGAIN && errno != EWOULDBLOCK) {
                SvREFCNT_dec((SV *)events);
                croak("inotify read: %s", Strerror(errno));
            }
        } else if (got > 0) {
            offset = 0;
            while (offset < (size_t)got) {
                struct inotify_event *event;
                size_t record_size;
                size_t name_len = 0;
                AV *row;

                if ((size_t)got - offset < sizeof(struct inotify_event)) {
                    SvREFCNT_dec((SV *)events);
                    croak("inotify read returned a truncated event header");
                }

                event = (struct inotify_event *)(buffer + offset);
                record_size = sizeof(struct inotify_event) + event->len;
                if (record_size > (size_t)got - offset) {
                    SvREFCNT_dec((SV *)events);
                    croak("inotify read returned a truncated event record");
                }

                row = newAV();
                av_push(row, newSViv(event->wd));
                av_push(row, newSVuv((UV)event->mask));
                av_push(row, newSVuv((UV)event->cookie));

                if (event->len) {
                    name_len = strnlen(event->name, event->len);
                    if (name_len)
                        av_push(row, newSVpvn(event->name, name_len));
                    else
                        av_push(row, newSV(0));
                } else {
                    av_push(row, newSV(0));
                }

                av_push(events, newRV_noinc((SV *)row));
                offset += record_size;
            }
        }

        RETVAL = newRV_noinc((SV *)events);
    OUTPUT:
        RETVAL

void
_close_fd(fd)
        int fd
    CODE:
        if (close(fd) < 0 && errno != EBADF)
            croak("close inotify fd: %s", Strerror(errno));
