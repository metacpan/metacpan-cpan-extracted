#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include <sys/types.h>
#include <attr/xattr.h>

static inline int handle2fd(SV *sv)
{
  IO *io;
  return (SvROK(sv) && (io=sv_2io(sv))
	  ? IoDIRP(io) ? my_dirfd(IoDIRP(io)) : PerlIO_fileno(IoIFP(io))
	  : -1);
}

MODULE = Linux::UserXAttr	PACKAGE = Linux::UserXAttr

PROTOTYPES: DISABLE

void
setxattr(handle, name, value, flags=0)
     SV* handle
     char *name
     SV *value
     int flags
  PPCODE:
{
  STRLEN vlen;
  int fd=handle2fd(handle);
  char *vcp;
  vcp=SvPV(value, vlen);

  if( fd>=0 ) {			/* file handle */
    if( !fsetxattr(fd, name, vcp, vlen, flags) ) {
      mPUSHi(1);
    }
  } else {			/* file name */
    STRLEN len;
    char *cp=SvPV(handle, len);
    char path[len+1];
    memcpy(path, cp, len);
    path[len]=0;
    if( !setxattr(path, name, vcp, vlen, flags) ) {
      mPUSHi(1);
    }
  }
}

void
getxattr(handle, name)
     SV* handle
     char *name
  PPCODE:
{
  int fd=handle2fd(handle);
  char buf[4096];
  ssize_t rc;

  errno=0;
  if( fd>=0 ) {
    if( (rc=fgetxattr(fd, name, buf, sizeof(buf)))>=0 ) {
      if(errno==ERANGE && rc>sizeof(buf)) {
	char buf2[rc+1];
	if( (rc=fgetxattr(fd, name, buf2, rc))>=0 ) {
	  mPUSHs(newSVpvn(buf2, rc));
	}
      } else {
	mPUSHs(newSVpvn(buf, rc));
      }
    }
  } else {			/* file name */
    STRLEN len;
    char *cp=SvPV(handle, len);
    char path[len+1];
    memcpy(path, cp, len);
    path[len]=0;
    if( (rc=getxattr(path, name, buf, sizeof(buf)))>=0 ) {
      if(errno==ERANGE && rc>sizeof(buf)) {
	char buf2[rc+1];
	if( (rc=getxattr(path, name, buf2, rc))>=0 ) {
	  mPUSHs(newSVpvn(buf2, rc));
	}
      } else {
	mPUSHs(newSVpvn(buf, rc));
      }
    }
  }
}

void
listxattr(handle)
     SV* handle
  PPCODE:
{
  int fd=handle2fd(handle);
  char buf[4096];
  ssize_t rc;

  errno=0;
  if( fd>=0 ) {
    if( (rc=flistxattr(fd, buf, sizeof(buf)))>=0 ) {
      if(errno==ERANGE && rc>sizeof(buf)) {
	char buf2[rc];
	if( (rc=flistxattr(fd, buf2, rc))>=0 ) {
	  char *cp=buf2;
	  while( cp<buf2+rc ) {
	    int len=strlen(cp);
	    mXPUSHs(newSVpvn(cp, len));
	    cp+=len+1;
	  }
	}
      } else {
	char *cp=buf;
	while( cp<buf+rc ) {
	  int len=strlen(cp);
	  mXPUSHs(newSVpvn(cp, len));
	  cp+=len+1;
	}
      }
    }
  } else {			/* file name */
    STRLEN len;
    char *cp=SvPV(handle, len);
    char path[len+1];
    memcpy(path, cp, len);
    path[len]=0;
    if( (rc=listxattr(path, buf, sizeof(buf)))>=0 ) {
      if(errno==ERANGE && rc>sizeof(buf)) {
	char buf2[rc];
	if( (rc=listxattr(path, buf2, rc))>=0 ) {
	  char *cp=buf2;
	  while( cp<buf2+rc ) {
	    int len=strlen(cp);
	    mXPUSHs(newSVpvn(cp, len));
	    cp+=len+1;
	  }
	}
      } else {
	char *cp=buf;
	while( cp<buf+rc ) {
	  int len=strlen(cp);
	  mXPUSHs(newSVpvn(cp, len));
	  cp+=len+1;
	}
      }
    }
  }
}

void
removexattr(handle, name)
     SV* handle
     char *name
  PPCODE:
{
  int fd=handle2fd(handle);

  if( fd>=0 ) {
    if( !fremovexattr(fd, name) ) {
      mPUSHi(1);
    }
  } else {			/* file name */
    STRLEN len;
    char *cp=SvPV(handle, len);
    char path[len+1];
    memcpy(path, cp, len);
    path[len]=0;
    if( !removexattr(path, name) ) {
      mPUSHi(1);
    }
  }
}

void
lsetxattr(path, name, value, flags=0)
     char *path
     char *name
     SV *value
     int flags
  PPCODE:
{
  STRLEN len;
  char *cp=SvPV(value, len);
  if( !lsetxattr(path, name, cp, len, flags) ) {
    mPUSHi(1);
  }
}

void
lgetxattr(path, name)
     char *path
     char *name
  PPCODE:
{
  char buf[4096];
  ssize_t rc;

  errno=0;
  if( (rc=lgetxattr(path, name, buf, sizeof(buf)))>=0 ) {
    if(errno==ERANGE && rc>sizeof(buf)) {
      char buf2[rc+1];
      if( (rc=lgetxattr(path, name, buf2, rc))>=0 ) {
	mPUSHs(newSVpvn(buf2, rc));
      }
    } else {
      mPUSHs(newSVpvn(buf, rc));
    }
  }
}

void
lremovexattr(path, name)
     char *path
     char *name
  PPCODE:
{
  if( !lremovexattr(path, name) ) {
    mPUSHi(1);
  }
}

void
llistxattr(path)
     char *path
  PPCODE:
{
  char buf[4096];
  ssize_t rc;

  errno=0;
  if( (rc=llistxattr(path, buf, sizeof(buf)))>=0 ) {
    if(errno==ERANGE && rc>sizeof(buf)) {
      char buf2[rc];
      if( (rc=llistxattr(path, buf2, rc))>=0 ) {
	char *cp=buf2;
	while( cp<buf2+rc ) {
	  int len=strlen(cp);
	  mXPUSHs(newSVpvn(cp, len));
	  cp+=len+1;
	}
      }
    } else {
      char *cp=buf;
      while( cp<buf+rc ) {
	int len=strlen(cp);
	mXPUSHs(newSVpvn(cp, len));
	cp+=len+1;
      }
    }
  }
}

BOOT:
{
  HV *stash=gv_stashpv ("Linux::UserXAttr", 0);
  newCONSTSUB(stash, "XATTR_CREATE",  newSViv (XATTR_CREATE));
  newCONSTSUB(stash, "XATTR_REPLACE", newSViv (XATTR_REPLACE));
}

## Local Variables: ##
## mode: c ##
## End: ##
