#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifndef WIN32
#include <sys/mman.h>
#include <unistd.h>
#endif

#ifdef __cplusplus
}
#endif

#ifdef NEED_NOT_HERE
static int
not_here(s)
char *s;
{
    croak("%s not implemented on this architecture", s);
    return -1;
}
#endif

#ifdef WIN32

#define MAP_ANON 1
#define MAP_ANONYMOUS 1
#define MAP_FILE 2
#define MAP_PRIVATE 4
#define MAP_SHARED 8
#define PROT_READ 1
#define PROT_WRITE 2

static double
constant(name, arg)
char *name;
int arg;
{
    switch (*name) {
		case 'M':
			if (strEQ(name, "MAP_ANON"))
				return MAP_ANON;
			else if (strEQ(name, "MAP_ANONYMOUS"))
				return MAP_ANONYMOUS;

			else if (strEQ(name, "MAP_FILE"))
				return MAP_FILE;
			else if (strEQ(name, "MAP_PRIVATE"))
				return MAP_PRIVATE;
			else if (strEQ(name, "MAP_SHARED"))
				return MAP_SHARED;

			break;

		case 'P':
			if (strEQ(name, "PROT_READ"))
				return PROT_READ;

			else if (strEQ(name, "PROT_WRITE"))
				return PROT_WRITE;
			break;

		default:
			break;
	}
    return 0;
}

#else

static double
constant(name, arg)
char *name;
int arg;
{
    errno = 0;
    switch (*name) {
		case 'M':
			if (strEQ(name, "MAP_ANON")) {
#ifdef MAP_ANON
				return MAP_ANON;
#else
			    errno = ENOENT;
			    return 0;
#endif
			}
			if (strEQ(name, "MAP_ANONYMOUS")) {
#ifdef MAP_ANONYMOUS
				return MAP_ANONYMOUS;
#else
			    errno = ENOENT;
			    return 0;
#endif
			}
			if (strEQ(name, "MAP_FILE")) {
#ifdef MAP_FILE
				return MAP_FILE;
#else
			    errno = ENOENT;
			    return 0;
#endif
			}
			if (strEQ(name, "MAP_PRIVATE")) {
#ifdef MAP_PRIVATE
				return MAP_PRIVATE;
#else
			    errno = ENOENT;
			    return 0;
#endif
			}
			if (strEQ(name, "MAP_SHARED")) {
#ifdef MAP_SHARED
				return MAP_SHARED;
#else
			    errno = ENOENT;
			    return 0;
#endif
			}

		case 'P':
			if (strEQ(name, "PROT_READ")) {
#ifdef PROT_READ
				return PROT_READ;
#else
			    errno = ENOENT;
			    return 0;
#endif
			}
			if (strEQ(name, "PROT_WRITE")) {
#ifdef PROT_WRITE
				return PROT_WRITE;
#else
			    errno = ENOENT;
			    return 0;
#endif
			}

		default:
			break;
	}
    errno = EINVAL;
    return 0;
}

static size_t pagesize;

#endif	/* not Win32 */

MODULE = IPC::Mmap		PACKAGE = IPC::Mmap

double
constant(name,arg)
	char *		name
	int		arg

# read len bytes starting at off from mmap's region defined
# by addr, into the Perl scalar var returns the actual length read

void
mmap_read(addr, maxlen, off, var, len)
	SV *    addr
	size_t        maxlen
	int         off
	SV *          var
	size_t        len
    PROTOTYPE: $$$$$
    PPCODE:
        UV tmp = SvUV(addr);
	    caddr_t lcladdr = INT2PTR(caddr_t, (tmp + off));

		if (len > maxlen - off)
			len = maxlen - off;
#		printf("\nmmap_read: length is %i\n", len);
		sv_setpvn(var, lcladdr, len);
		SvSETMAGIC(var);
		ST(0) = sv_2mortal(newSVnv(len));
		XSRETURN(1);

# write len bytes starting at off from mmap's region defined
# by addr, from the Perl scalar var. If no len
# specified, writes complete length of var; if length of
# var is < len, then only writes var's length; if len of
# var length exceeds the mmaped region length,
# only the allowable length will be written
# returns the number of bytes actually written

void
mmap_write(addr, maxlen, off, var, len)
	SV *  addr
	int   maxlen
	int   off
	SV * var
	int   len
    PROTOTYPE: $$$$$
    PPCODE:
        UV tmp = SvUV(addr);
	    caddr_t lcladdr = INT2PTR(caddr_t, (tmp + off));
 		STRLEN varlen;
 		char * ptr;

#		printf("\nmmap_write: addr %p maxlen %i off %i len %i\n",
#			lcladdr, maxlen, off, len);

		ptr = SvPV(var, varlen);
		if (len > (int)varlen)
			len = varlen;
		if (len > (maxlen - off))
			len = maxlen - off;
#		printf("\n lcladdr is %p offset is %d length is %d ptr is %p\n", addr, off, len, ptr);
#		printf("\ncopying memory\n");
#		dest = (char *)(lcladdr + off);
		memcpy(lcladdr, ptr, len);
#		dest[len] = (char)0;
# 		printf("\nmemory copied\n");
#		printf("\n%s\n", dest);
		ST(0) = sv_2mortal(newSVnv((int) len));
		XSRETURN(1);

#ifndef WIN32

