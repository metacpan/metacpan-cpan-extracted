#SYSREAD
########

SV*
sysread(fd, data, len, ...)
    SV* fd;
    SV* data
		size_t len
		INIT:
			ssize_t ret;
			char *buf;
			long offset=0;

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

        size_t data_len=sv_len(data);
        size_t request_len;
        if(offset<0){
          offset=data_len-offset;
        }
        else{

        }
        request_len=len+offset;

        //fprintf(stderr, "Length of buffer is: %d\n", data_len);
        //fprintf(stderr, "Length of request is: %d\n", request_len);

        buf = SvPOK(data) ? SvGROW(data, request_len+1) : 0;

        //data_len=sv_len(data);
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
pread(fd, data, len, offset)
  SV *fd;
  SV *data;
  size_t len
  long offset;

		INIT:
			ssize_t ret;
			char *buf;

    PPCODE:
			//TODO: allow unspecified len and offset

			//grow scalar to fit potental read
      if(SvOK(fd) && SvIOK(fd)){
        if(SvREADONLY(data)){
            Perl_croak(aTHX_ "%s", PL_no_modify);
        }

        buf = SvPOK(data) ? SvGROW(data, len+1) : 0;

        ret=pread(SvIV(fd), buf, len, offset);

        if(ret<0){
          XSRETURN_UNDEF;
        }
        else {
          buf[ret]='\0';
          SvCUR_set(data,ret);
          mXPUSHs(newSViv(ret));
          XSRETURN(1);
        }
      }
      else{
        errno=EBADF;
        Perl_warn(aTHX_ "%s", "IO::FD::pread called with something other than a file descriptor");
        XSRETURN_UNDEF;
      }





SV*
sysread3(fd, data, len)
		SV *fd;
		SV* data
		size_t len

		INIT:
			ssize_t ret;
			char *buf;
			long offset;

		PPCODE:
    if(SvOK(fd) &&SvIOK(fd)){
      if(SvREADONLY(data)){
        Perl_croak(aTHX_ "%s", PL_no_modify);
      }
			size_t data_len=SvCUR(data);

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
    size_t len
		long offset

		INIT:
			ssize_t ret;
			char *buf;

      PPCODE:
      if(SvOK(fd) &&SvIOK(fd)){
        if(SvREADONLY(data)){
          Perl_croak(aTHX_ "%s", PL_no_modify);
        }

#grow scalar to fit potental read
        long data_len=sv_len(data);
        long request_len;
        if(offset<0){
          offset=data_len-offset;
        }
        else{

        }
        request_len=len+offset;


        buf = SvPOK(data) ? SvGROW(data, request_len+1) : 0;

        //data_len=sv_len(data);

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
