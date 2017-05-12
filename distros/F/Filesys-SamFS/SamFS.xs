/*
 * If you get compilation errors and your SamFS version is somewhat
 * dated, you could try to uncomment the definition of OLS_SAMFS. The
 * author does not have access to SamFS anymore, let alone older
 * versions, so he can't check when OLD_SAMFS should be set. He would
 * definitely appreciate a mail describing the problems you encountered.
 */

/*
#define OLD_SAMFS
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* Avoid clash with library. */
extern char *dev_state[];
#define DEV_NM_HERE
#include <devstat.h>

#include <stat.h>
#include <rminfo.h>
#include <version.h>
#include <lib.h>
#include <catalog.h>

/* Not declared in early SamFS header files. */
char *sam_devstr(uint_t status);

#include "const-c.inc"

char buff[21];

char *
ull2s(u_longlong_t value)
{
	sprintf(buff, "%llu", value);
	return buff;
}

void
sam_stat2av(struct sam_stat *info, AV *av)
{
        int i;
        AV *copies;

	av_store(av,  0, newSViv(info->st_dev));
	av_store(av,  1, newSViv(info->st_ino));
	av_store(av,  2, newSViv(info->st_mode));
	av_store(av,  3, newSViv(info->st_nlink));
	av_store(av,  4, newSViv(info->st_uid));
	av_store(av,  5, newSViv(info->st_gid));
	av_store(av,  6, newSViv(info->rdev));
	av_store(av,  7, newSVpv(ull2s(info->st_size), 0));
	av_store(av,  8, newSViv(info->st_atime));
	av_store(av,  9, newSViv(info->st_mtime));
	av_store(av, 10, newSViv(info->st_ctime));
	av_store(av, 11, newSViv(512));		/* blksize */
	av_store(av, 12, newSVpv(ull2s(info->st_blocks), 0));
	av_store(av, 13, newSViv(info->attr));
	av_store(av, 14, newSViv(info->attribute_time));
	av_store(av, 15, newSViv(info->creation_time));
	av_store(av, 16, newSViv(info->residence_time));
	av_store(av, 17, newSViv(info->cs_algo));
	av_store(av, 18, newSViv(info->flags));
	av_store(av, 19, newSViv(info->gen));
	av_store(av, 20, newSViv(info->partial_size));
        copies = newAV();
        av_extend(av, MAX_ARCHIVE);
	av_store(av, 21, newRV_noinc((SV*)copies));
	for (i=0; i<MAX_ARCHIVE; i++) {
                AV *av = newAV();
                av_store(copies, i, newRV_noinc((SV*)av));
                av_extend(av, 7);
		av_store(av, 0, newSViv(info->copy[i].flags));
	        av_store(av, 1, newSViv(info->copy[i].n_vsns));
		av_store(av, 2, newSViv(info->copy[i].creation_time));
	        av_store(av, 3, newSVpv(ull2s(info->copy[i].position), 0));
                av_store(av, 4, newSViv(info->copy[i].offset));
		av_store(av, 5, newSVpv(info->copy[i].media, 0));
	        av_store(av, 6, newSVpv(info->copy[i].vsn, 0));
        }
	av_store(av, 22, newSViv(info->stripe_width));
	av_store(av, 23, newSViv(info->stripe_group));
	av_store(av, 24, newSViv(info->segment_size));
	av_store(av, 25, newSViv(info->segment_number));
	av_store(av, 26, newSViv(info->stage_ahead));
	av_store(av, 27, newSViv(info->admin_id));
	av_store(av, 28, newSViv(info->allocahead));
}

MODULE = Filesys::SamFS		PACKAGE = Filesys::SamFS		PREFIX = sam_

PROTOTYPES: DISABLE

INCLUDE: const-xs.inc

char *
sam_FIXV()
CODE:
	RETVAL = SAM_FIXV;
OUTPUT:
	RETVAL

char *
sam_MAJORV()
CODE:
	RETVAL = SAM_MAJORV;
OUTPUT:
	RETVAL

char *
sam_MINORV()
CODE:
	RETVAL = SAM_MINORV;
OUTPUT:
	RETVAL

char *
sam_NAME()
CODE:
	RETVAL = SAM_NAME;
OUTPUT:
	RETVAL

char *
sam_SAM_VERSION()
CODE:
	RETVAL = SAM_VERSION;
OUTPUT:
	RETVAL

#ifdef SAM_BUILD_INFO

char *
sam_BUILD_INFO()
CODE:
        RETVAL = SAM_BUILD_INFO;
OUTPUT:
        RETVAL

#endif

#ifdef SAM_BUILD_UNAME
char *
sam_BUILD_UNAME()
CODE:
        RETVAL = SAM_BUILD_UNAME;
OUTPUT:
        RETVAL

#endif

#ifdef S_ISBLK

int
sam_S_ISBLK(mode)
	int	mode
CODE:
	RETVAL = S_ISBLK(mode);
OUTPUT:
	RETVAL

#endif

#ifdef S_ISCHR

int
sam_S_ISCHR(mode)
	int	mode
CODE:
	RETVAL = S_ISCHR(mode);
OUTPUT:
	RETVAL

#endif

#ifdef S_ISDIR

int
sam_S_ISDIR(mode)
	int	mode
CODE:
	RETVAL = S_ISDIR(mode);
OUTPUT:
	RETVAL

#endif

#ifdef S_ISFIFO

int
sam_S_ISFIFO(mode)
	int	mode
CODE:
	RETVAL = S_ISFIFO(mode);
OUTPUT:
	RETVAL

#endif

#ifdef S_ISGID

int
sam_S_ISGID(mode)
	int	mode
CODE:
	RETVAL = S_ISGID(mode);
OUTPUT:
	RETVAL

#endif

#ifdef S_ISREG

int
sam_S_ISREG(mode)
	int	mode
CODE:
	RETVAL = S_ISREG(mode);
OUTPUT:
	RETVAL

#endif

#ifdef S_ISUID

int
sam_S_ISUID(mode)
	int	mode
CODE:
	RETVAL = S_ISUID(mode);
OUTPUT:
	RETVAL

#endif

#ifdef S_ISLNK

int
sam_S_ISLNK(mode)
	int	mode
CODE:
	RETVAL = S_ISLNK(mode);
OUTPUT:
	RETVAL

#endif

#ifdef S_ISSOCK

int
sam_S_ISSOCK(mode)
	int	mode
