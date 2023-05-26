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

      //struct timeval start;
      //struct timeval end;

      //gettimeofday(&start, NULL);
      ret=write(SvIV(fd), buf, len);
      //gettimeofday(&end, NULL);
      //time_t diff_sec=end.tv_sec-start.tv_sec;
      //time_t diff_usec=end.tv_usec-start.tv_usec;
      //fprintf(stderr,"Write seconds: %ld, useconds %ld\n", diff_sec, diff_usec); 
      //fprintf(stderr, "write consumed %d bytes\n", ret);	
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
pwrite(fd, data, len, offset)
	SV *fd
	SV* data
  int len;
  int offset;

	INIT:
		int ret;
		char *buf;
		STRLEN max;//=SvCUR(data);
	PPCODE:
    if(!SvOK(data)){
     Perl_warn(aTHX_ "%s", "IO::FD::pwrite called with use of uninitialized value");
     XSRETURN_IV(0);
    }
    max=SvCUR(data);

    //Ensure we don't attempt to write memory we don't have!
    len= max<len?max:len;
    if(SvOK(fd) && SvIOK(fd)){
      
      buf=SvPVX(data);
      ret=pwrite(SvIV(fd), buf, len, offset);
      if(ret<0){
        XSRETURN_UNDEF;
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
