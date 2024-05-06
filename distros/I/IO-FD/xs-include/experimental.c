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
		e->udata=(uint64_t)SvRV(udata);
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