CODE:
	RETVAL = S_ISSOCK(mode);
OUTPUT:
	RETVAL

#endif

#ifdef SS_ISSAMFS

int
sam_SS_ISSAMFS(attr)
	int	attr
CODE:
	RETVAL = SS_ISSAMFS(attr);
OUTPUT:
	RETVAL

#endif

#ifdef SS_ISREMEDIA

int
sam_SS_ISREMEDIA(attr)
	int	attr
CODE:
	RETVAL = SS_ISREMEDIA(attr);
OUTPUT:
	RETVAL

#endif

#ifdef SS_ISARCHIVED

int
sam_SS_ISARCHIVED(attr)
	int	attr
CODE:
	RETVAL = SS_ISARCHIVED(attr);
OUTPUT:
	RETVAL

#endif

#ifdef SS_ISARCHDONE

int
sam_SS_ISARCHDONE(attr)
	int	attr
CODE:
	RETVAL = SS_ISARCHDONE(attr);
OUTPUT:
	RETVAL

#endif

#ifdef SS_ISDAMAGED

int
sam_SS_ISDAMAGED(attr)
	int	attr
CODE:
	RETVAL = SS_ISDAMAGED(attr);
OUTPUT:
	RETVAL

#endif

#ifdef SS_ISOFFLINE

int
sam_SS_ISOFFLINE(attr)
	int	attr
CODE:
	RETVAL = SS_ISOFFLINE(attr);
OUTPUT:
	RETVAL

#endif

#ifdef SS_ISPARTIAL

int
sam_SS_ISPARTIAL(attr)
	int	attr
CODE:
	RETVAL = SS_ISPARTIAL(attr);
OUTPUT:
	RETVAL

#endif

#ifdef SS_ISARCHIVE_C

int
sam_SS_ISARCHIVE_C(attr)
	int	attr
CODE:
	RETVAL = SS_ISARCHIVE_C(attr);
OUTPUT:
	RETVAL

#endif

#ifdef SS_ISARCHIVE_I

int
sam_SS_ISARCHIVE_I(attr)
	int	attr
CODE:
	RETVAL = SS_ISARCHIVE_I(attr);
OUTPUT:
	RETVAL

#endif

#ifdef SS_ISARCHIVE_N

int
sam_SS_ISARCHIVE_N(attr)
	int	attr
CODE:
	RETVAL = SS_ISARCHIVE_N(attr);
OUTPUT:
	RETVAL

#endif

#ifdef SS_ISARCHIVE_A

int
sam_SS_ISARCHIVE_A(attr)
	int	attr
CODE:
	RETVAL = SS_ISARCHIVE_A(attr);
OUTPUT:
	RETVAL

#endif

#ifdef SS_ISARCHIVE_R

int
sam_SS_ISARCHIVE_R(attr)
	int	attr
CODE:
	RETVAL = SS_ISARCHIVE_R(attr);
OUTPUT:
	RETVAL

#endif

#ifdef SS_ISRELEASE_A

int
sam_SS_ISRELEASE_A(attr)
	int	attr
CODE:
	RETVAL = SS_ISRELEASE_A(attr);
OUTPUT:
	RETVAL

#endif

#ifdef SS_ISRELEASE_N

int
sam_SS_ISRELEASE_N(attr)
	int	attr
CODE:
	RETVAL = SS_ISRELEASE_N(attr);
OUTPUT:
	RETVAL

#endif

#ifdef SS_ISRELEASE_P

int
sam_SS_ISRELEASE_P(attr)
	int	attr
CODE:
	RETVAL = SS_ISRELEASE_P(attr);
OUTPUT:
	RETVAL

#endif

#ifdef SS_ISSTAGE_A

int
sam_SS_ISSTAGE_A(attr)
	int	attr
CODE:
	RETVAL = SS_ISSTAGE_A(attr);
OUTPUT:
	RETVAL

#endif

#ifdef SS_ISSTAGE_N

int
sam_SS_ISSTAGE_N(attr)
	int	attr
CODE:
	RETVAL = SS_ISSTAGE_N(attr);
OUTPUT:
	RETVAL

#endif

#ifdef SS_ISSEGMENT_A

int
sam_SS_ISSEGMENT_A(attr)
	int	attr
CODE:
	RETVAL = SS_ISSEGMENT_A(attr);
OUTPUT:
	RETVAL

#endif

#ifdef SS_ISSEGMENT_S

int
sam_SS_ISSEGMENT_S(attr)
	int	attr
CODE:
	RETVAL = SS_ISSEGMENT_S(attr);
OUTPUT:
	RETVAL

#endif

#ifdef SS_ISSEGMENT_F

int
sam_SS_ISSEGMENT_F(attr)
	int	attr
CODE:
	RETVAL = SS_ISSEGMENT_F(attr);
OUTPUT:
	RETVAL

#endif

#ifdef SS_ISCSGEN

int
sam_SS_ISCSGEN(attr)
	int	attr
CODE:
	RETVAL = SS_ISCSGEN(attr);
OUTPUT:
	RETVAL

#endif

#ifdef SS_ISCSUSE

int
sam_SS_ISCSUSE(attr)
	int	attr
CODE:
	RETVAL = SS_ISCSUSE(attr);
OUTPUT:
	RETVAL

#endif

#ifdef SS_ISCSVAL

int
sam_SS_ISCSVAL(attr)
	int	attr
CODE:
	RETVAL = SS_ISCSVAL(attr);
OUTPUT:
	RETVAL

#endif

#ifdef SS_ISDIRECTIO

int
sam_SS_ISDIRECTIO(attr)
	int	attr
CODE:
	RETVAL = SS_ISDIRECTIO(attr);
OUTPUT:
	RETVAL

#endif

# Only SS_ISSTAGE_M is defined in stat.h, but SS_STAGE_M is missing.
# SamFS 4.6

#ifdef notdef

#ifdef SS_ISSTAGE_M

int
sam_SS_ISSTAGE_M(attr)
	int	attr
CODE:
	RETVAL = SS_ISSTAGE_M(attr);
OUTPUT:
	RETVAL

#endif

#endif

#ifdef SS_ISWORM

int
sam_SS_ISWORM(attr)
	int	attr
CODE:
	RETVAL = SS_ISWORM(attr);
OUTPUT:
	RETVAL

#endif

#ifdef SS_ISREADONLY

int
sam_SS_ISREADONLY(attr)
	int	attr
