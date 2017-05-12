#ifndef _GNU_SOURCE
#	define _GNU_SOURCE
#endif
#define GNU_STRERROR_R

#include <string.h>

#include <sys/eventfd.h>
#include <sys/signalfd.h>
#include <sys/timerfd.h>

#define PERL_NO_GET_CONTEXT
#define PERL_REENTR_API 1
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#define get_fd(self) PerlIO_fileno(IoOFP(sv_2io(SvRV(self))));

#define die_sys(format) Perl_croak(aTHX_ format, strerror(errno))

static sigset_t* S_sv_to_sigset(pTHX_ SV* sigmask, const char* name) {
	IV tmp;
	if (!SvOK(sigmask))
		return NULL;
	if (!SvROK(sigmask) || !sv_derived_from(sigmask, "POSIX::SigSet"))
		Perl_croak(aTHX_ "%s is not of type POSIX::SigSet");
#if PERL_VERSION > 15 || PERL_VERSION == 15 && PERL_SUBVERSION > 2
	return (sigset_t *) SvPV_nolen(SvRV(sigmask));
#else
	tmp = SvIV((SV*)SvRV(sigmask));
	return INT2PTR(sigset_t*, tmp);
#endif
}
#define sv_to_sigset(sigmask, name) S_sv_to_sigset(aTHX_ sigmask, name)

static sigset_t* S_get_sigset(pTHX_ SV* signal, const char* name) {
	if (SvROK(signal))
		return sv_to_sigset(signal, name);
	else {
		int signo = (SvIOK(signal) || looks_like_number(signal)) && SvIV(signal) ? SvIV(signal) : whichsig(SvPV_nolen(signal));
		SV* buffer = sv_2mortal(newSVpvn("", 0));
		SvGROW(buffer, sizeof(sigset_t));
		sigset_t* ret = (sigset_t*)SvPV_nolen(buffer);
		sigemptyset(ret);
		sigaddset(ret, signo);
		return ret;
	}
}
#define get_sigset(sigmask, name) S_get_sigset(aTHX_ sigmask, name)

#define NANO_SECONDS 1000000000

static NV timespec_to_nv(struct timespec* time) {
	return time->tv_sec + time->tv_nsec / (double)NANO_SECONDS;
}

static void nv_to_timespec(NV input, struct timespec* output) {
	output->tv_sec  = (time_t) floor(input);
	output->tv_nsec = (long) ((input - output->tv_sec) * NANO_SECONDS);
}

typedef struct { const char* key; clockid_t value; } map[];

static map clocks = {
	{ "monotonic", CLOCK_MONOTONIC },
	{ "realtime" , CLOCK_REALTIME  },
};

static clockid_t S_get_clockid(pTHX_ const char* clock_name) {
	int i;
	for (i = 0; i < sizeof clocks / sizeof *clocks; ++i) {
		if (strEQ(clock_name, clocks[i].key))
			return clocks[i].value;
	}
	Perl_croak(aTHX_ "No such timer '%s' known", clock_name);
}
#define get_clockid(name) S_get_clockid(aTHX_ name)

static clockid_t S_get_clock(pTHX_ SV* ref, const char* funcname) {
	SV* value;
	if (!SvROK(ref) || !(value = SvRV(ref)))
		Perl_croak(aTHX_ "Could not %s: this variable is not a clock", funcname);
	return SvIV(value);
}
#define get_clock(ref, func) S_get_clock(aTHX_ ref, func)

static SV* S_io_fdopen(pTHX_ int fd, const char* classname) {
	PerlIO* pio = PerlIO_fdopen(fd, "r");
	GV* gv = newGVgen(classname);
	SV* ret = newRV_noinc((SV*)gv);
	IO* io = GvIOn(gv);
	HV* stash = gv_stashpv(classname, FALSE);
	IoTYPE(io) = '<';
	IoIFP(io) = pio;
	IoOFP(io) = pio;
	sv_bless(ret, stash);
	return ret;
}
#define io_fdopen(fd, classname) S_io_fdopen(aTHX_ fd, classname)

#ifndef EFD_CLOEXEC
#define EFD_CLOEXEC 0
#endif

#ifndef SFD_CLOEXEC
#define SFD_CLOEXEC 0
#endif

#ifndef TFD_CLOEXEC
#define TFD_CLOEXEC 0
#endif

