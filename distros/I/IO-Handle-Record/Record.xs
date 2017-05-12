#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <limits.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/resource.h>
#include <fcntl.h>

#ifndef PerlIO
#define PerlIO_fileno(f) fileno(f)
#endif

static int
fdtype(int fd) {
  struct stat buf;
  if( fstat(fd, &buf)<0 ) return -1;
  return (buf.st_mode & S_IFMT);
}

static int
socket_family(int fd) {
  union {
    struct sockaddr sa;
    char data[PATH_MAX+sizeof(uint8_t)+sizeof(sa_family_t)];
  } un;
  socklen_t len;

  len=sizeof(un);
  if( getsockname(fd, &un.sa, &len)<0 ) return -1;
  return un.sa.sa_family;
}

static int
socket_type(int fd) {
  int type;
  int len=sizeof(type);
  if(fdtype(fd)!=S_IFSOCK) return -1;
  if( getsockopt(fd, SOL_SOCKET, SO_TYPE, (void*)&type, (void*)&len)<0 )
    return -1;
  return type;
}

# define FDS_KEY "IO::Handle::Record::fds_to_send"
static int
smsg(SV* stream, SV* buffer, SV* length, int offset, int flags) {
  struct msghdr msg;
  struct cmsghdr* cmsgp;
  struct iovec  iov[1];
  STRLEN blen;
  char* bufp;
  int i, ret=-1;
  SV **svp, *sv;
  AV *fd_av;
  int fd_av_len, send_fd;
  IO* io;

  bufp=SvPV(buffer, blen);
  if( offset<0 ) {
    if( -offset>blen ) croak("Offset outside string");
    offset+=blen;
  } else if( offset>=blen && blen>0 ) croak("Offset outside string");
  bufp+=offset;
  blen-=offset;

  if( SvOK(length) ) {
    IV l=SvIV(length);
    if( l<0 ) croak("Negative length");
    if( l<blen ) blen=l;
  }

  Zero(&msg, 1, struct msghdr);
  Zero(iov,  1, struct iovec);

  iov[0].iov_base=bufp;
  iov[0].iov_len=blen;

  msg.msg_iov=iov;
  msg.msg_iovlen=1;

  SETERRNO(0,0);
  if( SvROK(stream) &&
      (sv=SvRV(stream)) &&
      SvTYPE(sv)==SVt_PVGV &&
      (io=GvIO(sv)) &&
      IoIFP(io) ) {
    send_fd=PerlIO_fileno(IoIFP(io));
    
    svp=hv_fetch(GvHV(sv), FDS_KEY, sizeof(FDS_KEY)-1, FALSE);
    if( svp && SvROK(*svp) &&
	(fd_av=(AV*)SvRV(*svp)) &&
	SvTYPE(fd_av)==SVt_PVAV &&
	(fd_av_len=av_len(fd_av)+1)>0 ) {
      /* warn("--> sending %d fds", fd_av_len); */
      msg.msg_controllen=CMSG_SPACE(fd_av_len*sizeof(int));
      Newxz(msg.msg_control, msg.msg_controllen, char);
      cmsgp=CMSG_FIRSTHDR(&msg);
      cmsgp->cmsg_len=CMSG_LEN(fd_av_len*sizeof(int));
      cmsgp->cmsg_level=SOL_SOCKET;
      cmsgp->cmsg_type=SCM_RIGHTS;
      for( i=0; i<fd_av_len; i++ ) {
	svp=av_fetch(fd_av, i, FALSE);
	if( SvIOK(*svp) ) {	/* file descriptor */
	  ((int*)CMSG_DATA(cmsgp))[i]=SvIV(*svp);
	} else if( SvROK(*svp) &&  /* file handle */
		   (sv=SvRV(*svp)) &&
		   SvTYPE(sv)==SVt_PVGV &&
		   (io=GvIO(sv)) &&
		   IoIFP(io) ) {
	  ((int*)CMSG_DATA(cmsgp))[i]=PerlIO_fileno(IoIFP(io));
	} else {
	  SETERRNO(EBADF, RMS_IFI);
	  goto ret;
	}
      }

      ret=sendmsg(send_fd, &msg, flags);

      if( ret>0 ) {		/* data sent ==> clear fds_to_send */
	/* warn("--> clearing fds_to_send"); */
	av_undef(fd_av);
      }
    } else {
      ret=sendmsg(send_fd, &msg, flags);
    }

    /* warn("--> sending data chunk: controllen=%d, ret=%d", msg.msg_controllen, ret); */
  } else {
    SETERRNO(EBADF, RMS_IFI);
  }

 ret:
  if( msg.msg_control ) Safefree(msg.msg_control);
  return ret;
}

