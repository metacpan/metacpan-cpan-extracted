#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <sys/mman.h>
#include <sys/syscall.h>
#include <linux/memfd.h>

#define die_sys(format) Perl_croak(aTHX_ format, strerror(errno))

static SV* S_io_fdopen(pTHX_ int fd, const char* classname, char type) {
	PerlIO* pio = PerlIO_fdopen(fd, "r");
	GV* gv = newGVgen(classname ? classname : "Linux::FD::Mem");
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

typedef struct { const char* key; size_t length; int value; } map[];

static const map mem_flags = {
	{ STR_WITH_LEN("allow-sealing"), MFD_ALLOW_SEALING },
#ifdef MFD_HUGETLB
	{ STR_WITH_LEN("huge-table"), MFD_HUGETLB },
	{ STR_WITH_LEN("huge-2mb"), MFD_HUGE_2MB },
	{ STR_WITH_LEN("huge-1gb"), MFD_HUGE_1GB },
#endif
};

static UV S_get_mem_flag(pTHX_ SV* flag_name) {
	int i;
	for (i = 0; i < sizeof mem_flags / sizeof *mem_flags; ++i)
		if (strEQ(SvPV_nolen(flag_name), mem_flags[i].key))
			return mem_flags[i].value;
	Perl_croak(aTHX_ "No such flag '%s' known", SvPV_nolen(flag_name));
}
#define get_mem_flag(name) S_get_mem_flag(aTHX_ name)

static const map seal_flags = {
	{ STR_WITH_LEN("seal"), F_SEAL_SEAL },
	{ STR_WITH_LEN("shrink"), F_SEAL_SHRINK },
	{ STR_WITH_LEN("grow"), F_SEAL_GROW },
	{ STR_WITH_LEN("write"), F_SEAL_WRITE },
#ifdef F_SEAL_FUTURE_WRITE
	{ STR_WITH_LEN("future-write"), F_SEAL_FUTURE_WRITE },
#endif
};

static UV S_get_seal_flag(pTHX_ SV* flag_name) {
	int i;
	for (i = 0; i < sizeof seal_flags / sizeof *seal_flags; ++i)
		if (strEQ(SvPV_nolen(flag_name), seal_flags[i].key))
			return seal_flags[i].value;
	Perl_croak(aTHX_ "No such seal '%s' known", SvPV_nolen(flag_name));
}
#define get_seal_flag(name) S_get_seal_flag(aTHX_ name)

#define get_fd(self) PerlIO_fileno(IoOFP(sv_2io(SvRV(self))))

MODULE = Linux::FD::Mem				PACKAGE = Linux::FD::Mem

SV*
new(classname, name, ...)
	const char* classname;
	const char* name;
	PREINIT:
	int memfd;
	int i, flags = MFD_CLOEXEC;
	CODE:
	for (i = 2; i < items; i++)
		flags |= get_mem_flag(ST(i));
	memfd = syscall(__NR_memfd_create, name, flags);
	if (memfd < 0)
		die_sys("Couldn't open memfd: %s");
	RETVAL = io_fdopen(memfd, classname, '+');
	OUTPUT:
		RETVAL

void
seal(file_handle, ...)
	SV* file_handle;
	PREINIT:
		int fd, seals = 0, i, ret;
	CODE:
	fd = get_fd(file_handle);
	for (i = 1; i < items; i++)
		seals |= get_seal_flag(ST(i));
	ret = fcntl(fd, F_ADD_SEALS, seals);
	if (ret < 0)
		die_sys("Couldn't add seal: %s");

void
get_seals(file_handle)
	SV* file_handle;
	PREINIT:
	int seals, fd, i;
	PPCODE:
	fd = get_fd(file_handle);
	seals = fcntl(fd, F_GET_SEALS, 0);
	for (i = 0; i < sizeof seal_flags / sizeof *seal_flags; ++i) {
		if (seal_flags[i].value & seals)
			mXPUSHp(seal_flags[i].key, seal_flags[i].length);
	}
