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
        //close returns 0 on success.. which is false in perl 
        //so increment
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