static SV*
call_open_fd( int fd ) {
  int n, socktype;
  SV *ret=NULL;
  dSP;

  ENTER;
  SAVETMPS;

  PUSHMARK(sp);
  XPUSHs(sv_2mortal(newSViv(fd)));
  XPUSHs(sv_2mortal(newSViv(fcntl(fd, F_GETFL, 0))));
  if( (socktype=socket_type(fd))>=0 )
    XPUSHs(sv_2mortal(newSViv(socktype)));
  PUTBACK;

  n=call_pv("open_fd", G_SCALAR | G_EVAL);

  SPAGAIN;

  if( n==1 ) {
    ret=POPs;
    (void)SvREFCNT_inc(ret);
  }

  PUTBACK;
  FREETMPS;
  LEAVE;

  return ret;
}

# define RCV_KEY "IO::Handle::Record::_received_fds"
static int
rmsg(SV* stream, SV* buffer, int length, int offset, int flags) {
  struct msghdr msg;
  struct cmsghdr* cmsgp;
  struct iovec  iov[1];
  struct rlimit rlim;
  STRLEN blen;
  int i, ret=-1, nfds, *fdp;
  SV *sv, **svp;
  AV *fd_av;
  IO* io;

  if( !SvOK(buffer) ) sv_setpvn(buffer, "", 0);
  if( length<0 ) croak("Negative length");

  SvPV_force(buffer, blen);

  if( offset<0 ) {
    if( -offset>(int)blen ) croak("Offset outside string");
    offset+=blen;
  }

  SvGROW(buffer, length+1);

  /* pad with \0 if offset > size of the buffer */
  if( offset>SvCUR(buffer) ) Zero(SvEND(buffer), offset-SvCUR(buffer), char);

  Zero(&msg, 1, struct msghdr);
  Zero(iov,  1, struct iovec);

  iov[0].iov_base=SvPVX(buffer)+offset;
  iov[0].iov_len=length;

  msg.msg_iov=iov;
  msg.msg_iovlen=1;

  if( getrlimit( RLIMIT_NOFILE, &rlim )<0 ) {
    rlim.rlim_cur=1024;
  }

  msg.msg_controllen=CMSG_SPACE(rlim.rlim_cur*sizeof(int));
  Newxz(msg.msg_control, msg.msg_controllen, char);

  SETERRNO(0,0);
  if( SvROK(stream) &&
      (sv=SvRV(stream)) &&
      SvTYPE(sv)==SVt_PVGV &&
      (io=GvIO(sv)) &&
      IoIFP(io) ) {
    if( (ret=recvmsg(PerlIO_fileno(IoIFP(io)), &msg, flags))<0 ) goto ret;

    SvCUR_set(buffer, ret+offset);
    *SvEND(buffer)='\0';
    SvPOK_only(buffer);

    if( (cmsgp=CMSG_FIRSTHDR(&msg))!=NULL &&
	cmsgp->cmsg_len>0 &&
	cmsgp->cmsg_level==SOL_SOCKET &&
	cmsgp->cmsg_type==SCM_RIGHTS ) {
      fdp=(int*)CMSG_DATA(cmsgp);
      nfds=(cmsgp->cmsg_len-
	    ((char*)fdp-(char*)cmsgp))/sizeof(int);
      /* warn("==> expecting %d fds -- got %d bytes, %d fds", rlim.rlim_cur, ret, nfds); */
      if( nfds>0 ) {
	/* sv is the typeglob of the filehandle here */
	svp=hv_fetch(GvHV(sv), RCV_KEY, sizeof(RCV_KEY)-1, FALSE);
	if( !(svp && SvROK(*svp) &&
	      (fd_av=(AV*)SvRV(*svp)) &&
	      SvTYPE(fd_av)==SVt_PVAV) ) {
	  /*
	   * ${*$I}{RCV_KEY}=[]
	   *   unless exists ${*$I}{RCV_KEY} and
	   *          ref(${*$I}{RCV_KEY}) eq 'ARRAY'
	   */
	  (void)hv_store(GvHV(sv), RCV_KEY, sizeof(RCV_KEY)-1,
			 newRV_inc((SV*)(fd_av=newAV())), 0);
	}
	av_extend(fd_av, av_len(fd_av)+1+nfds);
	    
	for( i=0; i<nfds; i++ ) {
	  sv=call_open_fd(fdp[i]);
	  if( sv ) av_push(fd_av, sv);
	}
      }
/*     } else { */
/*       warn("==> expecting %d fds -- got %d bytes, no CMSG", rlim.rlim_cur, ret); */
    }
  } else {
    SETERRNO(EBADF, RMS_IFI);
  }

 ret:
  if( msg.msg_control ) Safefree(msg.msg_control);
  return ret;
}