CODE:
	RETVAL = SS_ISREADONLY(attr);
OUTPUT:
	RETVAL

#endif

#ifdef SS_ISSETFA_G

int
sam_SS_ISSETFA_G(attr)
	int	attr
CODE:
	RETVAL = SS_ISSETFA_G(attr);
OUTPUT:
	RETVAL

#endif

#ifdef SS_ISSETFA_S

int
sam_SS_ISSETFA_S(attr)
	int	attr
CODE:
	RETVAL = SS_ISSETFA_S(attr);
OUTPUT:
	RETVAL

#endif

#ifdef SS_ISDFACL

int
sam_SS_ISDFACL(attr)
	int	attr
CODE:
	RETVAL = SS_ISDFACL(attr);
OUTPUT:
	RETVAL

#endif

#ifdef SS_ISACL

int
sam_SS_ISACL(attr)
	int	attr
CODE:
	RETVAL = SS_ISACL(attr);
OUTPUT:
	RETVAL

#endif

#ifdef SS_ISDATAV

int
sam_SS_ISDATAV(attr)
	int	attr
CODE:
	RETVAL = SS_ISDATAV(attr);
OUTPUT:
	RETVAL

#endif

#ifdef SS_ISAIO

int
sam_SS_ISAIO(attr)
	int	attr
CODE:
	RETVAL = SS_ISAIO(attr);
OUTPUT:
	RETVAL

#endif

#ifdef SS_ISSTAGING

int
sam_SS_ISSTAGING(flags)
	int	flags
CODE:
	RETVAL = SS_ISSTAGING(flags);
OUTPUT:
	RETVAL

#endif

#ifdef SS_ISSTAGEFAIL

int
sam_SS_ISSTAGEFAIL(flags)
	int	flags
CODE:
	RETVAL = SS_ISSTAGEFAIL(flags);
OUTPUT:
	RETVAL

#endif

int
sam_CS_NEEDS_AUDIT(status)
	int status;
CODE:
	RETVAL = (status & CSP_NEEDS_AUDIT) != 0;
OUTPUT:
	RETVAL

int
sam_CS_INUSE(status)
	int status;
CODE:
	RETVAL = (status & CSP_INUSE) != 0;
OUTPUT:
	RETVAL

int
sam_CS_LABELED(status)
	int status;
CODE:
	RETVAL = (status & CSP_LABELED) != 0;
OUTPUT:
	RETVAL

int
sam_CS_BADMEDIA(status)
	int status;
CODE:
	RETVAL = (status & CSP_BAD_MEDIA) != 0;
OUTPUT:
	RETVAL

int
sam_CS_OCCUPIED(status)
	int status;
CODE:
	RETVAL = (status & CSP_OCCUPIED) != 0;
OUTPUT:
	RETVAL

int
sam_CS_CLEANING(status)
	int status;
CODE:
	RETVAL = (status & CSP_CLEANING) != 0;
OUTPUT:
	RETVAL

int
sam_CS_BARCODE(status)
	int status;
CODE:
	RETVAL = (status & CSP_BAR_CODE) != 0;
OUTPUT:
	RETVAL

int
sam_CS_WRTPROT(status)
	int status;
CODE:
	RETVAL = (status & CSP_WRITEPROTECT) != 0;
OUTPUT:
	RETVAL

int
sam_CS_RDONLY(status)
	int status;
CODE:
	RETVAL = (status & CSP_READ_ONLY) != 0;
OUTPUT:
	RETVAL

int
sam_CS_RECYCLE(status)
	int status;
CODE:
	RETVAL = (status & CSP_RECYCLE) != 0;
OUTPUT:
	RETVAL

int
sam_CS_UNAVAIL(status)
	int status;
CODE:
	RETVAL = (status & CSP_UNAVAIL) != 0;
OUTPUT:
	RETVAL

int
sam_CS_EXPORT(status)
	int status;
CODE:
	RETVAL = (status & CSP_EXPORT) != 0;
OUTPUT:
	RETVAL

void
sam_stat(path)
	char *path
PREINIT:
	struct sam_stat statbuf;
	int retval;
	int i;
PPCODE:
	retval = sam_stat(path, &statbuf, sizeof statbuf);
	if (retval == 0) {
		EXTEND(SP, 22+MAX_ARCHIVE);
 /*  0 */	PUSHs(sv_2mortal(newSViv(statbuf.st_dev)));
 /*  1 */	PUSHs(sv_2mortal(newSViv(statbuf.st_ino)));
 /*  2 */	PUSHs(sv_2mortal(newSViv(statbuf.st_mode)));
 /*  3 */	PUSHs(sv_2mortal(newSViv(statbuf.st_nlink)));
 /*  4 */	PUSHs(sv_2mortal(newSViv(statbuf.st_uid)));
 /*  5 */	PUSHs(sv_2mortal(newSViv(statbuf.st_gid)));
 /*  6 */	PUSHs(sv_2mortal(newSViv(statbuf.rdev)));
 /*  7 */	PUSHs(sv_2mortal(newSVpv(ull2s(statbuf.st_size), 0)));
 /*  8 */	PUSHs(sv_2mortal(newSViv(statbuf.st_atime)));
 /*  9 */	PUSHs(sv_2mortal(newSViv(statbuf.st_mtime)));
 /* 10 */	PUSHs(sv_2mortal(newSViv(statbuf.st_ctime)));
 #ifdef OLD_SAMFS
 /* 11 */	PUSHs(&PL_sv_undef);    /* blksize */
 /* 12 */	PUSHs(&PL_sv_undef);    /* blocks */
 #else
 /* 11 */	PUSHs(sv_2mortal(newSViv(512)));	/* blksize */
 /* 12 */	PUSHs(sv_2mortal(newSVpv(ull2s(statbuf.st_blocks), 0)));
 #endif
 /* 13 */	PUSHs(sv_2mortal(newSViv(statbuf.attr)));
 /* 14 */	PUSHs(sv_2mortal(newSViv(statbuf.attribute_time)));
 /* 15 */	PUSHs(sv_2mortal(newSViv(statbuf.creation_time)));
 /* 16 */	PUSHs(sv_2mortal(newSViv(statbuf.residence_time)));
 /* 17 */	PUSHs(sv_2mortal(newSViv(statbuf.cs_algo)));
 /* 19 */	PUSHs(sv_2mortal(newSViv(statbuf.flags)));
 /* 20 */	PUSHs(sv_2mortal(newSViv(statbuf.gen)));
 /* 21 */	PUSHs(sv_2mortal(newSViv(statbuf.partial_size)));
		for (i=0; i<MAX_ARCHIVE; i++) {
			AV *av = newAV();
			av_extend(av, 7);
			PUSHs(sv_2mortal(newRV_noinc((SV*)av)));
			av_store(av, 0, newSViv(statbuf.copy[i].flags));
			av_store(av, 1, newSViv(statbuf.copy[i].n_vsns));
			av_store(av, 2, newSViv(statbuf.copy[i].creation_time));
			av_store(av, 3, newSVpv(ull2s(statbuf.copy[i].position), 0));
			av_store(av, 4, newSViv(statbuf.copy[i].offset));
			av_store(av, 5, newSVpv(statbuf.copy[i].media, 0));
			av_store(av, 6, newSVpv(statbuf.copy[i].vsn, 0));
		}
	}

