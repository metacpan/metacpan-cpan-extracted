#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "const-c.inc"
#include <fcntl.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <stdio.h>
#include <unistd.h>
#include <poll.h>

#include <sys/time.h>

#if defined(IO_FD_OS_DARWIN) || defined(IO_FD_OS_BSD)
#include <sys/event.h>
#include <sys/uio.h>
#include <sys/types.h>


#endif

#if defined(IO_FD_OS_LINUX)
#include <sys/sendfile.h>
#endif

#include <sys/stat.h>

#if defined(IO_FD_OS_DARWIN)
//Make up constants for manipulating accept4, socketpair, and socket
#define SOCK_NONBLOCK 0x10000000
#define SOCK_CLOEXEC  0x20000000
#endif

//Read from an fd until eof or error condition
//Returns SV containing all the data
// AKA "slurp";
SV * slurp(pTHX_ int fd, int read_size){
	SV* buffer;
	char *buf;
	int ret;
	int len=0;
	buffer=newSV(read_size);
	
	do {
		SvGROW(buffer, len+read_size);	//Grow the buffer if required
		buf=SvPVX(buffer);		//Get pointer to memory.. 
		ret=read(fd, buf+len, read_size);	//Do the read,offset to current traked len

		if(ret>=0){
			len+=ret;		//track total length
			buf=SvPVX(buffer);
			buf[len]='\0';		//Add null for shits and giggles
		}
		else{
			//break;
			//fprintf(stderr, "ERROR IN slurp\n");
			return &PL_sv_undef;
		}

	}
	while(ret>0);

	SvPOK_on(buffer);	//Make it a string
	SvCUR_set(buffer,len);	//Set the length
	sv_2mortal(buffer);	//Decrement ref count
	return buffer;
}


	SV *accept_multiple_next_addr;
	struct sockaddr *accept_multiple_next_buf;

  SV *max_file_desc;

#if defined(IO_FD_OS_DARWIN)|| defined(IO_FD_OS_BSD)
#define IO_FD_ATIME atime=buf.st_atimespec.tv_sec+buf.st_atimespec.tv_nsec*1e-9;
#define IO_FD_MTIME mtime=buf.st_mtimespec.tv_sec+buf.st_mtimespec.tv_nsec*1e-9;
#define IO_FD_CTIME ctime=buf.st_ctimespec.tv_sec+buf.st_ctimespec.tv_nsec*1e-9;
#endif

#if defined(IO_FD_OS_LINUX)
#define IO_FD_ATIME atime=buf.st_atim.tv_sec+buf.st_atim.tv_nsec*1e-9;
#define IO_FD_MTIME mtime=buf.st_mtim.tv_sec+buf.st_mtim.tv_nsec*1e-9;
#define IO_FD_CTIME ctime=buf.st_ctim.tv_sec+buf.st_ctim.tv_nsec*1e-9;
#endif

#if defined(IO_FD_OS_DARWIN)
#define KEVENT kevent64
#define KEVENT_S struct kevent64_s
#endif
#if defined(IO_FD_OS_BSD)
#define KEVENT kevent
#define KEVENT_S struct kevent
#endif

#define ADJUST_SOCKADDR_SIZE(addr) \
	struct sockaddr * a=(struct sockaddr *)SvPVX(addr);\
	switch(a->sa_family){\
		case AF_INET:\
			SvCUR_set(addr, sizeof(struct sockaddr_in));\
			break;\
		case AF_INET6:\
			SvCUR_set(addr, sizeof(struct sockaddr_in6));\
			break;\
		case AF_UNIX:\
			SvCUR_set(addr, sizeof(struct sockaddr_un));\
			break;\
		default:\
			break;\
	}\




MODULE = IO::FD		PACKAGE = IO::FD		

INCLUDE: const-xs.inc

BOOT:

	//boot strap the mutliple accept buffer
	accept_multiple_next_addr=newSV(sizeof(struct sockaddr_storage));
	accept_multiple_next_buf=(struct sockaddr *)SvPVX(accept_multiple_next_addr);

  //locate the $^F variable 
  //max_file_desc=get_sv("^F",0);

#SOCKET
#######

#TODO: 
#Allow a string af, which is actually sockaddr structure
#Extract out the family, Saves a step
SV* 
socket(sock,af,type,proto)
		SV* sock;
		int af
		int type
		int proto

		PREINIT:
			int fd;
			int s;
		CODE:
      if(SvREADONLY(sock)){
            Perl_croak(aTHX_ "%s", PL_no_modify);
      }
			s=socket(af, type, proto);

			//Set error variable...
			if(s<0){
				
				RETVAL=&PL_sv_undef;
				#need to set error code here
			}
			else{
        if(s>PL_maxsysfd){
          fcntl(s, F_SETFD, FD_CLOEXEC);
        }
				RETVAL=newSViv(s);
				if(SvOK(sock)){
					sv_setiv(sock,s);
				}
				else {
					sock=newSViv(s);
				}
			}

		OUTPUT:
			RETVAL
			sock

#LISTEN
#######


SV *
listen(listener,backlog)
	SV * listener;
	int backlog;


	INIT:
		int ret;

	PPCODE:
    if(SvOK(listener) && SvIOK(listener)){
		ret=listen(SvIV(listener), backlog);

		if(ret<0){
			//RETVAL=&PL_sv_undef;
      XSRETURN_UNDEF;
		}
		else{
		  //RETVAL=newSViv(ret+1);
      XSRETURN_IV(ret+1);
		}
  }
  else{
        Perl_warn(aTHX_ "%s", "IO::FD::listen called with something other than a file descriptor");
        errno=EBADF;
        XSRETURN_UNDEF;
  }


#ACCEPT
#######

SV*
accept(new_fd, listen_fd)
  SV* new_fd
  SV* listen_fd

  PREINIT:
      struct sockaddr *packed_addr;
      int ret;
			SV *addr=newSV(sizeof(struct sockaddr_storage));
			struct sockaddr *buf=(struct sockaddr *)SvPVX(addr);
			unsigned int len=sizeof(struct sockaddr_storage);

			

  CODE:
    if(SvOK(listen_fd)&& SvIOK(listen_fd)){
      if(SvREADONLY(new_fd)){
            Perl_croak(aTHX_ "%s", PL_no_modify);
      }
      ret=accept(SvIV(listen_fd), buf, &len);
      if(ret<0){
        RETVAL=&PL_sv_undef;
      }
      else {
        if(ret>PL_maxsysfd){
          fcntl(ret, F_SETFD, FD_CLOEXEC);
        }
        SvPOK_on(addr);
        //SvCUR_set(addr, sizeof(struct sockaddr_storage));
        ADJUST_SOCKADDR_SIZE(addr);
        RETVAL=addr;
        if(SvOK(new_fd)){
          sv_setiv(new_fd, ret);		
        }
        else{
          new_fd=newSViv(ret);
        }
        //Adjust the current size of the buffer based on socket family
      }
    }
    else {
        errno=EBADF;
        RETVAL=&PL_sv_undef;
        Perl_warn(aTHX_ "%s", "IO::FD::accept called with something other than a file descriptor");
    }
	
	
  OUTPUT:
    RETVAL
    new_fd

