/*
 * Copyright (c) 1995 Jarkko Hietaniemi and Kenneth Albanowski. 
 * All rights reserved. This program is free software; you can 
 * redistribute it and/or  modify it under the same terms as 
 * Perl itself.
 *
 */
 
 /*
 	TODO:
 	
 		Complete _base_lockfile.
 		
 		Fix DESTROY problem for File::Lock.
 		
 		Consider adding OO access to flock, lockf, lockfile.
 		
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef I_SYS_TYPES
#include <sys/types.h>
#endif

#ifdef I_SYS_FILE
#include <sys/file.h>
#endif

#ifdef I_FCNTL
#include <fcntl.h>
#endif

#ifdef I_UNISTD
#include <unistd.h>
#endif

#include <errno.h>

/* define this to trace the fcntl/lockf/flock calls */
#define FDEBUG

#ifdef I_SYS_TYPES
#include <sys/types.h>
#endif
#ifdef I_FCNTL
#include <fcntl.h>
#endif
#ifdef I_UNISTD
#include <unistd.h>
#endif
#ifdef I_SYS_FILE
#include <sys/file.h>
#endif

#ifdef File_Lock_DEBUG
#include <stdio.h>
#endif

#include <errno.h>

extern int errno;

/* Are we missing any important symbols? */

#if defined(HAS_LOCKF)
# if !defined(F_ULOCK) || !defined(F_LOCK) || !defined(F_TLOCK) || !defined (F_TEST)
#  undef HAS_LOCKF
# endif
#endif

#if defined(HAS_FCNTL)
# if !defined(F_UNLCK) || !defined(F_WRLCK) || !defined(F_RDLCK) || !defined (F_WRLCK)
#  undef HAS_FCNTK
# else
#  if !defined(F_SETLK) || !defined(F_SETLKW) || !defined(F_GETLK)
#   undef HAS_FCNTL
#  endif
# endif
#endif

#if defined(HAS_FLOCK)
# if !defined(LOCK_UN) || !defined(LOCK_SH) || !defined(LOCK_EX) || !defined(LOCK_NB)
#  undef HAS_FLOCK
# endif
#endif

/* @@@ sigh, we need a real check for this one. */

#if defined(__sgi)
#define HAS_SYSID_IN_FCNTL
#endif

#define MACRO_BEGIN do {
#define MACRO_END   } while (0)

static int
not_here(s)
char *s;
{
    croak("%s not implemented on this architecture", s);
    return -1;
}


static double
constant(name, arg)
char *name;
int arg;
{
    errno = 0;
    switch (*name) {
    case 'E':
	if (strEQ(name, "EACCES"))
#ifdef EACCES
	    return EACCES;
#else
	    goto not_there;
#endif
	if (strEQ(name, "EBADF"))
#ifdef EBADF
	    return EBADF;
#else
	    goto not_there;
#endif
	if (strEQ(name, "EDEADLK"))
#ifdef EDEADLK
	    return EDEADLK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "EFAULT"))
#ifdef EFAULT
	    return EFAULT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "EINTR"))
#ifdef EINTR
	    return EINTR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "EINVAL"))
#ifdef EINVAL
	    return EINVAL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "EMFILE"))
#ifdef EMFILE
	    return EMFILE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ENETUNREACH"))
#ifdef ENETUNREACH
	    return ENETUNREACH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ENOLCK"))
#ifdef ENOLCK
	    return ENOLCK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ENOMEM"))
#ifdef ENOMEM
	    return ENOMEM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "EWOULDBLOCK"))
#ifdef EWOULDBLOCK
	    return EWOULDBLOCK;
#else
	    goto not_there;
#endif
	break;
    case 'F':
	if (strEQ(name, "F_GETLK"))
#ifdef F_GETLK
	    return F_GETLK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "F_LOCK"))
#ifdef F_LOCK
	    return F_LOCK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "F_RDLCK"))