void
sam_lstat(path)
	char *path
PREINIT:
	struct sam_stat statbuf;
	int retval;
	int i;
PPCODE:
	retval = sam_lstat(path, &statbuf, sizeof statbuf);
	if (retval == 0) {
		EXTEND(SP, 22+MAX_ARCHIVE);
 /*  0 */	PUSHs(sv_2mortal(newSViv(statbuf.st_dev)));
 /*  1 */	PUSHs(sv_2mortal(newSViv(statbuf.st_ino)));
 /*  2 */	PUSHs(sv_2mortal(newSViv(statbuf.st_mode)));
 /*  3 */	PUSHs(sv_2mortal(newSViv(statbuf.st_nlink)));
 /*  4 */	PUSHs(sv_2mortal(newSViv(statbuf.st_uid)));
 /*  5 */	PUSHs(sv_2mortal(newSViv(statbuf.st_gid)));
 /*  6 */	PUSHs(sv_2mortal(newSViv(statbuf.rdev)));
 /*  7 */	PUSHs(sv_2mortal(newSVpv(ull2s(statbuf.st_size), 0)));
 /*  8 */	PUSHs(sv_2mortal(newSViv(statbuf.st_atime)));
 /*  9 */	PUSHs(sv_2mortal(newSViv(statbuf.st_mtime)));
 /* 10 */	PUSHs(sv_2mortal(newSViv(statbuf.st_ctime)));
 #ifdef OLD_SAMFS
 /* 11 */	PUSHs(&PL_sv_undef);    /* blksize */
 /* 12 */	PUSHs(&PL_sv_undef);    /* blocks */
 #else
 /* 11 */	PUSHs(sv_2mortal(newSViv(512)));	/* blksize */
 /* 12 */	PUSHs(sv_2mortal(newSVpv(ull2s(statbuf.st_blocks), 0)));
 #endif
 /* 13 */	PUSHs(sv_2mortal(newSViv(statbuf.attr)));
 /* 14 */	PUSHs(sv_2mortal(newSViv(statbuf.attribute_time)));
 /* 15 */	PUSHs(sv_2mortal(newSViv(statbuf.creation_time)));
 /* 16 */	PUSHs(sv_2mortal(newSViv(statbuf.residence_time)));
 /* 17 */	PUSHs(sv_2mortal(newSViv(statbuf.cs_algo)));
 /* 19 */	PUSHs(sv_2mortal(newSViv(statbuf.flags)));
 /* 20 */	PUSHs(sv_2mortal(newSViv(statbuf.gen)));
 /* 21 */	PUSHs(sv_2mortal(newSViv(statbuf.partial_size)));
		for (i=0; i<MAX_ARCHIVE; i++) {
			AV *av = newAV();
			av_extend(av, 7);
			PUSHs(sv_2mortal(newRV_noinc((SV*)av)));
			av_store(av, 0, newSViv(statbuf.copy[i].flags));
			av_store(av, 1, newSViv(statbuf.copy[i].n_vsns));
			av_store(av, 2, newSViv(statbuf.copy[i].creation_time));
			av_store(av, 3, newSVpv(ull2s(statbuf.copy[i].position), 0));
			av_store(av, 4, newSViv(statbuf.copy[i].offset));
			av_store(av, 5, newSVpv(statbuf.copy[i].media, 0));
			av_store(av, 6, newSVpv(statbuf.copy[i].vsn, 0));
		}
	}

 /*
  * New versions. These return a reference to the array of copies
  * instead of the individual elements. They are also meant to be extended
  * when Sun introduces even more elements into the sam_stat struct.
 */

#ifndef OLD_SAMFS
void
sam_stat_scalars(path)
	char *path
PREINIT:
	struct sam_stat statbuf;
	int retval;
	int i;
        AV *copies;
