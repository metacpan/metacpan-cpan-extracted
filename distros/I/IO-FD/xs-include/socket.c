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
		
INCLUDE_COMMAND: cat "xs-include/open.c"

INCLUDE_COMMAND: cat "xs-include/close.c"


INCLUDE_COMMAND: cat "xs-include/read.c"
INCLUDE_COMMAND: cat "xs-include/write.c"



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