#define SET_HASH_IMPL(key,value) hv_store(hash, key, sizeof key - 1, value, 0)
#define SET_HASH_U(key) SET_HASH_IMPL(#key, newSVuv(buffer.ssi_##key))
#define SET_HASH_I(key) SET_HASH_IMPL(#key, newSViv(buffer.ssi_##key))

static map flags = {
#ifdef EFD_NONBLOCK
	{ "non-blocking", EFD_NONBLOCK },
#endif
#ifdef EFD_SEMAPHORE
	{ "semaphore", EFD_SEMAPHORE },
#endif
};

static UV S_get_event_flag(pTHX_ SV* flag_name) {
	int i;
	for (i = 0; i < sizeof flags / sizeof *flags; ++i)
		if (strEQ(SvPV_nolen(flag_name), flags[i].key))
			return flags[i].value;
	Perl_croak(aTHX_ "No such flag '%s' known", flag_name);
}
#define get_event_flag(name) S_get_event_flag(aTHX_ name)

static SV* S_new_eventfd(pTHX_ const char* classname, UV initial, int flags) {
	int fd = eventfd(initial, flags);
	if (fd < 0)
		die_sys("Can't open eventfd descriptor: %s");
	return io_fdopen(fd, classname);
}
#define new_eventfd(classname, initial, flags) S_new_eventfd(aTHX_ classname, initial, flags)

static SV* S_new_signalfd(pTHX_ const char* classname, SV* sigmask) {
	int fd = signalfd(-1, get_sigset(sigmask, "signalfd"), SFD_CLOEXEC);
	if (fd < 0)
		die_sys("Can't open signalfd descriptor: %s");
	return io_fdopen(fd, classname);
}
#define new_signalfd(classname, sigset) S_new_signalfd(aTHX_ classname, sigset)

static SV* S_new_timerfd(pTHX_ const char* classname, SV* clock, const char* funcname) {
	clockid_t clock_id = SvROK(clock) ? get_clock(clock, funcname) : get_clockid(SvPV_nolen(clock));
	int fd = timerfd_create(clock_id, TFD_CLOEXEC);
	if (fd < 0)
		die_sys("Can't open timerfd descriptor: %s");
	return io_fdopen(fd, classname);
}
#define new_timerfd(classname, clock, func) S_new_timerfd(aTHX_ classname, clock, func)

static int S_interrupted(pTHX_ int value) {
	if (value == -1 && errno == EINTR) {
		PERL_ASYNC_CHECK();
		return 1;
	}
	return 0;
}
#define interrupted(value) S_interrupted(aTHX_ value)

MODULE = Linux::FD				PACKAGE = Linux::FD

BOOT:
	load_module(PERL_LOADMOD_NOIMPORT, newSVpvs("IO::Handle"), NULL);
	av_push(get_av("Linux::FD::Event::ISA" , GV_ADD), newSVpvs("IO::Handle"));
	av_push(get_av("Linux::FD::Signal::ISA", GV_ADD), newSVpvs("IO::Handle"));
	av_push(get_av("Linux::FD::Timer::ISA" , GV_ADD), newSVpvs("IO::Handle"));

SV*
eventfd(initial = 0, ...)
	UV initial;
	PREINIT:
		int i, flags = EFD_CLOEXEC;
	CODE:
	for (i = 1; i < items; i++)
		flags |= get_event_flag(ST(i));
	RETVAL = new_eventfd("Linux::FD::Event", initial, flags);
	OUTPUT:
		RETVAL

SV*
signalfd(sigmask)
	SV* sigmask;
	CODE:
	RETVAL = new_signalfd("Linux::FD::Signal", sigmask);
	OUTPUT:
	RETVAL

SV*
timerfd(clock)
	SV* clock;
	CODE:
	RETVAL = new_timerfd("Linux::FD::Timer", clock, "timerfd");
	OUTPUT:
	RETVAL

MODULE = Linux::FD				PACKAGE = Linux::FD::Event

SV*
new(classname, initial = 0, ...)
	const char* classname;
	UV initial;
	PREINIT:
		int i, flags = EFD_CLOEXEC;
	CODE:
		for (i = 2; i < items; i++)
			flags |= get_event_flag(ST(i));
		RETVAL = new_eventfd(classname, initial, flags);
	OUTPUT:
		RETVAL

UV
get(self)
	SV* self;
	PREINIT:
		uint64_t buffer;
		int ret, events;
	CODE:
		events = get_fd(self);
		do {
			ret = read(events, &buffer, sizeof buffer);
		} while (interrupted(ret));
		if (ret == -1) {
			if (errno == EAGAIN)
				XSRETURN_EMPTY;
			else
				die_sys("Couldn't read from eventfd: %s");
		}
		RETVAL = buffer;
	OUTPUT:
		RETVAL