PPCODE:
	retval = sam_stat(path, &statbuf, sizeof statbuf);
	if (retval == 0) {
		EXTEND(SP, 29);
 /*  0 */	PUSHs(sv_2mortal(newSViv(statbuf.st_dev)));
 /*  1 */	PUSHs(sv_2mortal(newSViv(statbuf.st_ino)));
 /*  2 */	PUSHs(sv_2mortal(newSViv(statbuf.st_mode)));
 /*  3 */	PUSHs(sv_2mortal(newSViv(statbuf.st_nlink)));
 /*  4 */	PUSHs(sv_2mortal(newSViv(statbuf.st_uid)));
 /*  5 */	PUSHs(sv_2mortal(newSViv(statbuf.st_gid)));
 /*  6 */	PUSHs(sv_2mortal(newSViv(statbuf.rdev)));
 /*  7 */	PUSHs(sv_2mortal(newSVpv(ull2s(statbuf.st_size), 0)));
 /*  8 */	PUSHs(sv_2mortal(newSViv(statbuf.st_atime)));
 /*  9 */	PUSHs(sv_2mortal(newSViv(statbuf.st_mtime)));
 /* 10 */	PUSHs(sv_2mortal(newSViv(statbuf.st_ctime)));
 /* 11 */	PUSHs(sv_2mortal(newSViv(512)));	/* blksize */
 /* 12 */	PUSHs(sv_2mortal(newSVpv(ull2s(statbuf.st_blocks), 0)));
 /* 13 */	PUSHs(sv_2mortal(newSViv(statbuf.attr)));
 /* 14 */	PUSHs(sv_2mortal(newSViv(statbuf.attribute_time)));
 /* 15 */	PUSHs(sv_2mortal(newSViv(statbuf.creation_time)));
 /* 16 */	PUSHs(sv_2mortal(newSViv(statbuf.residence_time)));
 /* 17 */	PUSHs(sv_2mortal(newSViv(statbuf.cs_algo)));
 /* 18 */	PUSHs(sv_2mortal(newSViv(statbuf.flags)));
 /* 19 */	PUSHs(sv_2mortal(newSViv(statbuf.gen)));
 /* 20 */	PUSHs(sv_2mortal(newSViv(statbuf.partial_size)));
                copies = newAV();
                sv_2mortal((SV*)copies);
                av_extend(copies, MAX_ARCHIVE);
 /* 21 */	PUSHs(sv_2mortal(newRV_noinc((SV*)copies)));
		for (i=0; i<MAX_ARCHIVE; i++) {
			AV *av = newAV();
                        av_store(copies, i, newRV_noinc((SV*)av));
			av_extend(av, 7);
			av_store(av, 0, newSViv(statbuf.copy[i].flags));
			av_store(av, 1, newSViv(statbuf.copy[i].n_vsns));
			av_store(av, 2, newSViv(statbuf.copy[i].creation_time));
			av_store(av, 3, newSVpv(ull2s(statbuf.copy[i].position), 0));
			av_store(av, 4, newSViv(statbuf.copy[i].offset));
			av_store(av, 5, newSVpv(statbuf.copy[i].media, 0));
			av_store(av, 6, newSVpv(statbuf.copy[i].vsn, 0));
		}
 /* 22 */	PUSHs(sv_2mortal(newSViv(statbuf.stripe_width)));
 /* 23 */	PUSHs(sv_2mortal(newSViv(statbuf.stripe_group)));
 /* 24 */	PUSHs(sv_2mortal(newSViv(statbuf.segment_size)));
 /* 25 */	PUSHs(sv_2mortal(newSViv(statbuf.segment_number)));
 /* 26 */	PUSHs(sv_2mortal(newSViv(statbuf.stage_ahead)));
 /* 27 */	PUSHs(sv_2mortal(newSViv(statbuf.admin_id)));
 /* 28 */	PUSHs(sv_2mortal(newSViv(statbuf.allocahead)));
	}

void
sam_lstat_scalars(path)
	char *path
PREINIT:
	struct sam_stat statbuf;
	int retval;
	int i;
        AV *copies;
PPCODE:
	retval = sam_lstat(path, &statbuf, sizeof statbuf);
	if (retval == 0) {
		EXTEND(SP, 29);
 /*  0 */	PUSHs(sv_2mortal(newSViv(statbuf.st_dev)));
 /*  1 */	PUSHs(sv_2mortal(newSViv(statbuf.st_ino)));
 /*  2 */	PUSHs(sv_2mortal(newSViv(statbuf.st_mode)));
 /*  3 */	PUSHs(sv_2mortal(newSViv(statbuf.st_nlink)));
 /*  4 */	PUSHs(sv_2mortal(newSViv(statbuf.st_uid)));
 /*  5 */	PUSHs(sv_2mortal(newSViv(statbuf.st_gid)));
 /*  6 */	PUSHs(sv_2mortal(newSViv(statbuf.rdev)));
 /*  7 */	PUSHs(sv_2mortal(newSVpv(ull2s(statbuf.st_size), 0)));
 /*  8 */	PUSHs(sv_2mortal(newSViv(statbuf.st_atime)));
 /*  9 */	PUSHs(sv_2mortal(newSViv(statbuf.st_mtime)));
 /* 10 */	PUSHs(sv_2mortal(newSViv(statbuf.st_ctime)));
 /* 11 */	PUSHs(sv_2mortal(newSViv(512)));	/* blksize */
 /* 12 */	PUSHs(sv_2mortal(newSVpv(ull2s(statbuf.st_blocks), 0)));
 /* 13 */	PUSHs(sv_2mortal(newSViv(statbuf.attr)));
 /* 14 */	PUSHs(sv_2mortal(newSViv(statbuf.attribute_time)));
 /* 15 */	PUSHs(sv_2mortal(newSViv(statbuf.creation_time)));
 /* 16 */	PUSHs(sv_2mortal(newSViv(statbuf.residence_time)));
 /* 17 */	PUSHs(sv_2mortal(newSViv(statbuf.cs_algo)));
 /* 18 */	PUSHs(sv_2mortal(newSViv(statbuf.flags)));
 /* 19 */	PUSHs(sv_2mortal(newSViv(statbuf.gen)));
 /* 20 */	PUSHs(sv_2mortal(newSViv(statbuf.partial_size)));
                copies = newAV();
                sv_2mortal((SV*)copies);
                av_extend(copies, MAX_ARCHIVE);
 /* 21 */	PUSHs(sv_2mortal(newRV_noinc((SV*)copies)));
		for (i=0; i<MAX_ARCHIVE; i++) {
			AV *av = newAV();
                        av_store(copies, i, newRV_noinc((SV*)av));
			av_extend(av, 7);
			av_store(av, 0, newSViv(statbuf.copy[i].flags));
			av_store(av, 1, newSViv(statbuf.copy[i].n_vsns));
			av_store(av, 2, newSViv(statbuf.copy[i].creation_time));
			av_store(av, 3, newSVpv(ull2s(statbuf.copy[i].position), 0));
			av_store(av, 4, newSViv(statbuf.copy[i].offset));
			av_store(av, 5, newSVpv(statbuf.copy[i].media, 0));
			av_store(av, 6, newSVpv(statbuf.copy[i].vsn, 0));
		}
 /* 22 */	PUSHs(sv_2mortal(newSViv(statbuf.stripe_width)));
 /* 23 */	PUSHs(sv_2mortal(newSViv(statbuf.stripe_group)));
 /* 24 */	PUSHs(sv_2mortal(newSViv(statbuf.segment_size)));
 /* 25 */	PUSHs(sv_2mortal(newSViv(statbuf.segment_number)));
 /* 26 */	PUSHs(sv_2mortal(newSViv(statbuf.stage_ahead)));
 /* 27 */	PUSHs(sv_2mortal(newSViv(statbuf.admin_id)));
 /* 28 */	PUSHs(sv_2mortal(newSViv(statbuf.allocahead)));
	}

#endif

#ifdef OLD_SAMFS

void
sam_vsn_stat(path, copy)
	char *	path
	int	copy