#ifdef F_RDLCK
	    return F_RDLCK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "F_SETLK"))
#ifdef F_SETLK
	    return F_SETLK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "F_SETLKW"))
#ifdef F_SETLKW
	    return F_SETLKW;
#else
	    goto not_there;
#endif
	if (strEQ(name, "F_TEST"))
#ifdef F_TEST
	    return F_TEST;
#else
	    goto not_there;
#endif
	if (strEQ(name, "F_TLOCK"))
#ifdef F_TLOCK
	    return F_TLOCK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "F_ULOCK"))
#ifdef F_ULOCK
	    return F_ULOCK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "F_UNLCK"))
#ifdef F_UNLCK
	    return F_UNLCK;
#else
	    goto not_there;
#endif
	if (strEQ(name, "F_WRLCK"))
#ifdef F_WRLCK
	    return F_WRLCK;
#else
	    goto not_there;
#endif
	break;
    case 'L':
    	
	if (strEQ(name, "LOCK_EX"))
#ifdef LOCK_EX
	    return LOCK_EX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "LOCK_NB"))
#ifdef LOCK_NB
	    return LOCK_NB;
#else
	    goto not_there;
#endif
	if (strEQ(name, "LOCK_SH"))
#ifdef LOCK_SH
	    return LOCK_SH;
#else
	    goto not_there;
#endif
	if (strEQ(name, "LOCK_UN"))
#ifdef LOCK_UN
	    return LOCK_UN;
#else
	    goto not_there;
#endif
	break;
    case 'S':
	if (strEQ(name, "SEEK_CUR"))
#ifdef SEEK_CUR
	    return SEEK_CUR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SEEK_END"))
#ifdef SEEK_END
	    return SEEK_END;
#else
	    goto not_there;
#endif
	if (strEQ(name, "SEEK_SET"))
#ifdef SEEK_SET
	    return SEEK_SET;
#else
	    goto not_there;
#endif
	break;
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}


typedef enum {	
	Lock_unlock, Lock_exclusive, Lock_shared, Lock_test, 	Lock_noblock, 
	Lock_modemask = (Lock_exclusive|Lock_shared|Lock_test), 
	Lock_blockmask = Lock_noblock,
	Lock_wait = 0, Lock_nowait = Lock_noblock, Lock_nonblock=Lock_noblock } mode_int;
	

#ifdef FDEBUG
char *	mode_name[8]	= {
	"Lock_unlock","Lock_exclusive","Lock_shared","Lock_test",
	"Lock_unlock|Lock_nowait","Lock_exclusive|Lock_nowait",
	"Lock_shared|Lock_nowait","Lock_test|Lock_nowait",
};
#define retval_name (retval?"bad":"good")
#endif


/* Match various ops to our standarized Lock_* tokens */

int flock_ops[8] = {
#ifndef HAS_FLOCK
	0,0,0,0, 0,0,0,0
#else
	LOCK_UN,LOCK_EX,LOCK_SH,-1, LOCK_UN,LOCK_EX|LOCK_NB,LOCK_SH|LOCK_NB,-1
#endif	
};

int fcntl_ops[2][8] = {
#ifndef HAS_FCNTL
	{0,0,0,0, 0,0,0,0},
	{0,0,0,0, 0,0,0,0},
#else
	{F_UNLCK,F_WRLCK,F_RDLCK,F_WRLCK,        F_UNLCK,F_WRLCK,F_RDLCK,F_WRLCK},
	{F_SETLK,F_SETLKW,F_SETLKW,F_GETLK, F_SETLK,F_SETLK,F_SETLK,F_GETLK},
#endif	
};

int lockf_ops[8] = {
#ifndef HAS_LOCKF
	0,0,0,0, 0,0,0,0
#else	
	F_ULOCK,F_LOCK,-1,F_TEST, F_ULOCK,F_TLOCK,-1,F_TEST
#endif	
};