MODULE = IPC::Mmap		PACKAGE = IPC::Mmap::POSIX

double
constant(name,arg)
	char *		name
	int		arg

void
_mmap_anon(len, prot, flags)
	size_t        len
	int           prot
	int           flags
    PROTOTYPE: $$$
    PPCODE:
		int   fd;
		void *  addr;
		int   slop;
/*		struct stat st; */

#		printf("\n_mmap: len %i prot %i flags %i\n", len, prot, flags);
 		EXTEND(SP, 3);
		fd = -1;
		if (!len)  {
			croak("mmap: MAP_ANON specified, but no length specified. cannot infer length from file");
			PUSHs(&PL_sv_undef);
			PUSHs(&PL_sv_undef);
			PUSHs(&PL_sv_undef);
			XSRETURN(3);
		}

		if (pagesize == 0) {
			pagesize = getpagesize();
		}

#		slop = off % pagesize;
		slop = 0;

#		addr = mmap(0, len + slop, prot, flags, fd, off - slop);
		addr = mmap(0, len + slop, prot, flags, fd, 0);

#		printf("\n_mmap: fileno %i slop %i addr %u\n", fd, slop, addr);

		if (addr == NULL) {
			croak("mmap: mmap call failed: errno: %d errmsg: %s ", errno, strerror(errno));
		 	PUSHs(&PL_sv_undef);
		 	PUSHs(&PL_sv_undef);
		 	PUSHs(&PL_sv_undef);
			XSRETURN(3);
		}
#
# return the address, the length (incl slop),
# and the offset (adjusted to nearest page)
#
	 	PUSHs(sv_2mortal(newSVuv(PTR2UV(addr))));
	 	PUSHs(sv_2mortal(newSVnv((int) len + slop)));
	 	PUSHs(sv_2mortal(newSVnv((int) slop)));
		XSRETURN(3);

void
_mmap(len, prot, flags, fh)
	size_t        len
	int           prot
	int           flags
	FILE *        fh
    PROTOTYPE: $$$*
    PPCODE:
		int   fd;
		void *  addr;
		int   slop;
		struct stat st;

#		printf("\n_mmap: len %i prot %i flags %i\n", len, prot, flags);
 		EXTEND(SP, 3);
		if (flags&MAP_ANON) {
			fd = -1;
			if (!len)  {
				croak("mmap: MAP_ANON specified, but no length specified. cannot infer length from file");
			 	PUSHs(&PL_sv_undef);
			 	PUSHs(&PL_sv_undef);
			 	PUSHs(&PL_sv_undef);
				XSRETURN(3);
			}
		}
		else {
			fd = fileno(fh);
			if (fd < 0) {
				croak("mmap: file not open or does not have associated fileno");
			 	PUSHs(&PL_sv_undef);
			 	PUSHs(&PL_sv_undef);
			 	PUSHs(&PL_sv_undef);
				XSRETURN(3);
			}
			if (fstat(fd, &st) == -1) {
				croak("mmap: no len provided, fstat failed, unable to infer length");
			 	PUSHs(&PL_sv_undef);
			 	PUSHs(&PL_sv_undef);
			 	PUSHs(&PL_sv_undef);
				XSRETURN(3);
			}
			if (!len) {
				len = st.st_size;
			}
			else if (len > st.st_size) {
				croak("_mmap: file size %i too small for specified length %i", st.st_size, len);
			 	PUSHs(&PL_sv_undef);
			 	PUSHs(&PL_sv_undef);
			 	PUSHs(&PL_sv_undef);
				XSRETURN(3);
			}
#			printf("\n_mmap: fileno %i len %i\n", fd, len);
		}

		if (pagesize == 0) {
			pagesize = getpagesize();
		}

#		slop = off % pagesize;
		slop = 0;

#		addr = mmap(0, len + slop, prot, flags, fd, off - slop);
		addr = mmap(0, len + slop, prot, flags, fd, 0);

#		printf("\n_mmap: fileno %i slop %i addr %u\n", fd, slop, addr);

		if (addr == NULL) {
			croak("mmap: mmap call failed: errno: %d errmsg: %s ", errno, strerror(errno));
		 	PUSHs(&PL_sv_undef);
		 	PUSHs(&PL_sv_undef);
		 	PUSHs(&PL_sv_undef);
			XSRETURN(3);
		}
#
# return the address, the length (incl slop),
# and the offset (adjusted to nearest page)
#
	 	PUSHs(sv_2mortal(newSVuv(PTR2UV(addr))));
	 	PUSHs(sv_2mortal(newSVnv((int) len + slop)));
	 	PUSHs(sv_2mortal(newSVnv((int) slop)));
		XSRETURN(3);

void
_munmap(addr, len)
	void *    addr
	size_t    len
    PROTOTYPE: $$
    PPCODE:
#
# XXX refrain from dumping core if this
# var wasnt previously mmap'd
#
#		printf("_munmap: addr %p len %i\n", addr, len);
		if (munmap(addr, len) == -1) {
#			printf("_munmap failed! errno %d\n", errno);
			croak("munmap failed! errno %d %s\n", errno, strerror(errno));
			ST(0) = &PL_sv_undef;
		}
		else
			ST(0)  = &PL_sv_yes;
#		printf("leaving _munmap\n");
		XSRETURN(1);

#endif
