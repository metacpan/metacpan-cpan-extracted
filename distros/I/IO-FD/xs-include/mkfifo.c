SV*
mkfifo(path, ...)
    char *path
    //int mode

		PREINIT:
			int f;
      int mode=0666;	//Default if not provided

		PPCODE:
      if(items==2){
        mode=SvIV(ST(1));
      }
			f=mkfifo(path, mode);
			if(f<0){
				//RETVAL=&PL_sv_undef;
        XSRETURN_UNDEF;
			}
			else{
        if(!(mode & O_CLOEXEC) && (f>PL_maxsysfd)){
          fcntl(f, F_SETFD, FD_CLOEXEC);
        }
        XSRETURN_IV(f+1);
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