/* The three locking calls. These are shells around the syscalls, which
provide a consistent interface (Lock_*). */

int _base_flock(fd, mode)
int		fd;
mode_int		mode;
{
	int retval;
#	ifdef FDEBUG
		fprintf(stderr,"Entering _base_flock(%d,%s)\n",fd,mode_name[mode]);
		errno=0;
#	endif		
#	ifdef HAS_FLOCK

		if((mode & Lock_modemask) == Lock_test) {
			if(!flock(fd, LOCK_EX | LOCK_NB)) {
				flock(fd, LOCK_UN);
				retval = Lock_unlock;
			} else if(errno != EWOULDBLOCK) {
				retval = -1; /* with errno set */
			} else if(!flock(fd, LOCK_SH | LOCK_NB)) {
				flock(fd, LOCK_UN);
				retval =  Lock_shared;
			} else if(errno != EWOULDBLOCK) {
				retval = -1; /* with errno set */
			} else {
				retval = Lock_exclusive;
			}
		} else {
			retval = flock(fd, flock_ops[mode]);
#			ifdef FDEBUG
				{ int saverr =errno;
				fprintf(stderr,"flock(%d,%d) = %d\n",fd,flock_ops[mode],retval);
				errno=saverr;
				}
#			endif		
		}
#		ifdef FDEBUG		
			if(retval) 
				fprintf(stderr,"V- Err: %s\n",Strerror(errno));
			fprintf(stderr,"Returning %d (%s) from _base_flock\n",retval,retval_name);
#		endif
		return retval;
#	else
		croak("flock is not supported on this architecture\n");		
#	endif
}

int _base_lockf(fd, mode, offset, whence, length)
int		fd;
mode_int		mode;
off_t	offset;
off_t	whence;
off_t	length;
{
#	ifdef FDEBUG
		fprintf(stderr,"Entering _base_lockf(%d,%s,%d,%d,%d)\n",fd,mode_name[mode],offset,whence,length);
		errno=0;
#	endif		
#	ifdef HAS_LOCKF
		if((mode & Lock_modemask) == Lock_shared) {
			croak("lockf does not support shared locks\n");
		} else {
			int retval;
			
			if( (offset != 0) || (whence != SEEK_CUR) ) {
				off_t original_pos = lseek(fd, 0, SEEK_CUR);
#				ifdef FDEBUG
					fprintf(stderr,"Seeking in _base_lockf\n");
#				endif
				lseek(fd, offset, whence);
				retval = lockf(fd, lockf_ops[mode], length);
				lseek(fd, original_pos, SEEK_SET);
#				ifdef FDEBUG
					{ int saverr =errno;
					fprintf(stderr,"lockf(%d,%d,%d) = %d\n",fd,lockf_ops[mode],length,retval);
					errno=saverr;
					}
#				endif		
			} else {
				retval = lockf(fd, lockf_ops[mode], length);
#				ifdef FDEBUG
					{ int saverr =errno;
					fprintf(stderr,"lockf(%d,%d,%d) = %d\n",fd,lockf_ops[mode],length,retval);
					errno=saverr;
					}
#				endif		
			}
#			ifdef FDEBUG
				if(retval) 
					fprintf(stderr,"V- Err: %s\n",Strerror(errno));
				fprintf(stderr,"Returning %d (%s) from _base_lockf\n",retval,retval_name);
#			endif		
			return retval; /* with errno set if -1 is returned */
						   /* Yes, the lseeks aren't properly checked,
						      but I'll worry about them some other time */
		}
#	else
		croak("lockf is not supported on this architecture\n");		
#	endif
}

