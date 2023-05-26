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

