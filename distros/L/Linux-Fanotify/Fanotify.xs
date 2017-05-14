/*
 * Copyright (C) 2014 Bastian Friedrich
 * <bastian.friedrich@collax.com> / <bastian@friedrich.link>
 */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <pwd.h>
#include <unistd.h>
#include <sys/fanotify.h>

#include "const-c.inc"

/*
 *******************************************************************************
 * Code documentation for perl methods and functions can be found in the
 * module's pod
 *******************************************************************************
 */

#define PERLCLASS_NOTGRP "Linux::Fanotify::FanotifyGroup"
#define PERLCLASS_EVENT "Linux::Fanotify::Event"

/*
 * We don't want to expose functionality to write one event's fd to a
 * notification group where it did not originate. fanotify_bundle
 * is the event metadata, plus its originating notification group
 */

struct fanotify_bundle {
	struct fanotify_event_metadata metadata;
	int fd;	/* Notification group fd */
	unsigned short int needs_response;
};

/*
 * Convert a perl SV for a notification group to a file descriptor
 */
int
notgrp2fd(SV *notgrp, int *dst) {
	SV *sv;

	if (!SvROK(notgrp)) {
		/* No RV */
		return 0;
	}
	if (!sv_isobject(notgrp) || !sv_isa(notgrp, PERLCLASS_NOTGRP)) {
		/* No notification group obj */
		return 0;
	}

	sv = SvRV(notgrp);

	if (!SvIOK(sv)) {
		/* No int */
		return 0;
	}

	*dst = SvIV(sv);

	return 1;
}

/*
 * Convert a perl SV for a fanotify_bundle (metadata plus fanotify group fd) to
 * a fanotify_bundle structure
 */
struct fanotify_bundle *
event2bundle(SV *event) {
	SV *deref;

	if (!SvROK(event)) {
		/* No RV */
		return NULL;
	}
	if (!sv_isobject(event) || !sv_isa(event, PERLCLASS_EVENT)) {
		/* No notification group obj */
		return NULL;
	}

	deref = SvRV(event);

	if (!deref) {
		return NULL;
	}

	return (struct fanotify_bundle *)SvPV_nolen(deref);

}

/*
 * Convert a notification event bundle to a string.
 * Intended for debugging purposes only.
 */
char *
event2str(const struct fanotify_bundle *bundle, char *buf, int len) {

	const struct fanotify_event_metadata *event = &(bundle->metadata);

	char *fmt = "event at %p is: event_len = %d, vers = %d, reserved = %d, meta_len = %d, mask = %lld, fd = %d, pid = %d (fanotify group fd %d)";

	if (snprintf(buf, len, fmt,
		event, event->event_len, event->vers, event->reserved, event->metadata_len, event->mask, event->fd, event->pid, bundle->fd) >= len) {
		buf[len-1] = 0;
	}

	return buf;
}

/*
 * Print an event's contents on the screen
 */
void
dumpEvent(const struct fanotify_bundle *bundle) {
	char buf[256];

	event2str(bundle, buf, sizeof(buf));
	printf("%s\n", buf);
}

int
_event_write_response(SV *event, int response) {
	struct fanotify_bundle *bundle;
	struct fanotify_response rsp;
	int fd;
	int ret;

	if (!(bundle = event2bundle(event))) {
		Perl_croak(aTHX_ "Invalid event object");
	}

	if (!bundle->needs_response) {
		Perl_croak(aTHX_ "Event already responded to or non-respondable event");
	}

	/* only ALLOW and DENY are available/sensible responses */
	if ((response != FAN_ALLOW) && (response != FAN_DENY)) {
		Perl_croak(aTHX_ "Response is neither FAN_ALLOW nor FAN_DENY; refusing to write invalid response");
	}

	fd = bundle->fd;

	rsp.fd = bundle->metadata.fd;
	rsp.response = response;

	ret = write(fd, &rsp, sizeof(struct fanotify_response));

	if (ret >= 0) {
		bundle->needs_response = 0;
	}

	return ret;
}