PREINIT:
#ifndef MAX_VSNS
 /* Make SamFS 3.3.1-15 backwards compatible */
#define MAX_VSNS MAX_VOLUMES
	struct sam_vsn_stat {
		struct sam_section section[MAX_VOLUMES];
	};
#define CAST (struct sam_section*)
#else
#define CAST
#endif
	struct sam_vsn_stat statbuf;
	int retval;
	int i;
PPCODE:
	retval = sam_vsn_stat(path, copy, CAST &statbuf, sizeof statbuf);
	if (retval == 0) {
		EXTEND(SP, MAX_VSNS);
		for (i=0; i<MAX_VSNS; i++) {
			AV *av = newAV();
			av_extend(av, 4);
			PUSHs(sv_2mortal(newRV_noinc((SV*)av)));
			av_store(av, 0, newSVpv(statbuf.section[i].vsn, 0));
			av_store(av, 1, newSVpv(ull2s(statbuf.section[i].length), 0));
			av_store(av, 2, newSVpv(ull2s(statbuf.section[i].position), 0));
			av_store(av, 3, newSVpv(ull2s(statbuf.section[i].offset), 0));
		}
	}

#else

void
sam_vsn_stat(path, copy)
	char *	path
	int	copy
PREINIT:
	struct sam_section statbuf;
	int retval;
	int i;
PPCODE:
	retval = sam_vsn_stat(path, copy, &statbuf, sizeof statbuf);
	if (retval == 0) {
		EXTEND(SP, 1);
		AV *av = newAV();
		av_extend(av, 4);
		PUSHs(sv_2mortal(newRV_noinc((SV*)av)));
		av_store(av, 0, newSVpv(statbuf.vsn, 0));
		av_store(av, 1, newSVpv(ull2s(statbuf.length), 0));
		av_store(av, 2, newSVpv(ull2s(statbuf.position), 0));
		av_store(av, 3, newSVpv(ull2s(statbuf.offset), 0));
	}

#endif

# The sam_segment_foo and sam_restore_foo functions have been
# introduced after I was cut off from any running SamFS
# installation. This code should be conditional on *something* to be
# compatible with old SamFS versions that don't have the functions. But
# conditional on *what*?!? So for now they are just wrapped in an
# #ifndef OLD_SAMFS.
# Because I have no way of testing this, the code will probably
# contain mistakes because of my misunderstandings of the terse
# documentation.

#ifndef OLD_SAMFS
int
sam_segment_vsn_stat(path, copy, segment_index)
	char *			path
	int			copy
	int			segment_index
PREINIT:
	struct sam_section statbuf;
	int retval;
	int i;
PPCODE:
	retval = sam_segment_vsn_stat(path, copy, segment_index, &statbuf, sizeof statbuf);
	if (retval == 0) {
		EXTEND(SP, 1);
		AV *av = newAV();
		av_extend(av, 4);
		PUSHs(sv_2mortal(newRV_noinc((SV*)av)));
		av_store(av, 0, newSVpv(statbuf.vsn, 0));
		av_store(av, 1, newSVpv(ull2s(statbuf.length), 0));
		av_store(av, 2, newSVpv(ull2s(statbuf.position), 0));
		av_store(av, 3, newSVpv(ull2s(statbuf.offset), 0));
	}

int
sam_segment_stat(path)
	char *			path
PREINIT:
	struct sam_stat file_info;
	struct sam_stat *data_seg_info_ptr;
	int number_of_data_segments;
	int retval;
	int i;
PPCODE:
	retval = sam_stat(path, &file_info, sizeof file_info);
	if (retval == 0) {
		if (SS_ISSEGMENT_F(file_info.attr)) {
	                number_of_data_segments = NUM_SEGS(&file_info);
                        Newxz(data_seg_info_ptr, number_of_data_segments,
                              struct sam_stat);
                	retval = sam_segment_stat(path, data_seg_info_ptr,
                                                  number_of_data_segments *
                                                  sizeof(struct sam_stat));
                        if (retval == 0) {
                		EXTEND(SP, number_of_data_segments);
                                for (i=0; i<number_of_data_segments; i++) {
                                        AV *av;
                                        av = newAV();
                                        sv_2mortal((SV*)av);
                                        av_extend(av, 30);
                                        PUSHs(sv_2mortal(newRV_noinc((SV*)av)));
                                        sam_stat2av(&file_info, av);
                                }
                        }
	                Safefree(data_seg_info_ptr);
                } else {
                        /* Not segmented, just return a list of one element,
                           from file_info. */
                        AV *av;
        		EXTEND(SP, 1);
                        av = newAV();
                        sv_2mortal((SV*)av);
                        av_extend(av, 30);
                        PUSHs(sv_2mortal(newRV_noinc((SV*)av)));
                        sam_stat2av(&file_info, av);
                }
        }

int
sam_segment_lstat(path)
	char *			path
PREINIT:
	struct sam_stat file_info;
	struct sam_stat *data_seg_info_ptr;
	int number_of_data_segments;
	int retval;
	int i;
PPCODE:
	retval = sam_lstat(path, &file_info, sizeof file_info);
	if (retval == 0) {
		if (SS_ISSEGMENT_F(file_info.attr)) {
	                number_of_data_segments = NUM_SEGS(&file_info);
                        Newxz(data_seg_info_ptr, number_of_data_segments,
                              struct sam_stat);
                	retval = sam_segment_lstat(path, data_seg_info_ptr,
                                                  number_of_data_segments *
                                                  sizeof(struct sam_stat));
                        if (retval == 0) {
                		EXTEND(SP, number_of_data_segments);
                                for (i=0; i<number_of_data_segments; i++) {
                                        AV *av;
                                        av = newAV();
                                        sv_2mortal((SV*)av);
                                        av_extend(av, 30);
                                        PUSHs(sv_2mortal(newRV_noinc((SV*)av)));
                                        sam_stat2av(&file_info, av);
                                }
                        }
	                Safefree(data_seg_info_ptr);
                } else {
                        /* Not segmented, just return a list of one element,
                           from file_info. */
                        AV *av;
        		EXTEND(SP, 1);
                        av = newAV();
                        sv_2mortal((SV*)av);
                        av_extend(av, 30);
                        PUSHs(sv_2mortal(newRV_noinc((SV*)av)));
                        sam_stat2av(&file_info, av);
                }
        }

