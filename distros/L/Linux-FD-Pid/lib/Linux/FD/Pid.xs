#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <signal.h>
#include <linux/wait.h>
#include <sys/syscall.h>
#include <unistd.h>

#define die_sys(format) Perl_croak(aTHX_ format, strerror(errno))

static SV* S_io_fdopen(pTHX_ int fd, const char* classname, char type) {
	PerlIO* pio = PerlIO_fdopen(fd, "r");
	GV* gv = newGVgen(classname ? classname : "Linux::FD::Pid");
	SV* ret = newRV_noinc((SV*)gv);
	IO* io = GvIOn(gv);
	IoTYPE(io) = type;
	IoIFP(io) = pio;
	IoOFP(io) = pio;
	if (classname) {
		HV* stash = gv_stashpv(classname, FALSE);
		sv_bless(ret, stash);
	}
	return ret;
}
#define io_fdopen(fd, classname, type) S_io_fdopen(aTHX_ fd, classname, type)

static char S_get_flags(pTHX_ int fd) {
	struct stat info;
	if (fstat(fd, &info) != -1) {
		if (S_ISSOCK(info.st_mode))
			return 's';
		else if (S_ISFIFO(info.st_mode))
			return '|';
	}

	int flags = fcntl(fd, F_GETFL);
	if (flags & O_APPEND)
		return 'a';
	switch (flags & 3) {
		case O_RDONLY:
			return '<';
		case O_WRONLY:
			return '>';
		case O_RDWR:
			return '+';
		default:
			close(fd);
			Perl_croak(aTHX_ "Unknown mode on descriptor");
	}
}
#define get_flags(fd) S_get_flags(aTHX_ fd)

typedef struct { const char* key; unsigned long value; } map[];

#define PIDFD_NONBLOCK O_NONBLOCK
static map pid_flags = {
	{ "non-blocking", PIDFD_NONBLOCK },
};

static UV S_get_pid_flag(pTHX_ SV* flag_name) {
	int i;
	for (i = 0; i < sizeof pid_flags / sizeof *pid_flags; ++i)
		if (strEQ(SvPV_nolen(flag_name), pid_flags[i].key))
			return pid_flags[i].value;
	Perl_croak(aTHX_ "No such flag '%s' known", SvPV_nolen(flag_name));
}
#define get_pid_flag(name) S_get_pid_flag(aTHX_ name)

#define get_fd(self) PerlIO_fileno(IoOFP(sv_2io(SvRV(self))))

MODULE = Linux::FD::Pid				PACKAGE = Linux::FD::Pid

PROTOTYPES: DISABLED

SV*
new(classname, pid, ...)
	const char* classname;
	int pid;
	PREINIT:
	int pidfd;
	int i, flags = 0;
	CODE:
	for (i = 2; i < items; i++)
		flags |= get_pid_flag(ST(i));
	pidfd = syscall(__NR_pidfd_open, pid, 0);
	if (pidfd < 0)
		die_sys("Couldn't open pidfd: %s");
	RETVAL = io_fdopen(pidfd, classname, '<');
	OUTPUT:
		RETVAL

void
send(file_handle, signal)
	SV* file_handle;
	SV* signal;
	PREINIT:
		int fd, ret;
	CODE:
		fd = get_fd(file_handle);
		int signo = (SvIOK(signal) || looks_like_number(signal)) && SvIV(signal) ? SvIV(signal) : whichsig(SvPV_nolen(signal));
		ret = syscall(__NR_pidfd_send_signal, fd, signo, NULL, 0);
		if (ret < 0)
			die_sys("Couldn't send signal: %s");

int
wait(file_handle, flags = WEXITED)
	SV* file_handle;
	int flags;
	PREINIT:
		int fd, wait_result;
		siginfo_t info;
	CODE:
		fd = get_fd(file_handle);
		wait_result = waitid(P_PIDFD, fd, &info, flags);
		if (wait_result != 0) {
			if (errno == EAGAIN)
				XSRETURN_UNDEF;
			else
				die_sys("Can't wait pid: %s");
		}
		if (info.si_signo == 0)
			XSRETURN_UNDEF;
		RETVAL = info.si_status;
	OUTPUT:
		RETVAL

SV*
get_handle(file_handle, fd)
	SV* file_handle;
	int fd;
	PREINIT:
		int pidfd, newfd;
	CODE:
		pidfd = get_fd(file_handle);
		newfd = syscall(__NR_pidfd_getfd, pidfd, fd, 0);
		if (newfd < 0)
			die_sys("Can't get file descriptor: %s");
		RETVAL = io_fdopen(newfd, NULL, get_flags(newfd));
	OUTPUT:
		RETVAL