int _base_fcntl(fd, mode, offset, whence, length, retflk)
int		fd;
mode_int		mode;
off_t	offset;
int		whence;
off_t	length;
struct flock * retflk;
{
#	ifdef FDEBUG
		fprintf(stderr,"Entering _base_fcntl(%d,%s,%d,%d,%d)\n",fd,mode_name[mode],offset,whence,length);
		errno=0;
#	endif		
#	ifdef HAS_FCNTL
	{
		int retval;
		struct flock flk;
			
		flk.l_type = fcntl_ops[0][mode];
		flk.l_whence = whence;
		flk.l_len = length;
		flk.l_start = offset;
		
		if((mode & Lock_modemask) == Lock_test) {
			/* Is this reduction even useful? Should exclusive be tested before shared? */
			flk.l_type = fcntl_ops[0][Lock_shared];
			retval = fcntl(fd, fcntl_ops[1][Lock_test], &flk);
#			ifdef FDEBUG
				{ int saverr =errno;
				fprintf(stderr,"fcntl(%d,%d,-) = %d\n",fd,fcntl_ops[1][Lock_test],retval);
				errno=saverr;
				}
#			endif		
			if(retval) {
				flk.l_type = fcntl_ops[0][Lock_exclusive];
				retval = fcntl(fd, fcntl_ops[1][Lock_test], &flk);
#				ifdef FDEBUG
					{ int saverr =errno;
					fprintf(stderr,"fcntl(%d,%d,-) = %d\n",fd,fcntl_ops[1][Lock_test],retval);
					errno=saverr;
					}
#				endif		
				fprintf(stderr,"%d ",retval);fflush(stderr);
				if(retval) {
					retval = 0;
					flk.l_type = F_UNLCK;
				}
			}
		} else {
			retval = fcntl(fd, fcntl_ops[1][mode], &flk);
#			ifdef FDEBUG
				{ int saverr =errno;
				fprintf(stderr,"fcntl(%d,%d,-) = %d\n",fd,fcntl_ops[1][mode],retval);
				errno=saverr;
				}
#			endif		
		}
		
		if((mode & Lock_modemask) == Lock_test) {
			if(retval==0) {
				if( flk.l_type == F_UNLCK ) {
					flk.l_type = Lock_unlock;
				} else if( flk.l_type == F_WRLCK ) {
					flk.l_type = Lock_exclusive;
				} else if( flk.l_type == F_RDLCK ) {
					flk.l_type = Lock_shared;
				}
			}
			if(retflk)
				StructCopy(&flk,retflk,struct flock);
		}
#		ifdef FDEBUG
			if(retval) 
				fprintf(stderr,"V- Err: %s\n",Strerror(errno));
			fprintf(stderr,"Returning %d (%s) from _base_fcntl (l_type=%s)\n",retval,retval_name,mode_name[flk.l_type]);
#		endif		
		
		return retval;
	}
#	else
		croak("fcntl is not supported on this architecture\n");		
#	endif
}

#define param_test(name) (params && \
						  (paramsv=hv_fetch(params,name,strlen(name),0)) && \
						  (SvTRUE(*paramsv)) \
						 )

int
_base_lockfile(filename, mode, shared, shortnames)
char *	filename;
mode_int		mode;
int shared,shortnames;
{
#if 0
#	ifdef FDEBUG
		fprintf(stderr,"Entering _base_lockfile(%s,%s)\n",filename,mode_name[mode]);
		errno=0;
#	endif		
	if((mode & Lock_modemask) == Lock_exclusive) {
		/*FILE * f = fopen(filename,"w");
		fclose(f);*/
		char * wedge = malloc(strlen(filename)+512);
		pid_t pid = getpid();
		time_t t;
		int remote;
		/*int shortnames;*/
		SV ** paramsv;

#	ifdef FDEBUG
		fprintf(stderr,"Locking in _base_lockfile\n");
		errno=0;
#	endif		
		
		remote = shared;/*param_test("shared");
		shortnames = param_test("shortnames");*/

		time(&t);
		
		if(remote) {
			char host[513];
			gethostname(&host[0],512);
			if(!shortnames)
				sprintf(wedge,"%s.%s.%ld.%ld",filename,&host[0],(long)pid,(long)(t%100));
			else {
				unsigned long hash = (long)t ^ (long)pid;
				char * c = &host[0];
				while(*c) 
					hash = hash * 33 + *c++;
				hash %= 1000;
				sprintf(wedge,"%s.%03.03d",filename,(int)hash);
			}
		} else {
			if(!shortnames)
				sprintf(wedge,"%s.%ld",filename,(long)pid);
			else 
				sprintf(wedge,"%s.%03.03d",filename,(int)(pid%1000));
		}
#		ifdef FDEBUG
			fprintf(stderr,"lockfile using wedge `%s'\n",wedge);
#		endif			
		
	} else if(mode == Lock_test) {
		/*RETVAL = stat(filename);*/
	} else if(mode == Lock_unlock) {
		unlink(filename);
	}
#	ifdef FDEBUG
		fprintf(stderr,"Returning from _base_lockfile\n");
#	endif		
#endif	
}