int
sam_restore_file(path, st_mode, st_uid, st_gid, st_size, st_atime, st_ctime, st_mtime, copies)
	char *          path
	unsigned long	st_mode
	unsigned long	st_uid
	unsigned long	st_gid
	char *          st_size
	unsigned long	st_atime
	unsigned long	st_ctime
	unsigned long	st_mtime
        SV *            copies
INIT:
	struct sam_stat info;
        int i;
CODE:
        if ((!SvROK(copies)) || (SvTYPE(SvRV(copies)) != SVt_PVAV)) {
                croak("\"copies\" argument has wrong type - must be array ref");
        } else if (av_len((AV*)copies) != MAX_ARCHIVE) {
                croak("\"copies\" argument must have exactly %d elements",
                      MAX_ARCHIVE);
        }
        info.st_mode = st_mode;
        info.st_uid = st_uid;
        info.st_gid = st_gid;
        sscanf(st_size, "%llu", &info.st_size);
        info.st_atime = st_atime;
        info.st_ctime = st_ctime;
        info.st_mtime = st_mtime;
        for (i=0; i<MAX_ARCHIVE; i++) {
                AV *copy;
                STRLEN l;
                char *media;
                char *vsn;
                copy = (AV*)*av_fetch((AV*)SvRV(copies), i, 0);
                media = SvPV(*av_fetch(copy, 0, 0), l);
                if (l > 4) {
                        l = 4;
                }
                strncpy(info.copy[i].media, media, l);
                sscanf(SvPV_nolen(*av_fetch(copy, 1, 0)), "%llu",
                       &info.copy[i].position);
                info.copy[i].creation_time =
                        (time_t)SvIV(*av_fetch(copy, 2, 0));
                vsn = SvPV(*av_fetch(copy, 3, 0), l);
                if (l > 32) {
                        l = 32;
                }
                strncpy(info.copy[i].vsn, vsn, l);
        }
        RETVAL = sam_restore_file(path, &info, sizeof info);
OUTPUT:
        RETVAL

int
sam_restore_copy(path, copy_no, st_mode, st_uid, st_gid, st_size, st_atime, st_ctime, st_mtime, copy_info, ...)
	char *		path
	int		copy_no
	unsigned long	st_mode
	unsigned long	st_uid
	unsigned long	st_gid
	char *          st_size
	unsigned long	st_atime
	unsigned long	st_ctime
	unsigned long	st_mtime
        SV *            copy_info
INIT:
	struct sam_stat info;
        struct sam_section *sinfo;
        int sinfosize;
        AV *av;
        int l;
        char *media;
        char *vsn;
        int i;

        if ((!SvROK(copy_info)) || (SvTYPE(SvRV(copy_info)) != SVt_PVAV)) {
                croak("\"copy_info\" argument has wrong type - must be array ref");
        } else if (av_len((AV *)SvRV(copy_info)) != 5) {
                croak("\"copy_info\" argument must have exactly 5 elements");
        }
CODE:
        info.st_mode = st_mode;
        info.st_uid = st_uid;
        info.st_gid = st_gid;
        sscanf(st_size, "%llu", &info.st_size);
        info.st_atime = st_atime;
        info.st_ctime = st_ctime;
        info.st_mtime = st_mtime;
	av = (AV*)SvRV(copy_info);
	media = SvPV(*av_fetch(av, 0, 0), l);
	if (l > 4) {
	        l = 4;
	}
	strncpy(info.copy[copy_no].media, media, l);
	sscanf(SvPV_nolen(*av_fetch(av, 1, 0)), "%llu",
	       &info.copy[copy_no].position);
	info.copy[copy_no].creation_time =
	        (time_t)SvIV(*av_fetch(av, 2, 0));
	vsn = SvPV(*av_fetch(av, 3, 0), l);
	if (l > 32) {
	        l = 32;
	}
	strncpy(info.copy[copy_no].vsn, vsn, l);
        info.copy[copy_no].offset = SvIV(*av_fetch(av, 2, 0));
        /* info.copy[copy_no].vsns is implicitly defined by the number
           of sections supplied */
        info.copy[copy_no].n_vsns = 1;
        sinfo = (struct sam_section *)0;
        sinfosize = 0;
        if (items > 9) {
                /* sections array, check it */
                SV *sv = ST(9);
                if ((!SvROK(sv)) || (SvTYPE(SvRV(sv)) != SVt_PVAV)) {
                       croak("\"sections\" has wrong type - must be array ref");
                }
                av = (AV*)sv;
                info.copy[copy_no].n_vsns = av_len(av) + 1;
                Newxz(sinfo, av_len(av), struct sam_section);
                sinfosize = av_len(av) * sizeof(struct sam_section);
                for (i=0; i<av_len(av); i++) {
                        AV *av2;
                        char *vsn;
                        av2 = (AV*)*av_fetch((AV*)SvRV(av), i, 0);
                        if ((!SvROK(av2)) || (SvTYPE(SvRV(av2)) != SVt_PVAV)) {
                                croak("section %d has wrong type - must be array ref",
                                      i);
                        } else if (av_len((AV *)SvRV(copy_info)) != 4) {
                                croak("section must have exactly 4 elements");
                        }
                        vsn = SvPV(*av_fetch(av2, 0, 0), l);
                        if (l > 32) {
                                l = 32;
                        }
                        strncpy(sinfo[i].vsn, vsn, l);
                        sscanf(SvPV_nolen(*av_fetch(av2, 1, 0)), "%llu",
                               &sinfo[i].length);
                        sscanf(SvPV_nolen(*av_fetch(av2, 2, 0)), "%llu",
                               &sinfo[i].position);
                        sscanf(SvPV_nolen(*av_fetch(av2, 3, 0)), "%llu",
                               &sinfo[i].offset);
                }
        }

        RETVAL = sam_restore_copy(path, copy_no,
                                  &info, sizeof info,
                                  sinfo, sinfosize);
OUTPUT:
        RETVAL

#endif

char *
sam_attrtoa(attr)
	int	attr
CODE:
	RETVAL = sam_attrtoa(attr, NULL);
OUTPUT:
	RETVAL

void
sam_devstat(eq)
	int	eq
PREINIT:
	struct sam_devstat statbuf;
	int retval;