SV *
accept4(new_fd, listen_fd, flags)
  SV *new_fd
  SV *listen_fd
  UV flags

  INIT:
      struct sockaddr *packed_addr;
      int ret;
      int ret2;
			SV *addr=newSV(sizeof(struct sockaddr_storage));
			struct sockaddr *buf=(struct sockaddr *)SvPVX(addr);
			unsigned int len=sizeof(struct sockaddr_storage);

  CODE:
    if(SvOK(listen_fd) && SvIOK(listen_fd)){
      if(SvREADONLY(new_fd)){
            Perl_croak(aTHX_ "%s", PL_no_modify);
      }
#if defined(IO_FD_OS_LINUX)
      ret=accept4(SvIV(listen_fd), buf, &len, flags);
#endif
#if defined(IO_FD_OS_DARWIN) || defined(IO_FD_OS_BSD)
      ret=accept(SvIV(listen_fd), buf, &len);
      if(ret<0){
        RETVAL=&PL_sv_undef;
      }
      else {
        if(SOCK_NONBLOCK & flags){
          //Assumes no other status flags are set
          fcntl(ret, F_SETFL, O_NONBLOCK);
        }
        if(SOCK_CLOEXEC & flags){
          fcntl(ret, F_SETFD, FD_CLOEXEC);
        }
	}
#endif
        if(ret<0){
          RETVAL=&PL_sv_undef;
        }
        else {
          SvPOK_on(addr);
          ADJUST_SOCKADDR_SIZE(addr);
          RETVAL=addr;
          if(SvOK(new_fd)){
            sv_setiv(new_fd, ret);		
          }
          else{
            new_fd=newSViv(ret);
          }
          //mXPUSHs(addr);
          //XSRETURN(1);
        }
    }
    else{
        errno=EBADF;
        RETVAL=&PL_sv_undef;
        Perl_warn(aTHX_ "%s", "IO::FD::accept4 called with something other than a file descriptor");
    }

  OUTPUT:
    RETVAL
    new_fd


SV*
accept_multiple(new_fds, peers, listen_fd)
	AV* new_fds
	AV* peers
	SV* listen_fd
	PROTOTYPE:\@\@$

	INIT:
		struct sockaddr *packed_addr;
		int ret;
		SV *new_fd=NULL;
		unsigned int len=sizeof(struct sockaddr_storage);

		int count=0;
#if defined(IO_FD_OS_LINUX) 
		int flags;