/* A fancy macro that takes care of the return behaviour favoured by the XS
lock functions. If the Lock_test mode was requested and the call was
successful, then one of "u", "w", or "r" will be returned to indicate the
locking state. Otherwise, true or undef is returned to indicate success or
failure. */

#ifdef File_Lock_FDEBUG

#define PUSHResult(result,mode) \
	MACRO_BEGIN \
	if(result==-1)  \
		{PUSHs(sv_mortalcopy(&sv_undef)); fprintf(stderr,"Returning 'undef'\n");}\
	else \
		if(mode==Lock_test) \
			{PUSHs(sv_2mortal(newSVpv("uwrl" + (result&Lock_modemask),1)));fprintf(stderr,"Returning '%c'\n","uwrl"[result&Lock_modemask]);}\
		else \
			{PUSHs(sv_mortalcopy(&sv_yes));fprintf(stderr,"Returning 'yes'\n");}\
	MACRO_END

#else

#define PUSHResult(result,mode) \
	MACRO_BEGIN \
	if(result==-1)  \
		PUSHs(&sv_undef);\
	else \
		if(mode==Lock_test) \
			PUSHs(sv_2mortal(newSVpv("uwrl" + (result&Lock_modemask),1)));\
		else \
			PUSHs(&sv_yes);\
	MACRO_END

#endif
	
#define ReturnResult(result,mode) \
	MACRO_BEGIN \
	EXTEND(sp,1); \
	PUSHResult(result,mode); \
	MACRO_END
		
#define wantarray (GIMME == G_ARRAY)
        

MODULE = File::Lock		PACKAGE = File::Lock

double
constant(name,arg)
	char *		name
	int		arg


int
lockfile(filename, mode=Lock_exclusive|Lock_nonblock,shared=0,shortnames=0)
	char *	filename
	mode_int	mode
	int	shared
	int	shortnames
	CODE:
	{
#		ifdef FDEBUG
			fprintf(stderr,"Entering lockfilef(%s,%s,shared=%d,shortnames=%d)\n",filename,mode_name[mode],shared,shortnames);
#		endif		
		RETVAL = _base_lockfile(filename,mode,shared,shortnames);
	}
	OUTPUT:
	RETVAL