PPCODE:
	retval = sam_devstat(eq, &statbuf, sizeof statbuf);
	if (retval == 0) {
		EXTEND(SP, 7);
/* 0 */		PUSHs(sv_2mortal(newSViv(statbuf.type)));
/* 1 */		PUSHs(sv_2mortal(newSVpv(statbuf.name, 0)));
/* 2 */		PUSHs(sv_2mortal(newSVpv(statbuf.vsn, 0)));
/* 3 */		PUSHs(sv_2mortal(newSVpv(dev_state[statbuf.state], 0)));
/* 4 */		PUSHs(sv_2mortal(newSViv(statbuf.status)));
/* 5 */		PUSHs(sv_2mortal(newSViv(statbuf.space)));
/* 6 */		PUSHs(sv_2mortal(newSViv(statbuf.capacity)));
	}

void
sam_ndevstat(eq)
	int	eq
PREINIT:
	struct sam_ndevstat statbuf;
	int retval;
PPCODE:
	retval = sam_ndevstat(eq, &statbuf, sizeof statbuf);
	if (retval == 0) {
		EXTEND(SP, 7);
/* 0 */		PUSHs(sv_2mortal(newSViv(statbuf.type)));
/* 1 */		PUSHs(sv_2mortal(newSVpv(statbuf.name, 0)));
/* 2 */		PUSHs(sv_2mortal(newSVpv(statbuf.vsn, 0)));
/* 3 */		PUSHs(sv_2mortal(newSVpv(dev_state[statbuf.state], 0)));
/* 4 */		PUSHs(sv_2mortal(newSViv(statbuf.status)));
/* 5 */		PUSHs(sv_2mortal(newSViv(statbuf.space)));
/* 6 */		PUSHs(sv_2mortal(newSViv(statbuf.capacity)));
	}

char *
sam_devstr(status)
	int	status
CODE:
	RETVAL = sam_devstr(status);
OUTPUT:
	RETVAL

void
sam_opencat(path)
	char *	path
PREINIT:
	struct sam_cat_tbl catbuf;
	int retval;
PPCODE:
	retval = sam_opencat(path, &catbuf, sizeof catbuf);
	if (retval >= 0) {
		EXTEND(SP, 4);
/* 0 */		PUSHs(sv_2mortal(newSViv(retval)));
/* 1 */		PUSHs(sv_2mortal(newSViv(catbuf.audit_time)));
/* 2 */		PUSHs(sv_2mortal(newSViv(catbuf.version)));
/* 3 */		PUSHs(sv_2mortal(newSViv(catbuf.count)));
/* 4 */		PUSHs(sv_2mortal(newSVpv(catbuf.media, 0)));
	}

int
sam_closecat(cat_handle)
	int	cat_handle

void
sam_getcatalog(cat_handle, slot)
	int	cat_handle
	int	slot
PREINIT:
	struct sam_cat_ent	catbuf;
	int retval;
PPCODE:
	retval = sam_getcatalog(cat_handle, slot, slot, &catbuf, sizeof catbuf);
	if (retval >= 0) {
		EXTEND(SP, 11);
/* 0 */		PUSHs(sv_2mortal(newSViv(catbuf.type)));
/* 1 */		PUSHs(sv_2mortal(newSViv(catbuf.status)));
/* 2 */		PUSHs(sv_2mortal(newSVpv(catbuf.media, 0)));
/* 3 */		PUSHs(sv_2mortal(newSVpv(catbuf.vsn, 0)));
/* 4 */		PUSHs(sv_2mortal(newSViv(catbuf.access)));
/* 5 */		PUSHs(sv_2mortal(newSViv(catbuf.capacity)));
/* 6 */		PUSHs(sv_2mortal(newSViv(catbuf.space)));
/* 7 */		PUSHs(sv_2mortal(newSViv(catbuf.ptoc_fwa)));
/* 8 */		PUSHs(sv_2mortal(newSViv(catbuf.modification_time)));
/* 9 */		PUSHs(sv_2mortal(newSViv(catbuf.mount_time)));
/*10 */		PUSHs(sv_2mortal(newSVpv(catbuf.bar_code, 0)));
	}


int
sam_archive(name, opns)
	char *	name
	char *	opns

int
sam_cancelstage(name)
	char *	name

int
sam_release(name, opns)
	char *	name
	char *	opns

int
sam_ssum(name, opns)
	char *	name
	char *	opns

int
sam_stage(name, opns)
	char *	name
	char *	opns

int
sam_setfa(name, opns)
	char *	name
	char *	opns

int
sam_advise(fildes, opns)
	int	fildes
	char *	opns

# Not yet implemented.

#-# int
#-# sam_request(path, buf, bufsize)
#-# 	char *			path
#-# 	struct sam_rminfo *	buf
#-# 	size_t			bufsize

# Not documented
#-# int
#-# sam_readrminfo(path, buf, bufsize)
#-# 	char *	path
#-# 	struct sam_rminfo *	buf
#-# 	size_t	bufsize

#-# int
#-# sam_segment(name, opns);
#-# 	char *	name
#-# 	char *	opns

# is_<foo> macros from devstat.h

#ifdef is_disk

int
sam_is_disk(a)
	int	a
CODE:
	RETVAL = is_disk(a);
OUTPUT:
	RETVAL

#endif

#ifdef is_optical

int
sam_is_optical(a)
	int	a
CODE:
	RETVAL = is_optical(a);
OUTPUT:
	RETVAL

#endif

#ifdef is_robot

int
sam_is_robot(a)
	int	a
CODE:
	RETVAL = is_robot(a);
OUTPUT:
	RETVAL

#endif

#ifdef is_tape

int
sam_is_tape(a)
	int	a
CODE:
	RETVAL = is_tape(a);
OUTPUT:
	RETVAL

#endif

#ifdef is_tapelib

int
sam_is_tapelib(a)
	int	a
CODE:
	RETVAL = is_tapelib(a);
OUTPUT:
	RETVAL

#endif

#ifdef is_third_party

int
sam_is_third_party(a)
	int	a
CODE:
	RETVAL = is_third_party(a);
OUTPUT:
	RETVAL

#endif

#ifdef is_stripe_group

int
sam_is_stripe_group(a)
	int	a
CODE:
	RETVAL = is_stripe_group(a);
OUTPUT:
	RETVAL

#endif

#ifdef is_rsd

int
sam_is_rsd(a)
	int	a
CODE:
	RETVAL = is_rsd(a);
OUTPUT:
	RETVAL

#endif

#ifdef is_stk

int
sam_is_stk5800(a)
	int	a
CODE:
	RETVAL = is_stk5800(a);
OUTPUT:
	RETVAL

#endif