MODULE = IO::Handle::Record    PACKAGE = IO::Handle::Record   PREFIX = smh_

void
smh_peercred(s)
    PerlIO* s;
PROTOTYPE: $
PPCODE:
{
# ifdef SO_PEERCRED
  struct ucred uc;
  socklen_t uc_len=sizeof(uc);

  if( !getsockopt(PerlIO_fileno(s), SOL_SOCKET, SO_PEERCRED, &uc, &uc_len) ) {
    EXTEND(SP, 3);
    PUSHs(sv_2mortal(newSViv(uc.pid)));
    PUSHs(sv_2mortal(newSViv(uc.uid)));
    PUSHs(sv_2mortal(newSViv(uc.gid)));
  }
# else
  SETERRNO(EOPNOTSUPP, RMS_IFI);
# endif
}

void
smh_issock(s)
    PerlIO* s;
PROTOTYPE: $
PPCODE:
{
  if( fdtype(PerlIO_fileno(s))==S_IFSOCK ) {
    XSRETURN_YES;
  } else {
    XSRETURN_UNDEF;
  }
}

char *
smh_typeof(fd)
    int fd;
PROTOTYPE: $
CODE:
{
  switch(fdtype(fd)) {
  case S_IFSOCK:
    switch(socket_family(fd)) {
    case AF_UNIX:
      RETVAL=("IO::Socket::UNIX");
      break;
    case AF_INET:
      RETVAL=("IO::Socket::INET");
      break;
    case AF_INET6:
      RETVAL=("IO::Socket::INET6");
      break;
    default:
      RETVAL=("IO::Handle");
      break;
    }
    break;
  case S_IFREG:
    RETVAL=("IO::File");
    break;
  case S_IFDIR:
    RETVAL=("IO::Dir");
    break;
  case S_IFIFO:
    RETVAL=("IO::Pipe");
    break;
  default:
    RETVAL=("IO::Handle");
    break;
  }
}
OUTPUT:
RETVAL

int
smh_socket_type(s)
    int s;

    PROTOTYPE: $
    CODE:
    RETVAL=socket_type(s);
    
    OUTPUT:
    RETVAL

int
smh_socket_family(s)
    int s;

    PROTOTYPE: $
    CODE:
    RETVAL=socket_family(s);
    
    OUTPUT:
    RETVAL

int
smh_sendmsg(s, buf, len = &PL_sv_undef, offset = 0, flags = 0)
      SV* s;
      SV* buf;
      SV* len;
      int offset;
      int flags;

    PROTOTYPE: $$;$$$
    CODE:
    if ((RETVAL = smsg(s, buf, len, offset, flags)) < 0 ) 
      XSRETURN_UNDEF;
    
    OUTPUT:
    RETVAL

int
smh_recvmsg(s, buf, len, offset = 0, flags = 0)
      SV* s;
      SV* buf;
      int len;
      int offset;
      int flags;

    PROTOTYPE: $$$;$$
    CODE:
    if ((RETVAL = rmsg(s, buf, len, offset, flags)) < 0 ) 
      XSRETURN_UNDEF;
    
    OUTPUT:
    RETVAL

 # Local Variables:
 # mode: c
 # End:
