#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "const-c.inc"

// Platform include files are injected here.
// See Makefile.PL for details
//
#include "platform.h"


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

INCLUDE_COMMAND: cat "xs-include/socket.c"
INCLUDE_COMMAND: $^X "xs-include/sendfile.pl"
INCLUDE_COMMAND: cat "xs-include/mkfifo.c"
INCLUDE_COMMAND: $^X "xs-include/mkfifoat.pl"
INCLUDE_COMMAND: cat "xs-include/file.c"
INCLUDE_COMMAND: cat "xs-include/experimental.c"
INCLUDE_COMMAND: cat "xs-include/temp.c"
INCLUDE_COMMAND: cat "xs-include/send-recv.c"



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