int
_event_close(SV *self) {
	struct fanotify_bundle *bundle;
	int ret;
	SV *sv_default_response;
	int default_response = FAN_DENY;

	if (!(bundle = event2bundle(self))) {
		Perl_croak(aTHX_ "Invalid event object");
	}

	if ((sv_default_response = get_sv("Linux::Fanotify::default_response", 0))) {
		default_response = SvIV(sv_default_response);
		if (default_response == -1) {
			default_response = FAN_DENY;
		}
	}

	if (bundle->needs_response) {
		if (default_response) {
			_event_write_response(self, default_response);
		}
	}

	if (bundle->metadata.fd > 0) {
		ret = close(bundle->metadata.fd);
		if (ret == 0) {
			bundle->metadata.fd = -1;
		}
	} else {
		errno = EBADF;
		ret = -1;
	}
	return ret;
}

/*
 *******************************************************************************
 * Main package: Linux::Fanotify
 */
MODULE = Linux::Fanotify PACKAGE = Linux::Fanotify
PROTOTYPES: ENABLE

INCLUDE: const-xs.inc

#
#
#
SV *
fanotify_init(flags, event_f_flags)
	unsigned int flags
	unsigned int event_f_flags
    INIT:
	int fd;
	SV *notgrp;
    CODE:
	fd = fanotify_init(flags, event_f_flags);

	if (fd == -1) {
		XSRETURN_UNDEF;
	}

	notgrp = newSV(0);

	sv_setref_iv(notgrp, PERLCLASS_NOTGRP, fd);

	SvREADONLY_on(SvRV(notgrp));

	RETVAL = notgrp;
    OUTPUT:
	RETVAL

#
#
#
int
fanotify_mark(notgrp, flags, mask = 0, dirfd = 0, pathname = NULL)
	SV *notgrp
	unsigned int flags
	uint64_t mask
	int dirfd
	const char *pathname
    INIT:
	int ret;
	int fd = -1;
    CODE:
	if (!notgrp2fd(notgrp, &fd)) {
		Perl_croak(aTHX_ "Invalid fanotify_fd");
	} else {
		ret = fanotify_mark(fd, flags, mask, dirfd, pathname);

		if (ret == -1) {
			XSRETURN_UNDEF;
		}
	}
	RETVAL = 1;
    OUTPUT:
	RETVAL

#
#
#
void
fanotify_read(notgrp, max = 0)
	SV *notgrp
	int max
    INIT:
	struct fanotify_event_metadata *buf;
	const struct fanotify_event_metadata *metadata;
	struct fanotify_bundle *bundle;
	ssize_t len;
	int size;
	int fd;
	SV *event;
	SV *eventref;
    PPCODE:
	/*
	 * Check arguments and allocate read buffer
	 */
	if (max < 1) {
		max = 170;	// Results in a buffer slightly smaller than 4k
	}
	if (max > 4096) {	// 4096 results in an almost 100k buffer. Don't allow more.
		Perl_croak(aTHX_ "Maximum buffer size exceeded (max = 4096)");
	}
	if (!notgrp2fd(notgrp, &fd)) {
		Perl_croak(aTHX_ "Invalid notification group object");
	}

	size = max * sizeof(struct fanotify_event_metadata);
	buf = (struct fanotify_event_metadata *)malloc(size + (sizeof(struct fanotify_bundle) - sizeof(struct fanotify_event_metadata)));

	if (!buf) {
		Perl_croak(aTHX_ "Could not allocate memory");
	}

	/*
	 * Read from fanotify queue
	 */


	len = read(fd, (void *)buf, size);

	if (len == -1) {
		/* Read error. errno is already set, we simply return an empty list and expect the user to check errno */
		free(buf);
		XSRETURN_EMPTY;
	}

	// printf("Number of event structures: %d\n",
	// 	len/sizeof(struct fanotify_event_metadata));

	metadata = buf;

	while (FAN_EVENT_OK(metadata, len)) {
		if (metadata->vers != FANOTIFY_METADATA_VERSION) {
			Perl_croak(aTHX_ "Mismatch of fanotify metadata version.");
		}

		event = newSVpvn((const char *)metadata, sizeof(struct fanotify_bundle));
		sv_2mortal(event);

		bundle = (struct fanotify_bundle *)SvPV_nolen(event);
		bundle->fd = fd;
		if (metadata->mask & (FAN_ACCESS_PERM | FAN_OPEN_PERM)) {
			bundle->needs_response = 1;
		} else {
			bundle->needs_response = 0;
		}

		eventref = newRV_noinc(event);
		sv_bless(eventref, gv_stashpv(PERLCLASS_EVENT, GV_ADD | SVf_UTF8));
		SvREADONLY_on(eventref);

		XPUSHs(eventref);

		metadata = FAN_EVENT_NEXT(metadata, len);
	}

	free(buf);

