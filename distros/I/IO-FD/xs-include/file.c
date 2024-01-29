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
    //NOTE: Remember to add 1 to no error return
	OUTPUT:
		RETVAL


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
		long long atime;
		long long mtime;
		long long ctime;
		char scratch[32]; //
    		SV *tmp;
	PPCODE:

		if(SvOK(target) && SvIOK(target)){
			//Integer => always an fstat
			ret=fstat(SvIV(target), &buf);
		}
		else if(SvOK(target)&& SvPOK(target)){
			//String => stat OR lstat
			
			len=SvCUR(target);
			Newx(path, len+1, char); 	//Allocate plus null
			Copy(SvPVbyte_nolen(target), path, len, char);	//Copy
			path[len]='\0';	//set null	
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

    //fprintf(stderr, "Size of dev: %d\n",sizeof(buf.st_dev));
    //fprintf(stderr, "Size of ino: %d\n",sizeof(buf.st_ino));
    //fprintf(stderr, "Size of nlink: %d\n",sizeof(buf.st_nlink));
    //fprintf(stderr, "Size of size: %d\n",sizeof(buf.st_size));
    //fprintf(stderr, "Size of blocks: %d\n",sizeof(buf.st_blocks));

		if(ret>=0){
			switch(GIMME_V){
				case G_ARRAY:

					IO_FD_ATIME
					IO_FD_MTIME
					IO_FD_CTIME


					//Work through the items in the struct
          //
					EXTEND(SP, 13);               //macos     bsd       linux
          // ====== st_dev
          if(buf.st_dev<0){
            // Handle signed value
                                        //int32     uint64    uint64
            if(sizeof(IV)<sizeof(buf.st_dev)){
              sprintf(scratch,"%lld", buf.st_dev);
              tmp = newSVpv(scratch,0);
            }
            else{
              tmp=newSViv(buf.st_dev);
            }
          }
          else {
            // Handle unsigned value
            if(sizeof(UV)<sizeof(buf.st_dev)){
              sprintf(scratch,"%llu", buf.st_dev);
              tmp = newSVpv(scratch,0);
            }
            else{
              tmp=newSVuv(buf.st_dev);
            }
          }
          mPUSHs(tmp);

          // ==== st_ino                            
          if(sizeof(UV)<sizeof(buf.st_ino)){
              sprintf(scratch,"%llu", buf.st_ino);
              tmp = newSVpv(scratch,0);
          }
          else{
            tmp=newSVuv(buf.st_ino);
          }
          mPUSHs(tmp);
          //mPUSHs(newSVuv(buf.st_ino));  //uint32/64 uint64    uint32/uint64



          // ==== st_mode
	  mPUSHs(newSVuv(buf.st_mode)); //uint16    uint16    uint32
                                        //
          // ==== st_nlink
          if(sizeof(UV)<sizeof(buf.st_nlink)){
            // We know we are longer than 32 bits
              sprintf(scratch,"%llu", buf.st_nlink);
              tmp = newSVpv(scratch,0);
          }
          else{
            tmp=newSVuv(buf.st_nlink);
          }
          mPUSHs(tmp);

          //mPUSHs(newSVuv(buf.st_nlink));//uint16    uint64    uint32


          // ==== st_uid
	  mPUSHs(newSVuv(buf.st_uid));  //uint32    uint32    uint32
                                        //
          // ==== st_gid
 	  mPUSHs(newSVuv(buf.st_gid));  //uint32    uint32    uint32
                                        //
          // ==== st_rdev
          if(buf.st_rdev<0){
            // Handle signed value
                                        //int32     uint64    uint64
            if(sizeof(IV)<sizeof(buf.st_rdev)){
              sprintf(scratch,"%lld", buf.st_rdev);
              tmp = newSVpv(scratch,0);
            }
            else{
              tmp=newSViv(buf.st_rdev);
            }
          }
          else {
            // Handle unsigned value
            if(sizeof(UV)<sizeof(buf.st_rdev)){
              sprintf(scratch,"%llu", buf.st_rdev);
              tmp = newSVpv(scratch,0);
            }
            else{
              tmp=newSVuv(buf.st_rdev);
            }
          }
          mPUSHs(tmp);


          // ==== st_size
          if(sizeof(IV)<sizeof(buf.st_size)){
              sprintf(scratch,"%lld", buf.st_size);
              tmp = newSVpv(scratch,0);
          }
          else{
            tmp=newSViv(buf.st_size);
          }
          mPUSHs(tmp);
					//mPUSHs(newSViv(buf.st_size)); //int64     int64     int64 


          // ==== Times
          if(sizeof(IV)<sizeof(atime)){
              sprintf(scratch,"%lld", atime);
              tmp = newSVpv(scratch,0);
	      mPUSHs(tmp);

              sprintf(scratch,"%lld", mtime);
              tmp = newSVpv(scratch,0);
	      mPUSHs(tmp);

              sprintf(scratch,"%lld", ctime);
              tmp = newSVpv(scratch,0);
	      mPUSHs(tmp);
          }
          else{
            // ==== st_atime
            mPUSHs(newSViv(atime));

            // ==== st_mtime
            mPUSHs(newSViv(mtime));

            // ==== st_ctime
            mPUSHs(newSViv(ctime));
          }


          // ==== st_blksize
	  mPUSHs(newSViv(buf.st_blksize));//int32   int32     int32 


          // ==== st_blocks
          if(sizeof(IV)<sizeof(buf.st_blocks)){
              sprintf(scratch,"%lld", buf.st_blocks);
              tmp = newSVpv(scratch,0);
          }
          else{
            tmp=newSViv(buf.st_blocks);
          }
          mPUSHs(tmp);
					//mPUSHs(newSViv(buf.st_blocks));//int64    int64     int32


					XSRETURN(13);
					break;
				case G_VOID:
					XSRETURN_EMPTY;
					break;
				case G_SCALAR:
				default:
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