#endif



	PPCODE:

    if(SvOK(listen_fd) && SvIOK(listen_fd)){
#if defined(IO_FD_OS_LINUX) 
		while((ret=accept4(SvIV(listen_fd),accept_multiple_next_buf, &len,SOCK_NONBLOCK))>=0){
			//fcntl(ret, F_SETFL, O_NONBLOCK);
#endif
#if defined(IO_FD_OS_DARWIN)  || defined(IO_FD_OS_BSD)
		while((ret=accept(SvIV(listen_fd),accept_multiple_next_buf, &len))>=0){
#endif
      if(ret>PL_maxsysfd){
        fcntl(ret, F_SETFD, FD_CLOEXEC);
      }
			SvPOK_on(accept_multiple_next_addr);
			SvCUR_set(accept_multiple_next_addr, sizeof(struct sockaddr_storage));

			new_fd=newSViv(ret);
			av_push(new_fds, new_fd);
			av_push(peers,accept_multiple_next_addr);
			count++;
			ADJUST_SOCKADDR_SIZE(accept_multiple_next_addr);

			//Allocate a buffer for next attempt. Could be another call
			accept_multiple_next_addr=newSV(sizeof(struct sockaddr_storage));
			accept_multiple_next_buf=(struct sockaddr *)SvPVX(accept_multiple_next_addr);
		}	
		//If new_fd is still null, we failed all to gether
		mXPUSHs((new_fd==NULL) ?&PL_sv_undef :newSViv(count));
		XSRETURN(1);
    }
    else{

        errno=EBADF;
        Perl_warn(aTHX_ "%s", "IO::FD::accept_multiple called with something other than a file descriptor");
        XSRETURN_UNDEF;
    }



#CONNECT
########

SV*
connect(fd, address)
	SV* fd
	SV *address

	PREINIT:
		int ret;
		int len;//=SvOK(address)?SvCUR(address):0;
		struct sockaddr *addr;//=(struct sockaddr *)SvPVX(address);

	CODE:
    if(SvOK(fd) &&SvIOK(fd)){
      if(SvOK(address)){
        len=SvOK(address)?SvCUR(address):0;
        addr=(struct sockaddr *)SvPVX(address);
      }
      else {
        addr=NULL;
        len=0;
      }
      ret=connect(SvIVX(fd),addr,len);
      //fprintf(stderr,"CONNECT: %d\n",ret);
      if(ret<0){
        RETVAL=&PL_sv_undef;	
      }
      else{
        RETVAL=newSViv(ret+1);
      }
    }
    else{
        errno=EBADF;
        Perl_warn(aTHX_ "%s", "IO::FD::connect called with something other than a file descriptor");
        RETVAL=&PL_sv_undef;	
    }

	OUTPUT:
		RETVAL
	
#SOCKATMARK
##########
SV*
sockatmark(fd)
	SV *fd;
	INIT:
		int ret;
	PPCODE:
		if(SvOK(fd)&&SvIOK(fd)){
			ret=sockatmark(SvIV(fd));
			if(ret<0){
				XSRETURN_UNDEF;
			}
			else{
				XSRETURN_IV(ret);
			}

		}
		else{
      errno=EBADF;
      Perl_warn(aTHX_ "%s", "IO::FD::sockatmark called with something other than a file descriptor");
			XSRETURN_UNDEF;
		}
		
#SYSOPEN
########

SV*
sysopen(fd, path, mode, ... )
 		SV* fd
    char *path
    int mode

		PREINIT:
			int f;
      int permissions=0666;	//Default if not provided

		CODE:
      if(SvREADONLY(fd)){
        Perl_croak(aTHX_ "%s", PL_no_modify);
      }
			if(items==4){
				permissions=SvIV(ST(3));
			}
			f=open(path, mode, permissions);
			if(f<0){
				RETVAL=&PL_sv_undef;
			}
			else{
        if(f>PL_maxsysfd){
          fcntl(f, F_SETFD, FD_CLOEXEC);
        }
				RETVAL=newSViv(f);
				if(SvOK(fd)){
					sv_setiv(fd,f);
				}
				else {
					fd= newSViv(f);
				}
			}

		OUTPUT:
			RETVAL
			fd


SV*
sysopen4(fd, path, mode, permissions)
 		SV *fd
    char *path
    int mode
    int permissions

		PREINIT:
			int f;

		CODE:
      if(SvREADONLY(fd)){
        Perl_croak(aTHX_ "%s", PL_no_modify);
      }
			f=open(path, mode, permissions);
			if(fd<0){
				RETVAL=&PL_sv_undef;
			}
			else{
        if(f>PL_maxsysfd){
          fcntl(f, F_SETFD, FD_CLOEXEC);
        }
				RETVAL=newSViv(f);
				if(SvOK(fd)){
					sv_setiv(fd,f);
				}
				else {
					fd= newSViv(f);
				}
			}

		OUTPUT:
			RETVAL
			fd

#CLOSE
######

SV*
close(fd)
	SV* fd;

	INIT:
		int ret;

	CODE:
    if(SvOK(fd) && SvIOK(fd)){
      ret=close(SvIV(fd));
      if(ret<0){
        RETVAL=&PL_sv_undef;
      }
      else{
#close returns 0 on success.. which is false in perl 
#so increment
        RETVAL=newSViv(ret+1);
      }
    }
    else {
      errno=EBADF;
      RETVAL=&PL_sv_undef;
      Perl_warn(aTHX_ "%s", "IO::FD::close called with something other than a file descriptor");
    }
	OUTPUT:
		RETVAL



#SYSREAD
########

SV*
sysread(fd, data, len, ...)
    SV* fd;
    SV* data
		int len
		INIT:
			int ret;
			char *buf;
			int offset=0;

    PPCODE:
			//TODO: allow unspecified len and offset

			//grow scalar to fit potental read
      if(SvOK(fd) && SvIOK(fd)){
        if(SvREADONLY(data)){
            Perl_croak(aTHX_ "%s", PL_no_modify);
        }
        if(items >=4 ){
          //len=SvIOK(ST(2))?SvIV(ST(2)):0;
          offset=SvIOK(ST(3))?SvIV(ST(3)):0;
        }

        int data_len=sv_len(data);
        int request_len;
        if(offset<0){
          offset=data_len-offset;
        }
        else{

        }
        request_len=len+offset;

        //fprintf(stderr, "Length of buffer is: %d\n", data_len);
        //fprintf(stderr, "Length of request is: %d\n", request_len);

        buf = SvPOK(data) ? SvGROW(data, request_len+1) : 0;

        data_len=sv_len(data);
        //fprintf(stderr, "Length of buffer is: %d\n", data_len);
        //TODO: fill with nulls if offset past end of original data

        buf+=offset;

        ret=read(SvIV(fd), buf, len);
        if(ret<0){

          //RETVAL=&PL_sv_undef;
          XSRETURN_UNDEF;
        }
        else {
          buf[ret]='\0';
          SvCUR_set(data,ret+offset);
          //RETVAL=newSViv(ret);
          mXPUSHs(newSViv(ret));
          XSRETURN(1);
        }
      }
      else{
        errno=EBADF;
        Perl_warn(aTHX_ "%s", "IO::FD::sysread called with something other than a file descriptor");
        XSRETURN_UNDEF;
      }


SV*
sysread3(fd, data, len)
		SV *fd;
		SV* data
		int len

		INIT:
			int ret;
			char *buf;
			int offset;

		PPCODE:
    if(SvOK(fd) &&SvIOK(fd)){
      if(SvREADONLY(data)){
        Perl_croak(aTHX_ "%s", PL_no_modify);
      }
			int data_len=SvCUR(data);

			//fprintf(stderr, "Length of buffer is: %d\n", data_len);
			//fprintf(stderr, "Length of request is: %d\n",len);

			buf = SvPOK(data) ? SvGROW(data,len+1) : 0;

			//data_len=SvPVX(data);
			//fprintf(stderr, "Length of buffer is: %d\n", data_len);


			ret=read(SvIV(fd), buf, len);
			if(ret<0){

				//RETVAL=&PL_sv_undef;
        XSRETURN_UNDEF;
			}
			else {
				buf[ret]='\0';
				SvCUR_set(data,ret);
        mXPUSHs(newSViv(ret));
        XSRETURN(1);
				//RETVAL=newSViv(ret);
			}
      }

      else {
        errno=EBADF;
        Perl_warn(aTHX_ "%s", "IO::FD::sysread called with something other than a file descriptor");
        XSRETURN_UNDEF;
      }


SV*
sysread4(fd, data, len, offset)
    SV* fd;
    SV* data
    int len
		int offset

		INIT:
			int ret;
			char *buf;

      PPCODE:
      if(SvOK(fd) &&SvIOK(fd)){
        if(SvREADONLY(data)){
          Perl_croak(aTHX_ "%s", PL_no_modify);
        }

#grow scalar to fit potental read
        int data_len=sv_len(data);
        int request_len;
        if(offset<0){
          offset=data_len-offset;
        }
        else{

        }
        request_len=len+offset;


        buf = SvPOK(data) ? SvGROW(data, request_len+1) : 0;

        data_len=sv_len(data);

        buf+=offset;

        ret=read(SvIV(fd), buf, len);
        if(ret<0){

          //RETVAL=&PL_sv_undef;
          XSRETURN_UNDEF;
        }
        else {
          buf[ret]='\0';
          SvCUR_set(data,ret+offset);
          //RETVAL=newSViv(ret);
          mXPUSHs(newSViv(ret));
          XSRETURN(1);
        }
      }
      else {
        errno=EBADF;
        Perl_warn(aTHX_ "%s", "IO::FD::sysread called with something other than a file descriptor");
        XSRETURN_UNDEF;
      }

#SYSWRITE 
##########

SV*
syswrite(fd,data, ...)
	SV *fd
	SV* data

	INIT:
		int ret;
		char *buf;
		STRLEN max;//=SvCUR(data);
		int len;
		int offset;
	PPCODE:
    if(!SvOK(data)){
     Perl_warn(aTHX_ "%s", "IO::FD::syswrite called with use of uninitialized value");
     XSRETURN_IV(0);
    }
    max=SvCUR(data);
		if(items >=4 ){
			//length and  Offset provided
			len=SvIOK(ST(2))?SvIV(ST(2)):0;
			offset=SvIOK(ST(3))?SvIV(ST(3)):0;
			
		}
		else if(items == 3){
			//length provided	
			len=SvIOK(ST(2))?SvIV(ST(2)):0;
			offset=0;
		}
		else{
			//no length or offset
			len=SvCUR(data);
			offset=0;
		}

    if(SvOK(fd) && SvIOK(fd)){
      #TODO: fix negative offset processing
      #TODO: allow unspecified len and offset

      #fprintf(stderr,"Input size: %zu\n",SvCUR(data));
      offset=
        offset>max
          ?max
          :offset;

      if((offset+len)>max){
        len=max-offset;
      }
      
      buf=SvPVX(data);
      buf+=offset;
      ret=write(SvIV(fd), buf, len);
      #fprintf(stderr, "write consumed %d bytes\n", ret);	
      if(ret<0){
        XSRETURN_UNDEF;
        //RETVAL=&PL_sv_undef;	
      }
      else{
        mXPUSHs(newSViv(ret));
        XSRETURN(1);

        //RETVAL=newSViv(ret);
      }
    }
    else{
        errno=EBADF;
        Perl_warn(aTHX_ "%s", "IO::FD::syswrite called with something other than a file descriptor");
        XSRETURN_UNDEF;  
    }


SV*
syswrite2(fd,data)
	SV* fd
	SV* data

	INIT:
		int ret;
		char *buf;
		int len;
	PPCODE:

    if(SvOK(fd) && SvIOK(fd)){
      if(!SvOK(data)){
        Perl_warn(aTHX_ "%s", "IO::FD::syswrite called with use of uninitialized value");
        XSRETURN_IV(0);
      }
      len=SvPOK(data)?SvCUR(data):0;
      //TODO: fix negative offset processing
      //TODO: allow unspecified len and offset

      //fprintf(stderr,"Input size: %zu\n",SvCUR(data));


      buf=SvPVX(data);
      ret=write(SvIV(fd), buf, len);
      if(ret<0){
        XSRETURN_UNDEF;
        //RETVAL=&PL_sv_undef;	
      }
      else{
        //RETVAL=newSViv(ret);
        mXPUSHs(newSViv(ret));
        XSRETURN(1);
      }
    }
    else{
      errno=EBADF;
      Perl_warn(aTHX_ "%s", "IO::FD::syswrite called with something other than a file descriptor");
      XSRETURN_UNDEF;
    }

SV*
syswrite3(fd,data,len)
	SV* fd
	SV* data
	int len

	INIT:
		int ret;
		char *buf;
		STRLEN max;//=SvCUR(data);
		int offset=0;
	PPCODE:

    if(SvOK(fd) && SvIOK(fd)){
      if(!SvOK(data)){
        Perl_warn(aTHX_ "%s", "IO::FD::syswrite called with use of uninitialized value");
        XSRETURN_IV(0);
      }
      //TODO: fix negative offset processing
      //TODO: allow unspecified len and offset

      //fprintf(stderr,"Input size: %zu\n",SvCUR(data));
      max=SvCUR(data);
      if(len>max){
        len=max;
      }

      buf=SvPVX(data);
      ret=write(SvIV(fd),buf,len);
      //fprintf(stderr, "write consumed %d bytes\n", ret);	
      if(ret<0){
        //RETVAL=&PL_sv_undef;	
        XSRETURN_UNDEF;
      }
      else{
        //RETVAL=newSViv(ret);
        mXPUSHs(newSViv(ret));
        XSRETURN(1);
      }
    }
    else {
      errno=EBADF;
      Perl_warn(aTHX_ "%s", "IO::FD::syswrite called with something other than a file descriptor");
      XSRETURN_UNDEF;
    }


SV*
syswrite4(fd,data,len,offset)
	SV* fd
	SV* data
	int len
	int offset

	INIT:
		int ret;
		char *buf;
		STRLEN max;//=SvCUR(data);
	PPCODE:

		//TODO: fix negative offset processing
		//TODO: allow unspecified len and offset

    if(SvOK(fd) && SvIOK(fd)){
      if(!SvOK(data)){
        Perl_warn(aTHX_ "%s", "IO::FD::syswrite called with use of uninitialized value");
        XSRETURN_IV(0);
      }
      //fprintf(stderr,"Input size: %zu\n",SvCUR(data));
      max=SvCUR(data);
      offset=
        offset>max
        ?max
        :offset;

      if((offset+len)>max){
        len=max-offset;
      }

      buf=SvPVX(data);
      buf+=offset;
      ret=write(SvIV(fd),buf,len);
      //fprintf(stderr, "write consumed %d bytes\n", ret);	
      if(ret<0){
        //RETVAL=&PL_sv_undef;	
        XSRETURN_UNDEF;
      }
      else{
        //RETVAL=newSViv(ret);
        mXPUSHs(newSViv(ret));
      }
    }
    else{
      errno=EBADF;
      Perl_warn(aTHX_ "%s", "IO::FD::syswrite called with something other than a file descriptor");
      XSRETURN_UNDEF;
    }


#SENDFILE
#########

SV *
sendfile(socket, source, len, offset)
  SV * socket
  SV * source
  SV * len 
  SV * offset

  INIT:

    off_t l;
	  off_t o;
    int ret;

  PPCODE:
    if(SvOK(socket) && SvIOK(socket) && SvOK(source) && SvIOK(source)){
        l=SvIV(len);
	o=SvIV(offset);
#if defined(IO_FD_OS_DARWIN)
        ret=sendfile(SvIV(source),SvIV(socket),SvIV(offset),&l, NULL, 0);
#endif
#if defined(IO_FD_OS_BSD)
        ret=sendfile(SvIV(source),SvIV(socket),SvIV(offset),l, NULL, 0,0);
#endif
#if defined(IO_FD_OS_LINUX)
        ret=sendfile(SvIV(socket), SvIV(source), &o,l);
#endif
        if(ret<0){
          //Return undef on error
          XSRETURN_UNDEF;
        }
        //Otherwise return the number of bytes transfered
        ret=l;
        XSRETURN_IV(ret);

      }
      else {
        errno=EBADF;
        Perl_warn(aTHX_ "%s", "IO::FD::sendfile called with something other than a file descriptor");
        XSRETURN_UNDEF;
      }



#PIPE
######

SV*
pipe(read_end,write_end)
	SV* read_end
	SV* write_end

	ALIAS: syspipe=1


	INIT:
		int ret;
		int fds[2];

	CODE:
    if(SvREADONLY(read_end) || SvREADONLY(write_end)){
      Perl_croak(aTHX_ "%s", PL_no_modify);
    }
		ret=pipe(fds);

		if(ret<0){
			RETVAL=&PL_sv_undef;
		}
		else{
      if(fds[0]>PL_maxsysfd){
        fcntl(fds[0], F_SETFD, FD_CLOEXEC);
      }
      if(fds[1]>PL_maxsysfd){
        fcntl(fds[1], F_SETFD, FD_CLOEXEC);
      }
			//pipe returns 0 on success...
			RETVAL=newSViv(ret+1);
			if(SvOK(read_end)){
				sv_setiv(read_end, fds[0]);
			}
			else {
				read_end=newSViv(fds[0]);
			}

			if(SvOK(write_end)){
				sv_setiv(write_end,fds[1]);
			}
			else {
				write_end=newSViv(fds[1]);
			}
		}
	OUTPUT:
		RETVAL
		read_end
		write_end

#BIND
#####

SV*
bind(fd, address)
	SV *fd
	SV *address
	
	ALIAS: sysbind=1

	INIT:
		int ret;
		int len;//=SvOK(address)?SvCUR(address):0;
		struct sockaddr *addr;//=(struct sockaddr *)SvPVX(address);

	CODE:
    if(SvOK(fd) && SvIOK(fd)){
      if(SvOK(address) &&SvPOK(address)){  
		    len=SvOK(address)?SvCUR(address):0;
		    addr=(struct sockaddr *)SvPVX(address);
      }
      else {
        addr=NULL;
        len=0;
      }
      ret=bind(SvIV(fd), addr, len);
      if(ret<0){
        RETVAL=&PL_sv_undef;
      }
      else{
        RETVAL=newSViv(ret+1);
      }
    }
    else {
      errno=EBADF;
      Perl_warn(aTHX_ "%s", "IO::FD::bind called with something other than a file descriptor");
      RETVAL=&PL_sv_undef;
    }
	
	OUTPUT:
		RETVAL

#SOCKETPAIR
###########
# TODO: 
# How to through an exception like perl when syscall not implemented?

SV*
socketpair(fd1,fd2, domain, type, protocol)
	SV *fd1
	SV *fd2
	int domain
	int type
	int protocol

	INIT:

		int ret;
		int fds[2];

	CODE:
		//TODO need to emulate via tcp to localhost for non unix
    if(SvREADONLY(fd1) || SvREADONLY(fd2)){
      Perl_croak(aTHX_ "%s", PL_no_modify);
    }
		ret=socketpair(domain, type, protocol, fds);
		if(ret<0){
			RETVAL=&PL_sv_undef;
		}
		else{
      if(!SvOK(fd1)){
          fd1=newSViv(fds[0]);
      }
      if(!SvOK(fd2)){
          fd2=newSViv(fds[1]);
      }
			RETVAL=newSViv(ret+1);
      if(fds[0]>PL_maxsysfd){
        fcntl(fds[0], F_SETFD, FD_CLOEXEC);
      }
      if(fds[1]>PL_maxsysfd){
        fcntl(fds[1], F_SETFD, FD_CLOEXEC);
      }
			//fd1=fds[0];
			//fd2=fds[1];
		}
	OUTPUT:
		RETVAL
		fd1
		fd2

#SYSSEEK
########

SV*
sysseek(fd,offset,whence)
	SV *fd;
	int offset;
	int whence;

	INIT:
		int ret;

	CODE:
    if(SvOK(fd) && SvIOK(fd)){
      ret=lseek(SvIV(fd), offset, whence);
      if(ret<0){
        RETVAL=&PL_sv_undef;
      }
      else{
        RETVAL=newSViv(ret);
      }
    }
    else{
      errno=EBADF;
      RETVAL=&PL_sv_undef;
      Perl_warn(aTHX_ "%s", "IO::FD::bind called with something other than a file descriptor");
    }

	OUTPUT:
		RETVAL

#DUP
####

SV*
dup(fd)
	SV *fd;

	INIT:
		int ret;

	CODE:
    if(SvOK(fd) && SvIOK(fd)){
      ret=dup(SvIV(fd));
      if(ret<0){
        RETVAL=&PL_sv_undef;
      }
      else{
        RETVAL=newSViv(ret);
      }
    }
    else {
      errno=EBADF;
      RETVAL=&PL_sv_undef;
      Perl_warn(aTHX_ "%s", "IO::FD::dup called with something other than a file descriptor");
    }

	OUTPUT:
		RETVAL


#DUP2
#####

SV*
dup2(fd1,fd2)
	SV *fd1
	SV *fd2

	INIT: 
		int ret;

	CODE:
    if(SvOK(fd1) && SvIOK(fd1) && SvOK(fd2) && SvIOK(fd2)){
      ret=dup2(SvIV(fd1),SvIV(fd2));
      if(ret<0){
        RETVAL=&PL_sv_undef;
      }
      else{
        if(ret>PL_maxsysfd){
          fcntl(ret, F_SETFD, FD_CLOEXEC);
        }
        RETVAL=newSViv(ret);
      }
    }
    else {
      errno=EBADF;
      RETVAL=&PL_sv_undef;
      Perl_warn(aTHX_ "%s", "IO::FD::dup2 called with something other than a file descriptor");
    }

	OUTPUT:
		RETVAL
    
#FCNTL
######

SV*
fcntl(fd, cmd, arg)
	SV *fd
	int cmd
	SV* arg

	#TODO: everything

	ALIAS: sysfctrl=1
	INIT:
		int ret;
	CODE:
    if(SvOK(fd) && SvIOK(fd)){
      //if arg is numeric, call with iv
      //otherwise we pass pointers and hope for the best
      if(SvOK(arg)){
        if(SvIOK(arg)){
          //fprintf(stderr, "PROCESSING ARG AS NUMBER\n");
          ret=fcntl(SvIV(fd),cmd, SvIV(arg));
        }else if(SvPOK(arg)){
          //fprintf(stderr, "PROCESSING ARG AS STRING\n");
          ret=fcntl(SvIV(fd),cmd,SvPVX(arg));
        }
        else {
          //error
          //fprintf(stderr, "PROCESSING ARG AS UNKOWN\n");
          ret=-1;
        }
        if(ret==-1){
          RETVAL=&PL_sv_undef;
        }
        else {
          RETVAL=newSViv(ret);
        }
      }
    }
    else {
      errno=EBADF;
      RETVAL=&PL_sv_undef;
      Perl_warn(aTHX_ "%s", "IO::FD::fcntl called with something other than a file descriptor");
    }

	OUTPUT:
		RETVAL


#IOCTL
######

SV*
ioctl(fd, request, arg)
	SV *fd
	int request
	int arg

	ALIAS: sysioctl=1
	INIT:

	CODE:
		RETVAL=&PL_sv_undef;

	OUTPUT:
		RETVAL

#GETSOCKOPT
############
SV*
getsockopt(fd, level, option) 
	SV *fd
	int level
	int option

	INIT:
		int ret;
		char * buf;
		unsigned int  len;
		SV *buffer;

	CODE:
    if(SvOK(fd) && SvIOK(fd)){
      buffer=newSV(257);
      SvPOK_on(buffer);
      buf=SvPVX(buffer);
      len=256;

      ret=getsockopt(SvIV(fd),level, option, buf, &len);	

      if(ret<0){
        RETVAL=&PL_sv_undef;
      }
      else {
        SvCUR_set(buffer, len);
        *SvEND(buffer)='\0';
        RETVAL=buffer;
      }
    }
    else{
      errno=EBADF;
      RETVAL=&PL_sv_undef;
      Perl_warn(aTHX_ "%s", "IO::FD::getsockopt called with something other than a file descriptor");
    }
    


	OUTPUT:
		RETVAL


#SETSOCKOPT
###########
SV*
setsockopt(fd, level, option, buffer)
	SV *fd
	int level
	int option
	SV* buffer;

	INIT:
		int ret;
		char  *buf;
		unsigned int len;

		SV *_buffer;


	CODE:
    if(SvOK(fd) && SvIOK(fd)){
      if(SvOK(buffer)){
        if(SvIOK(buffer)){
          //fprintf(stderr, "SET SOCKOPT as integer\n");
          //Do what perl does and convert integers
          _buffer=newSV(sizeof(int));
          len=sizeof(int);

          SvPOK_on(_buffer);
          SvCUR_set(_buffer, len);
          //*SvEND(_buffer)='\0';
          buf=SvPVX(_buffer);
          *((int *)buf)=SvIVX(buffer);

        }
        else if(SvPOK(buffer)){
          //fprintf(stderr, "SET SOCKOPT as NON integer\n");
          _buffer=buffer;

        }

        len=SvCUR(_buffer);
        buf=SvPVX(_buffer);
        ret=setsockopt(SvIV(fd),level,option,buf, len);
        if(ret<0){
          //fprintf(stderr, "call failed\n");
          RETVAL=&PL_sv_undef;
        }
        else{
          //fprintf(stderr, "call succeeded\n");
          RETVAL=newSViv(ret+1);
        }

      }
      else{
        //fprintf(stderr, "no buffer");
        RETVAL=&PL_sv_undef;
      }	

    }
    else{
      errno=EBADF;
      RETVAL=&PL_sv_undef;
      Perl_warn(aTHX_ "%s", "IO::FD::setsockopt called with something other than a file descriptor");
    }

		

	OUTPUT:
		RETVAL



#SELECT
#######
SV*
select(readvec, writevec, errorvec, tout)
	SV* readvec
	SV* writevec
	SV* errorvec
	#Perl timeout is in fractional seconds
	SV* tout


	INIT:
		fd_set *r;
		fd_set *w;
		fd_set *e;
		struct timeval timeout;
		int size=sizeof(fd_set)+1;
		double tval;
		int ret;
		int nfds=0;
		int bit_string_size=129;
		int tmp;

	CODE:
		//Ensure the vector can fit a fd_set
		//TODO: Need to make sure its null filled too
		//
		if(SvOK(readvec)){
			r=(fd_set *)SvGROW(readvec,bit_string_size);
			tmp=SvCUR(readvec);
			Zero(((char *)r)+tmp,bit_string_size-tmp,1);
			nfds=tmp;
		}
		else {
			r=NULL;
		}

		if(SvOK(writevec)){
			w=(fd_set *)SvGROW(writevec,bit_string_size);
			tmp=SvCUR(writevec);
			Zero(((char *)w)+tmp,bit_string_size-tmp,1);
			nfds=tmp>nfds?tmp:nfds;
		}
		else {
			w=NULL;
		}

		if(SvOK(errorvec)){
			e=(fd_set *)SvGROW(errorvec,bit_string_size);
			tmp=SvCUR(errorvec);
			Zero(((char *)e)+tmp, bit_string_size-tmp,1);
			nfds=tmp>nfds?tmp:nfds;
		}
		else {
			e=NULL;
		}

		nfds*=8;        //convert string (byte) length to bit length
				//This length has an implicit +1 for select call

		//Clamp the nfds to 1024
		if(nfds>1024){
			//TODO: Need to show an error here?
			nfds=1024;
		}
		//TODO: handle EAGAIN and EINT
		//nfds++;
		//fprintf(stderr, "Number of fds for select: %d\n", nfds);
		if(SvOK(tout) && (SvNOK(tout) || SvIOK(tout))){
			//Timeout value provided in fractional seconds
			tval=SvNV(tout);
			timeout.tv_sec=(unsigned int ) tval;
			tval-=timeout.tv_sec;
			tval*=1000000;
			timeout.tv_usec=(unsigned int) tval;

			//fprintf(stderr, "select with %fs timeout....\n", tval);
			ret=select(nfds,r,w,e,&timeout);
			//fprintf(stderr, "Returned number of fds %d\n", ret);
		}

		else{
			//Timeout is not a number
			//printf(stderr, "select with null timeout....\n");
			ret=select(nfds,r,w,e, NULL);
		}
		if(ret<0){
			//Undef on error
			RETVAL=&PL_sv_undef;
		}
		else{
			//0 on timeout expired
			//>0 number of found fds to test
			RETVAL=newSViv(ret);
		}


	OUTPUT:

		RETVAL
		readvec
		writevec
		errorvec

#POLL
#####
SV*
poll (poll_list, s_timeout)
	SV* poll_list;
	double s_timeout;
	INIT:

		int sz=sizeof(struct pollfd);
		int count;	
		int ret;
	CODE:
		if(SvOK(poll_list) && SvPOK(poll_list)){
			count=SvCUR(poll_list)/sz;	 //Number of items in array
			//TODO: croak if not fully divisible
			ret=poll((struct pollfd *)SvPVX(poll_list), count, (int)s_timeout*1000);
		}
		else {
			//Used for timeout only
			ret=poll(NULL,0,(int)s_timeout*1000);
		}
		//TODO: need to process EAGAIN and INT somehow
		if(ret<0){
			RETVAL=&PL_sv_undef;
		}
		else{
			RETVAL=newSViv(ret);

		}
	
	
		//No length of list is required as we use the smallest multiple of sizeof(struct pollfd) which will fit in  the poll list

	OUTPUT:

		RETVAL
		poll_list




#MKSTEMP
########

SV*
mkstemp(template)
	char *template

	INIT:
		int ret;
		SV *path_sv;
		char *path;
		int len=0;
		int min_ok=1;
	PPCODE:
		len=strlen(template);
		if(len<6){
			Perl_croak(aTHX_ "The template must end with at least 6 'X' characters");
		}

		for(int i=1; i<=6; i++){
			min_ok=min_ok&&(template[len-i]=='X');
		}
		if(!min_ok){
			Perl_croak(aTHX_ "The template must end with at least 6 'X' characters");
		}


		ret=mkstemp(template);
		if(ret<0){
			Perl_croak(aTHX_ "Error creating temp file");
			//mXPUSHs(&PL_sv_undef);
		}	
		else{

      if(ret>PL_maxsysfd){
        fcntl(ret, F_SETFD, FD_CLOEXEC);
      }
			switch(GIMME_V){
				case G_SCALAR:
					mXPUSHs(newSViv(ret));
					XSRETURN(1);
					break;
				case G_ARRAY:
					//path_sv=newSV(MAXPATHLEN);	
					//path=SvPVX(path_sv);
					//fcntl(ret, F_GETPATH, path);
					//SvCUR_set(path_sv, strlen(path));

					EXTEND(SP,2);
					mPUSHs(newSViv(ret));
					//mPUSHs(newSVpv(path,0));
					mPUSHs(&PL_sv_undef);
					XSRETURN(2);
					break;

				default:
					XSRETURN_EMPTY;
					break;
					
			}
		}

#MKTEMP
#######

SV*
mktemp(template)
	char *template

	INIT:
		char *ret;
		char *buf;
		int len=0;
		int min_ok=1;
	PPCODE:
		len=strlen(template);
		if(len<6){
			Perl_croak(aTHX_ "The template must end with at least 6 'X' characters");
		}

		for(int i=1; i<=6; i++){
			min_ok=min_ok&&(template[len-i]=='X');
		}

		if(!min_ok){
			Perl_croak(aTHX_ "The template must end with at least 6 'X' characters");
		}

		ret=mktemp(template);
		if(ret==NULL){
			Perl_croak(aTHX_ "Error creating temp file");
		}
		else{
			mXPUSHs(newSVpv(ret, 0));
			XSRETURN(1);
		}


SV*
recv(fd, data, len, flags)
	SV *fd
	SV *data
	int len
	int flags

	INIT:
		int ret;
		SV* peer;	//Return addr like perl
		struct sockaddr *peer_buf; 
		unsigned int addr_len;
		char *buf;

	CODE:
    if(SvOK(fd) && SvIOK(fd)){
        if(SvREADONLY(data)){
            Perl_croak(aTHX_ "%s", PL_no_modify);
        }
      //Makesure the buffer exists and is large enough to recv
      if(!SvOK(data)){
        data=newSV(len);
      }
      buf = SvPOK(data) ? SvGROW(data,len+1) : NULL;

      peer=newSV(sizeof(struct sockaddr_storage));
      peer_buf=(struct sockaddr *)SvPVX(peer);

      addr_len=sizeof(struct sockaddr_storage);
      ret=recvfrom(SvIV(fd), buf, len, flags, peer_buf, &addr_len);

      if(ret<0){
        RETVAL=&PL_sv_undef;
      }
      else{
        SvCUR_set(data,ret);
        SvPOK_on(peer);
        //SvCUR_set(peer, addr_len);
        ADJUST_SOCKADDR_SIZE(peer);
        RETVAL=peer;
      }
    }
    else {
      errno=EBADF;
      RETVAL=&PL_sv_undef;
      Perl_warn(aTHX_ "%s", "IO::FD::recv called with something other than a file descriptor");
    }
	OUTPUT:
		RETVAL

SV*
send(fd,data,flags, ...)
	SV *fd
	SV* data
	int flags

	INIT:

		char *buf;
		int len;

		struct sockaddr *dest;
		int ret;

		
	CODE:
    if(SvOK(fd) && SvIOK(fd)){
      if(SvOK(data) && SvPOK(data)){
        if((items == 4) && SvOK(ST(3)) && SvPOK(ST(3))){
          //Do sendto
          len=SvCUR(data);
          buf=SvPVX(data);

          dest=(struct sockaddr *)SvPVX(ST(3));

          ret=sendto(SvIV(fd), buf, len, flags, dest, SvCUR(ST(3)));
        }
        else {
          //Regular send
          len=SvCUR(data);
          buf=SvPVX(data);
          ret=send(SvIV(fd), buf, len, flags);
        }
      }
      if(ret<0){

        RETVAL=&PL_sv_undef;
      }
      else{
        RETVAL=newSViv(ret);
      }
    }
    else{
      errno=EBADF;
      RETVAL=&PL_sv_undef;
      Perl_warn(aTHX_ "%s", "IO::FD::send called with something other than a file descriptor");
    }

	OUTPUT:
		RETVAL


SV*
getpeername(fd)
	SV *fd;
	
	INIT:
		int ret;
		SV *addr=newSV(sizeof(struct sockaddr_storage)+1);
		struct sockaddr *buf=(struct sockaddr *)SvPVX(addr);
		unsigned int len=sizeof(struct sockaddr_storage);

	CODE:
    if(SvOK(fd)&&SvIOK(fd)){	
      ret=getpeername(SvIV(fd),buf,&len);
      if(ret<0){
        RETVAL=&PL_sv_undef;
      }
      else {
        //SvCUR_set(addr,len);
        ADJUST_SOCKADDR_SIZE(addr);
        SvPOK_on(addr);

        RETVAL=addr;
      }
    }
    else {
      errno=EBADF;
      RETVAL=&PL_sv_undef;
      Perl_warn(aTHX_ "%s", "IO::FD::getpeername called with something other than a file descriptor");
    }
	
	OUTPUT:
		RETVAL

SV*
getsockname(fd)
	SV *fd;
	
	INIT:
		int ret;
		SV *addr=newSV(sizeof(struct sockaddr_storage)+1);
		struct sockaddr *buf=(struct sockaddr *)SvPVX(addr);
		unsigned int len=sizeof(struct sockaddr_storage);

	CODE:
    if(SvOK(fd) && SvIOK(fd)){	
      ret=getsockname(SvIV(fd),buf,&len);
      if(ret<0){
        RETVAL=&PL_sv_undef;
      }
      else {
        //SvCUR_set(addr,len);
        ADJUST_SOCKADDR_SIZE(addr);
        SvPOK_on(addr);

        RETVAL=addr;
      }
    }
    else{
      errno=EBADF;
      RETVAL=&PL_sv_undef;
      Perl_warn(aTHX_ "%s", "IO::FD::getsockname called with something other than a file descriptor");
    }
	
	OUTPUT:
		RETVAL

void
shutdown(fd, how)
	SV *fd
	int how

	INIT:

	  int ret;
	PPCODE:
  if(SvOK(fd)&& SvIOK(fd)){ 
    ret=shutdown(SvIV(fd), how);

    if(ret<0){
      XSRETURN_UNDEF;
    }
    else{
      mXPUSHs(newSViv(1));
      XSRETURN(1);
    }
  }
  else{
      errno=EBADF;
      Perl_warn(aTHX_ "%s", "IO::FD::shutdown called with something other than a file descriptor");
      XSRETURN_UNDEF;
  }

void
stat(target)
	SV *target;

	ALIAS:
		IO::FD::stat = 1
		IO::FD::lstat = 2
	INIT:

		int ret=-1;
		char *path;
		struct stat buf;
		int len;
		IV atime;
		IV mtime;
		IV ctime;
	PPCODE:

		if(SvOK(target) && SvIOK(target)){
			//Integer => always an fstat
			ret=fstat(SvIV(target), &buf);
		}
		else if(SvOK(target)&& SvPOK(target)){
			//String => stat OR lstat
			
			len=SvCUR(target);
			Newx(path, len+1, char); 	//Allocate plus null
			Copy(SvPV_nolen(target), path, len, char);	//Copy
			*(path+len)='\0';	//set null	
			switch(ix){
				case 1:
					ret=stat(path, &buf);
					break;
				case 2:
					ret=lstat(path, &buf);
					break;

				default:
					break;
			}
			Safefree(path);

			
		}
		else {
			//Unkown
		}

		if(ret>=0){
			switch(GIMME_V){
				case G_ARRAY:
					//fprintf(stderr , "ARRAY CONTEXT. no error\n");


					//atime=buf.st_atimespec.tv_sec+buf.st_atimespec.tv_nsec*1e-9;
					//mtime=buf.st_mtimespec.tv_sec+buf.st_mtimespec.tv_nsec*1e-9;
					//ctime=buf.st_ctimespec.tv_sec+buf.st_ctimespec.tv_nsec*1e-9;
					IO_FD_ATIME
					IO_FD_MTIME
					IO_FD_CTIME





					//Work through the items in the struct
					//dSP;
					EXTEND(SP, 13);
					mPUSHs(newSViv(buf.st_dev));
					mPUSHs(newSVuv(buf.st_ino));
					mPUSHs(newSVuv(buf.st_mode));
					mPUSHs(newSViv(buf.st_nlink));
					mPUSHs(newSViv(buf.st_uid));
					mPUSHs(newSViv(buf.st_gid));
					mPUSHs(newSViv(buf.st_rdev));
					mPUSHs(newSViv(buf.st_size));
					mPUSHs(newSViv(atime));
					mPUSHs(newSViv(mtime));
					mPUSHs(newSViv(ctime));
					mPUSHs(newSViv(buf.st_blksize));
					mPUSHs(newSViv(buf.st_blocks));
					XSRETURN(13);
					break;
				case G_VOID:
					XSRETURN_EMPTY;
					break;
				case G_SCALAR:
				default:
					//fprintf(stderr , "SCALAR CONTEXT. no error\n");
					mXPUSHs(newSViv(1));
					XSRETURN(1);
					break;
			}



		}
		switch(GIMME_V){
			case G_SCALAR:
				mXPUSHs(&PL_sv_undef);
				XSRETURN(1);
				break;
			case G_VOID:
			case G_ARRAY:
			default:
				XSRETURN_EMPTY;
				break;
		}





#if defined(IO_FD_OS_DARWIN) || defined(IO_FD_OS_BSD)
SV *
kqueue()

	INIT:
		int ret;
	CODE:
		ret=kqueue();
		if(ret<0){
			RETVAL=&PL_sv_undef;
		}
		else{
			RETVAL=newSViv(ret);
		}
	OUTPUT:
		RETVAL

SV *
kevent(kq, change_list, event_list, timeout)
	int kq;
	SV * change_list;
	SV * event_list;
	SV * timeout;
	
	INIT:
		int ret;
		int ncl, nel;
		KEVENT_S *cl, *el;
		struct timespec tspec;
		double tout;

	CODE:
		//Calcuate from current length
		ncl=SvCUR(change_list)/sizeof(KEVENT_S);

		//Calculate from available length
		nel=SvLEN(event_list)/sizeof(KEVENT_S);

		cl=(KEVENT_S *)SvPVX(change_list);
		el=(KEVENT_S *)SvPVX(event_list);

		//fprintf(stderr, "change list len: %d, event list available: %d\n", ncl, nel);
		if(SvOK(timeout)&& SvNIOK(timeout)){
			tout=SvNV(timeout);
			tspec.tv_sec=tout;
			tspec.tv_nsec=1e9*(tout-tspec.tv_sec);
#if defined(IO_FD_OS_DARWIN)
			ret=KEVENT (kq, cl, ncl, el, nel, 0, &tspec);
#endif
#if defined(IO_FD_OS_BSD)
			ret=KEVENT(kq, cl, ncl, el, nel, &tspec);
	//}
#endif
		}
		else {
#if defined(IO_FD_OS_DARWIN)
			ret=KEVENT(kq,cl,ncl, el, nel,0, NULL);
#endif
#if defined(IO_FD_OS_BSD)
			ret=KEVENT(kq,cl,ncl, el, nel, NULL);
#endif
		}

		if(ret<0){
			SvCUR_set(event_list,0);
			RETVAL=&PL_sv_undef;
		}
		else {
			SvCUR_set(event_list,sizeof(KEVENT_S)*ret);
			RETVAL=newSViv(ret);
		}

	OUTPUT:
		RETVAL
		event_list

	
SV *
pack_kevent(ident,filter,flags,fflags,data,udata, ...)
	unsigned long ident;
	I16 filter;
	U16 flags;
	U32 fflags;
	long data;
	SV *udata;

	INIT:
		KEVENT_S *e;

	CODE:
		RETVAL=newSV(sizeof(KEVENT_S));	
		e=(KEVENT_S *)SvPVX(RETVAL);
		e->ident=ident;
		e->filter=filter;
		e->flags=flags;
		e->fflags=fflags;
		e->data=data;
		e->udata=SvRV(udata);
		SvCUR_set(RETVAL,sizeof(KEVENT_S));
		SvPOK_on(RETVAL);
		//Pack

	OUTPUT:
		RETVAL

#endif

SV * 
clock_gettime_monotonic()

	INIT:
		struct timespec tp;
		int ret;

	CODE:
		ret=clock_gettime(CLOCK_MONOTONIC, &tp);
		if(ret<0){
			RETVAL=&PL_sv_undef;
		}
		else{
			RETVAL=newSVnv(tp.tv_sec + tp.tv_nsec * 1e-9);
		}


	OUTPUT:
		RETVAL

long
sv_to_pointer(sv)
	SV *sv

	INIT:

	CODE:
		//TODO: Increase the ref count	of input sv
		RETVAL=(long)SvRV(sv);
	OUTPUT:

		RETVAL

SV *
pointer_to_sv(pointer)
	long pointer;

	INIT:
	CODE:
		//TODO: check valid. decrement ref count;
		RETVAL=newRV((SV*)pointer);

	OUTPUT:
		RETVAL


SV *
SV(size)
	int size

	CODE:
		RETVAL=newSV(size);
		
		//SvPOK_on(RETVAL);
		SvPVCLEAR(RETVAL);
	OUTPUT:
		RETVAL

#TODO

#readline
#readinput based on $\ seperator. use get_sv function??
#in list or scalar context

void
readline(fd)
	SV *fd
	
	INIT:
		SV *irs;
		int ret;
		int count;
		SV* buffer;
		char *buf;
		int do_loop=1;

		int tmp;
	PPCODE:
    if(SvOK(fd)&& SvIOK(fd)){
      irs=get_sv("/",0);
      if(irs){
  #Found variable. Read records
        if(SvOK(irs)){
          if(SvROK(irs)){
            //fprintf(stderr, "DOING RECORD READ\n");
            //SLURP RECORDS

            SV* v=SvRV(irs);	//Dereference to get SV
            tmp=SvIV(v);		//The integer value of the sv
            buffer=newSV(tmp);	//Allocate buffer at record size
            buf=SvPVX(buffer);	//Get the pointer we  need
            ret=read(SvIV(fd), buf, tmp);	//Do the read into buffer
            //fprintf(stderr, "read return: %d\n", ret);
            SvPOK_on(buffer);	//Make a string
            if(ret>=0){
              buf[ret]='\0';		//Set null just in case
              SvCUR_set(buffer,ret);	//Set the length of the string
              EXTEND(SP,1);		//Extend stack
              mPUSHs(buffer);		//Push record
              XSRETURN(1);
            }
            else {
              XSRETURN_UNDEF;
            }

          }
          else {
            Perl_croak( aTHX_ "IO::FD::readline does not split lines");
          }
        }
        else{

          //fprintf(stderr, "DOING SLURP READ\n");
          //SLURP entire file
          EXTEND(SP,1);
          PUSHs(slurp(aTHX_ SvIV(fd), 4096));
          XSRETURN(1);
        }
      }
      else {
        //not found.. this isn't good

      }
    }
    else{
      XSRETURN_UNDEF;
    }


#Naming

#TODO:
# TODO ioctl
# poll
# select ... perl compatiable version
# dir ... not normally on FDs?
# readline?

# Add IPC::Open2 and IPC::Open3 emulations