#
#
#
int
fanotify_write(event, response)
	SV *event
	int response
    INIT:
	int ret;
    CODE:
	ret = _event_write_response(event, response);

	if (ret == -1) {
		XSRETURN_UNDEF;
	}

	RETVAL = ret;

    OUTPUT:
	RETVAL

# /*
#  *******************************************************************************
#  * Main package: Linux::Fanotify::FanotifyGroup
#  */
MODULE = Linux::Fanotify PACKAGE = Linux::Fanotify::FanotifyGroup PREFIX = fanogrp_

#
#
#
int
fanogrp_getfd(self)
	SV *self
    INIT:
	int fd;
    CODE:
	if (!notgrp2fd(self, &fd)) {
		Perl_croak(aTHX_ "Invalid notification group object");
	}

	if (fd > 0) {
		RETVAL = fd;
	} else {
		XSRETURN_UNDEF;
	}
    OUTPUT:
	RETVAL

#
#
#
int
fanogrp_close(self)
	SV *self
    INIT:
	int fd;
	SV *deref;
	int ret;
    CODE:
	if (!notgrp2fd(self, &fd)) {
		Perl_croak(aTHX_ "Invalid notification group object");
	}

	if (fd > 0) {
		ret = close(fd);

		deref = SvRV(self);
		SvIV_set(deref, -1);
	} else {
		ret = -1;
		errno = EBADF;
	}

	// Convert C style 0/-1 to perl style 1/undef
	if (ret == -1) {
		XSRETURN_UNDEF;
	} else {
		ret = 1;
	}
	RETVAL = ret;
    OUTPUT:
	RETVAL

#
#
#
void
fanogrp_DESTROY(self)
	SV *self
    INIT:
	int fd;
	int autoclose = 1;
	SV *sv_autoclose;
    CODE:
	if (!notgrp2fd(self, &fd)) {
		Perl_croak(aTHX_ "Invalid notification group object");
	}

	if (fd > 0) {
		if ((sv_autoclose = get_sv("Linux::Fanotify::FanotifyGroup::autoclose", 0))) {
			autoclose = SvIV(sv_autoclose);
		}
		if (autoclose) {
			close(fd);
		}
	}

# /*
#  *******************************************************************************
#  * Main package: Linux::Fanotify::Event
#  */
MODULE = Linux::Fanotify PACKAGE = Linux::Fanotify::Event PREFIX = event_

#
#
#
int
event_close(self)
	SV *self
    INIT:
	int ret;
    CODE:
	ret = _event_close(self);

	if (ret == -1) {
		XSRETURN_UNDEF;
	} else {
		ret = 1;
	}

	RETVAL = ret;
    OUTPUT:
	RETVAL

#
#
#
void
event_DESTROY(self)
	SV *self
    INIT:
	int autoclose = 1;
	SV *sv_autoclose;
    CODE:
	if ((sv_autoclose = get_sv("Linux::Fanotify::Event::autoclose", 0))) {
		autoclose = SvIV(sv_autoclose);
	}
	if (autoclose) {
		_event_close(self);
	}

#
#
#
int
event_needsResponse(self)
	SV *self
    INIT:
	struct fanotify_bundle *bundle;
    CODE:
	if (!(bundle = event2bundle(self))) {
		Perl_croak(aTHX_ "Invalid event object");
	}

	RETVAL = bundle->needs_response;
    OUTPUT:
	RETVAL