void
fcntl(file, mode=Lock_exclusive|Lock_nonblock, offset=0, whence=SEEK_SET, length=0)
	FILE *	file
	mode_int	mode
	int		offset
	int		whence
	int		length
	PPCODE:
	{
#	ifdef FDEBUG
		fprintf(stderr,"Entering fcntl(%d,%s,%d,%d,%d)\n",fileno(file),mode_name[mode],offset,whence,length);
#	endif		
#	if defined(HAS_FCNTL)
#define YES_FCNTL		
	{
		struct flock retflk;
		int retval;
		retval = _base_fcntl(fileno(file),mode,offset,whence,length, &retflk);
		if(((mode & Lock_modemask) == Lock_test) && (retval!=-1)) {
			if(wantarray) {
#				ifdef HAS_SYSID_IN_FCNTL
					EXTEND(sp, 6);
#				else					
					EXTEND(sp, 5);
#				endif					
#				ifdef FDEBUG
					fprintf(stderr,"Returning (%s,%d,%d,%d,%d",mode_name[retflk.l_type],
							retflk.l_start,retflk.l_whence,retflk.l_len,retflk.l_pid);
#				endif
				PUSHResult(retflk.l_type,mode);
				PUSHs(sv_2mortal(newSViv(retflk.l_start))); 
				PUSHs(sv_2mortal(newSViv(retflk.l_whence))); 
				PUSHs(sv_2mortal(newSViv(retflk.l_len))); 
				PUSHs(sv_2mortal(newSViv(retflk.l_pid))); 
#				ifdef HAS_SYSID_IN_FCNTL
					PUSHs(sv_2mortal(newSViv(retflk.l_sysid))); 
#					ifdef FDEBUG
						fprintf(stderr,",%d",retflk.l_sysid);
#					endif
#				endif				
#				ifdef FDEBUG
					fprintf(stderr,") from fcntl()\n");
#				endif
			
			} else {
				EXTEND(sp,1);
				PUSHResult(retflk.l_type,mode);
			}
		} else {
		   EXTEND(sp,1);
		   PUSHResult(retval,mode);
		}
	}
#	endif
#	if !defined(HAS_FCNTL) && defined(HAS_LOCKF)
#define EMU_FCNTL
	if(((mode & Lock_modemask) == Lock_test) && wantarray) {
		croak("fcntl is emulated on this architecture, and does "
		      "not support testing a lock in an array context\n");
	} else {
		int retval = _base_lockf(fileno(file),mode,offset,whence,length);
		ReturnResult(retval,mode);
	}
#	endif
#	if !defined(HAS_FCNTL) && !defined(HAS_LOCKF)
#define NO_FCNTL		
		croak("fcntl is not supported on this architecture\n");
#	endif				
	}

void
flock(file, mode=Lock_exclusive|Lock_nonblock)
	FILE *	file
	mode_int		mode
	PPCODE:
	{
#	ifdef FDEBUG
		fprintf(stderr,"Entering flock(%d,%s)\n",fileno(file),mode_name[mode]);
#	endif		
#	if defined(HAS_FLOCK)
#define YES_FLOCK		
		ReturnResult(_base_flock(fileno(file),mode),mode);
#	endif
#	if !defined(HAS_FLOCK) && defined(HAS_FCNTL)
#define EMU_FLOCK		
		ReturnResult(_base_fcntl(fileno(file),mode,0,SEEK_SET,0,0),mode);
#	endif
#	if !defined(HAS_FLOCK) && !defined(HAS_FCNTL) && defined(HAS_LOCKF)
#define EMU_FLOCK		
		ReturnResult(_base_lockf(fileno(file),mode,0,SEEK_SET,0),mode);
#	endif
#	if !defined(HAS_FLOCK) && !defined(HAS_FCNTL) && !defined(HAS_LOCKF)
#define NO_FLOCK		
		croak("flock is not supported on this architecture\n");
#	endif				
	}

void
lockf(file, mode=Lock_exclusive|Lock_nonblock, offset=0, whence=SEEK_SET, length=0)
	FILE *	file
	mode_int	mode
	int		offset
	int		whence
	int		length
	PPCODE:
	{
#	ifdef FDEBUG
		fprintf(stderr,"Entering lockf(%d,%s,%d,%d,%d)\n",fileno(file),mode_name[mode],offset,whence,length);
#	endif		
#	if defined(HAS_LOCKF)
#define YES_LOCKF		
		ReturnResult(_base_lockf(fileno(file),mode,offset,whence,length),mode);
#	endif
#	if !defined(HAS_LOCKF) && defined(HAS_FCNTL)
#define EMU_LOCKF		
		ReturnResult(_base_fcntl(fileno(file),mode,offset,whence,length,0),mode);
#	endif
#	if !defined(HAS_LOCKF) && !defined(HAS_FCNTL)
#define NO_LOCKF		
		croak("lockf is not supported on this architecture\n");
#	endif				
	}
	