UV
add(self, value)
	SV* self;
	UV value;
	PREINIT:
		uint64_t buffer;
		int ret, events;
	CODE:
		events = get_fd(self);
		buffer = value;
		do {
			ret = write(events, &buffer, sizeof buffer);
		} while (interrupted(ret));
		if (ret == -1) {
			if (errno == EAGAIN)
				XSRETURN_EMPTY;
			else
				die_sys("Couldn't write to eventfd: %s");
		}
		RETVAL = value;
	OUTPUT:
		RETVAL


MODULE = Linux::FD				PACKAGE = Linux::FD::Signal

SV*
new(classname, sigmask)
	const char* classname;
	SV* sigmask;
	PREINIT:
	CODE:
		RETVAL = new_signalfd(classname, sigmask);
	OUTPUT:
		RETVAL

void set_mask(self, sigmask)
	SV* self;
	SV* sigmask;
	PREINIT:
	int fd;
	CODE:
	fd = get_fd(self);
	if(signalfd(fd, sv_to_sigset(sigmask, "signalfd"), 0) == -1)
		die_sys("Couldn't set_mask: %s");

SV*
receive(self)
	SV* self;
	PREINIT:
		struct signalfd_siginfo buffer;
		int tmp, timer;
		HV* hash;
	CODE:
		timer = get_fd(self);
		do {
			tmp = read(timer, &buffer, sizeof buffer);
		} while (interrupted(tmp));
		if (tmp == -1) {
			if (errno == EAGAIN)
				XSRETURN_EMPTY;
			else
				die_sys("Couldn't read from signalfd: %s");
		}
		hash = newHV();
		SET_HASH_U(signo);
		SET_HASH_I(errno);
		SET_HASH_I(code);
		SET_HASH_U(pid);
		SET_HASH_U(uid);
		SET_HASH_I(fd);
		SET_HASH_U(tid);
		SET_HASH_U(band);
		SET_HASH_U(overrun);
		SET_HASH_U(trapno);
		SET_HASH_I(status);
		SET_HASH_I(int);
		SET_HASH_U(ptr);
		SET_HASH_U(utime);
		SET_HASH_U(stime);
		SET_HASH_U(addr);
		RETVAL = newRV_noinc((SV*)hash);
	OUTPUT:
		RETVAL


MODULE = Linux::FD				PACKAGE = Linux::FD::Timer

SV*
new(classname, clock)
	const char* classname;
	SV* clock;
	CODE:
		RETVAL = new_timerfd(classname, clock, "Linux::FD::Timer->new");
	OUTPUT:
		RETVAL

void
get_timeout(self)
	SV* self;
	PREINIT:
		int timer;
		struct itimerspec value;
	PPCODE:
		timer = get_fd(self);
		if (timerfd_gettime(timer, &value) == -1)
			die_sys("Couldn't get_timeout: %s");
		mXPUSHn(timespec_to_nv(&value.it_value));
		if (GIMME_V == G_ARRAY)
			mXPUSHn(timespec_to_nv(&value.it_interval));

SV*
set_timeout(self, new_value, new_interval = 0, abstime = 0)
	SV* self;
	NV new_value;
	NV new_interval;
	IV abstime;
	PREINIT:
		int timer;
		struct itimerspec new_itimer, old_itimer;
	PPCODE:
		timer = get_fd(self);
		nv_to_timespec(new_value, &new_itimer.it_value);
		nv_to_timespec(new_interval, &new_itimer.it_interval);
		if (timerfd_settime(timer, (abstime ? TIMER_ABSTIME : 0), &new_itimer, &old_itimer) == -1)
			die_sys("Couldn't set_timeout: %s");
		mXPUSHn(timespec_to_nv(&old_itimer.it_value));
		if (GIMME_V == G_ARRAY)
			mXPUSHn(timespec_to_nv(&old_itimer.it_interval));

IV
receive(self)
	SV* self;
	PREINIT:
		uint64_t buffer;
		int ret, timer;
	CODE:
		timer = get_fd(self);
		do {
			ret = read(timer, &buffer, sizeof buffer);
		} while (interrupted(ret));
		if (ret == -1) {
			if (errno == EAGAIN)
				XSRETURN_EMPTY;
			else
				die_sys("Couldn't read from timerfd: %s");
		}
		RETVAL = buffer;
	OUTPUT:
		RETVAL