#
#
#
int
event__write(self, response)
	SV *self
	int response
    INIT:
	int ret;
    CODE:
	ret = _event_write_response(self, response);

	if (ret == -1) {
		XSRETURN_UNDEF;
	}

	RETVAL = ret;
    OUTPUT:
	RETVAL

#
#
#
int
event_allow(self)
	SV *self
    INIT:
	int ret;
    CODE:
	ret = _event_write_response(self, FAN_ALLOW);

	if (ret == -1) {
		XSRETURN_UNDEF;
	}

	RETVAL = ret;
    OUTPUT:
	RETVAL

#
#
#
int
event_deny(self)
	SV *self
    INIT:
	int ret;
    CODE:
	ret = _event_write_response(self, FAN_DENY);

	if (ret == -1) {
		XSRETURN_UNDEF;
	}

	RETVAL = ret;
    OUTPUT:
	RETVAL

#
#
#
void
event__dump(self)
	SV *self
    INIT:
	struct fanotify_bundle *bundle;
	char buf[256];
    CODE:
	if (!(bundle = event2bundle(self))) {
		Perl_croak(aTHX_ "Invalid event object");
	}
	printf("object dump --\n%s\n",
		event2str(bundle, buf, sizeof(buf)));

#
#
#
SV *
event__stringify(self)
	SV *self
    INIT:
	struct fanotify_bundle *bundle;
	char buf[256];
	SV *s;
    CODE:
	if (!(bundle = event2bundle(self))) {
		Perl_croak(aTHX_ "Invalid event object");
	}

	event2str(bundle, buf, sizeof(buf));

	s = newSVpvn_utf8(buf, strlen(buf), 1);
	// sv_2mortal(s); // XXX XXX Needed?

	RETVAL = s;
   OUTPUT:
	RETVAL

################################################################################
# Accessor methods start here
#
unsigned int
event_event_len(self)
	SV *self
    INIT:
	struct fanotify_bundle *bundle;
    CODE:
	if (!(bundle = event2bundle(self))) {
		Perl_croak(aTHX_ "Invalid event object");
	}
	RETVAL = bundle->metadata.event_len;
    OUTPUT:
	RETVAL

#
#
#
unsigned int
event_vers(self)
	SV *self
    INIT:
	struct fanotify_bundle *bundle;
    CODE:
	if (!(bundle = event2bundle(self))) {
		Perl_croak(aTHX_ "Invalid event object");
	}
	RETVAL = bundle->metadata.vers;
    OUTPUT:
	RETVAL

#
#
#
unsigned int
event_reserved(self)
	SV *self
    INIT:
	struct fanotify_bundle *bundle;
    CODE:
	if (!(bundle = event2bundle(self))) {
		Perl_croak(aTHX_ "Invalid event object");
	}
	RETVAL = bundle->metadata.reserved;
    OUTPUT:
	RETVAL

#
#
#
unsigned int
event_metadata_len(self)
	SV *self
    INIT:
	struct fanotify_bundle *bundle;
    CODE:
	if (!(bundle = event2bundle(self))) {
		Perl_croak(aTHX_ "Invalid event object");
	}
	RETVAL = bundle->metadata.metadata_len;
    OUTPUT:
	RETVAL

#
#
#
uint64_t
event_mask(self)
	SV *self
    INIT:
	struct fanotify_bundle *bundle;
    CODE:
	if (!(bundle = event2bundle(self))) {
		Perl_croak(aTHX_ "Invalid event object");
	}
	RETVAL = bundle->metadata.mask;
    OUTPUT:
	RETVAL

#
#
#
int
event_fd(self)
	SV *self
    INIT:
	struct fanotify_bundle *bundle;
    CODE:
	if (!(bundle = event2bundle(self))) {
		Perl_croak(aTHX_ "Invalid event object");
	}
	RETVAL = bundle->metadata.fd;
    OUTPUT:
	RETVAL

#
#
#
int
event_pid(self)
	SV *self
    INIT:
	struct fanotify_bundle *bundle;
    CODE:
	if (!(bundle = event2bundle(self))) {
		Perl_croak(aTHX_ "Invalid event object");
	}
	RETVAL = bundle->metadata.pid;
    OUTPUT:
	RETVAL