char *
has_flock()
	CODE:
	{
#	ifdef YES_FLOCK
		RETVAL = "yes";
#	endif				
#	ifdef EMU_FLOCK
		RETVAL = "emulated";
#	endif
#	ifdef NO_FLOCK
		RETVAL = "";
#	endif
#	ifdef FDEBUG
		fprintf(stderr,"Returning `%s' from has_flock()\n",RETVAL);
#	endif		
	}
	OUTPUT:
	RETVAL

char *
has_lockf()
	CODE:
	{
#	ifdef YES_LOCKF
		RETVAL = "yes";
#	endif				
#	ifdef EMU_LOCKF
		RETVAL = "emulated";
#	endif
#	ifdef NO_LOCKF
		RETVAL = "";
#	endif
#	ifdef FDEBUG
		fprintf(stderr,"Returning `%s' from has_lockf()\n",RETVAL);
#	endif		
	}
	OUTPUT:
	RETVAL

char *
has_fcntl()
	CODE:
	{
#	ifdef YES_FCNTL
		RETVAL = "yes";
# endif 
# ifdef EMU_FCNTL
		RETVAL = "emulated";
#	endif
#	ifdef NO_FCNTL
		RETVAL = "";
#	endif
#	ifdef FDEBUG
		fprintf(stderr,"Returning `%s' from has_fcntl()\n",RETVAL);
#	endif		
	}
	OUTPUT:
	RETVAL

char *
has_lockfile()
	CODE:
	{
		RETVAL = "yes";
#	ifdef FDEBUG
		fprintf(stderr,"Returning `%s' from has_lockfile()\n",RETVAL);
#	endif		
	}
	OUTPUT:
	RETVAL

void
_mode(mode)
	mode_int	mode
	PPCODE:
	{
		ReturnResult(mode & Lock_modemask,Lock_test);
	}
	

void
new(class, file, mode=Lock_shared, offset=0, whence=SEEK_SET, length=0)
	SV *	class
	FILE *	file
	mode_int	mode
	int		offset
	int		whence
	int		length
	PPCODE:
	{
#	ifdef FDEBUG
		fprintf(stderr,"Entering new File::Lock(%d,%s,%d,%d,%d)\n",fileno(file),mode_name[mode],offset,whence,length);
#	endif		
	if(((mode & Lock_modemask)== Lock_test) || ((mode & Lock_modemask)==Lock_unlock)) {
		croak("Only exclusive or shared locking modes may be used with new File::Lock.\n");
	}
	{
#	if defined(HAS_FCNTL)
		struct flock retflk;
		int retval;
		retval = _base_fcntl(fileno(file),mode,offset,whence,length, 0);
#	endif
#	if !defined(HAS_FCNTL) && defined(HAS_LOCKF)
		int retval = _base_lockf(fileno(file),mode,offset,whence,length);
#	endif
#	if !defined(HAS_FCNTL) && !defined(HAS_LOCKF)
		croak("fcntl is not supported on this architecture\n");
#	else
		if(retval==0) {
			AV * ary = newAV();
			SV * ref;
			av_push(ary,newRV((SV*)sv_2io(ST(1))));
			av_push(ary,newSViv(offset));
			av_push(ary,newSViv(whence));
			av_push(ary,newSViv(length));
			ref = newRV((SV*)ary);
			sv_bless(ref,gv_stashpv("File::Lock",0));
			EXTEND(sp,1);
			PUSHs(sv_2mortal(ref));
		} else {
			EXTEND(sp,1);
			PUSHs(&sv_undef);
		}
#	endif				
	}
	}

