
#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include <zlib.h> 

/* expletive */
#undef malloc
#undef free

#ifdef WIN32
#define snprintf _snprintf
#endif

#ifdef __GNUC__

/* Mingw32 defaults to globing command line 
 * This is inconsistent with other Win32 ports and 
 * seems to cause trouble with passing -DXSVERSION=\"1.6\" 
 * So we turn it off like this:
 */
int _CRT_glob = 0;

#endif

///////////////////////////////////////////////////////////

typedef struct di_stream {
    z_stream stream;
    uLong    bufsize; 
    uLong    bufinc; 
    SV *     dictionary ;
    uLong    dict_adler ;
    bool     deflateParams_out_valid ;
    Bytef    deflateParams_out_byte;
    int      Level;
    int      Method;
    int      WindowBits;
    int      MemLevel;
    int      Strategy;
} di_stream;

typedef di_stream * inflateStream ;
typedef di_stream * LibZip__MyZlib__inflateStream ;

/* typedef gzFile LibZip__MyZlib__gzFile ; */
typedef struct gzType {
    gzFile gz ;
    SV *   buffer ;
    uLong   offset ;
    bool   closed ;
}  gzType ;

typedef gzType* LibZip__MyZlib__gzFile ; 

#define GZERRNO	"LibZip::MyZlib::gzerrno"

#define ZMALLOC(to, typ) ((to = (typ *)safemalloc(sizeof(typ))), \
                                Zero(to,1,typ))

#define adlerInitial adler32(0L, Z_NULL, 0)
#define crcInitial crc32(0L, Z_NULL, 0)

#if 1
static char *my_z_errmsg[] = {
    "need dictionary",     /* Z_NEED_DICT     2 */
    "stream end",          /* Z_STREAM_END    1 */
    "",                    /* Z_OK            0 */
    "file error",          /* Z_ERRNO        (-1) */
    "stream error",        /* Z_STREAM_ERROR (-2) */
    "data error",          /* Z_DATA_ERROR   (-3) */
    "insufficient memory", /* Z_MEM_ERROR    (-4) */
    "buffer error",        /* Z_BUF_ERROR    (-5) */
    "incompatible version",/* Z_VERSION_ERROR(-6) */
    ""};
#endif


static int trace = 0 ;

///////////////////////////////////////////////////////////

static PerlInterpreter *my_perl;

static void xs_init( pTHX );
EXTERN_C void boot_DynaLoader( pTHX_ CV* cv );

int opt_allowed(const char *s1, const char *s2) {
  int n = strlen(s1) ;
  if (n == 0) return 0 ;
  
  if ( *s2 == '-' ) {
    if ( strlen(s2) == 2 ) { ++s2 ;}
    else if ( strlen(s2) > 2 ) {
      ++s2 ;
      if (
        *s2 != 'd' &&
        *s2 != 'D' &&
        *s2 != 'F' &&
        *s2 != 'i' &&
        *s2 != 'I' &&
        *s2 != 'l' &&
        *s2 != 'm' &&
        *s2 != 'M' &&
        *s2 != 'V' &&
        *s2 != 'x'
      )
      return 0 ;
    }
  }

  //printf("OPT %s [%s]" , s1 , s2) ;

  while (n-- != 0) {
    if (n == 0 || *s1 == '\0' || *s1 == '#') {
      //printf("\n") ;
      return 0 ;
    }
    if ( *(unsigned char *)s1 == *(unsigned char *)s2 ) {
      //printf("OK\n") ;
      return 1 ;
    }
    s1++;
  }

  return 0 ;
}

char** prepare_args( int argc, char** argv, int* my_argc , int* arg_code_pos , char* allow_opts )
{
    int i, count = ( argc ? argc : 1 ) + 3 ;
    int opts_count = strlen(allow_opts) ;
    
    char** my_argv = (char**) malloc( ( count + 1 ) * sizeof(char**) );
    char** perl_argv = (char**) malloc( ( count + 1 ) * sizeof(char**) );
    char** noallow_argv = (char**) malloc( ( count + 1 ) * sizeof(char**) );
    char** script_argv = (char**) malloc( ( count + 1 ) * sizeof(char**) );
    
    int perl_argv_i = 0 ;
    int noallow_argv_i = 0 ;
    int script_argv_i = 0 ;
    int my_arv_i = 0 ;
    
    int script_argv_begin = 0 ;
    
    int end_perl_args = -1 ;
    int last_e = 0 ;

    int found_opt_e = 0 ;
    int found_opt_c = 0 ;
    
    for( i = 1; i < count - 3 ; ++i ) {
      
      if ( end_perl_args == -1 && (strncmp(argv[i], "-", 1) == 0 || last_e) ) {
        if ( last_e || opt_allowed(allow_opts,argv[i]) ) {
          perl_argv[ perl_argv_i++ ] = strdup(argv[i]) ;

          if ( strcmp(argv[i], "-e") == 0 ) { last_e = found_opt_e = 1 ;}
          else { last_e = 0 ;}
          
          if ( strcmp(argv[i], "-c") == 0 ) { found_opt_c = 1 ;}
        }
        else {
          noallow_argv[ noallow_argv_i++ ] = strdup(argv[i]) ;
          last_e = 0 ;
        }
      }
      else {
        if (end_perl_args == -1) end_perl_args = i ;
        script_argv[ script_argv_i++ ] = strdup(argv[i]) ;
        last_e = 0 ;
      }
    }
    
    if ( last_e ) { perl_argv[ perl_argv_i++ ] = "0" ;}

    my_argv[my_arv_i++] = strdup( argc ? argv[0] : "" );
    
    for(i = 0; i < perl_argv_i ; ++i ) {
      my_argv[my_arv_i++] =  strdup( perl_argv[i] ) ;
    }
    
    if ( found_opt_c && script_argv_i > 0 ) {
      my_argv[my_arv_i++] = strdup( script_argv[0] );
      ++script_argv_begin ;
    }
    else if ( !found_opt_e ) {
      my_argv[my_arv_i++] = strdup( "-e" );
      *arg_code_pos = my_arv_i ;
      my_argv[my_arv_i++] = strdup( "0" );
    }
    
    my_argv[my_arv_i++] = strdup( "--" );
    
    for(i = 0; i < noallow_argv_i ; ++i ) {
      my_argv[my_arv_i++] =  strdup( noallow_argv[i] ) ;
    }
    
    for(i = script_argv_begin; i < script_argv_i ; ++i ) {
      my_argv[my_arv_i++] =  strdup( script_argv[i] ) ;
    }

    my_argv[my_arv_i] = NULL;
    
    /*
    printf("------------------------------------- END: %i\n" , end_perl_args) ;
    
    for( i = 0; i < perl_argv_i ; ++i ) {
      printf("pl>> %s\n" , perl_argv[i] ) ;    
    }
    
    for( i = 0; i < noallow_argv_i ; ++i ) {
      printf("no>> %s\n" , noallow_argv[i] ) ;    
    }
    
    for( i = 0; i < script_argv_i ; ++i ) {
      printf("sc>> %s\n" , script_argv[i] ) ;    
    }
    
    for( i = 0; i < my_arv_i ; ++i ) {
      printf("my>> %s\n" , my_argv[i] ) ;    
    }
    
    printf("-------------------------------------\n") ;
    */
    
    
    *my_argc = my_arv_i;
    return my_argv;
}

int
main(int argc, char **argv, char **env)
{
    int my_argc , i;
    char** my_argv;
    int exitstatus ;
    int arg_code_pos = -1 ;
    char  *tmp=NULL ;
    int   can_run=1 ;
    char  CODE[500] ;
    char  LBZ_size[] = "##[LBZZ]##";
    char  LBZ_size2[] = "##[LBZS]##";
    char  LBZ_allow_opts[] = "##[LBZOPTS]###################";
    char  LBZ_runA[] = "package LibZip::MAIN;eval{%LBZ=(z=>'" ;
    char  LBZ_runB[] = "',s=>'" ;
    char  LBZ_runC[] = "',x=>$^X);if((!-s$LBZ{x})||-d$LBZ{x}){if($^O=~/(msw|win|dos)/i){$LBZ{x}.='.exe'}}open(LBZ,$LBZ{x});binmode(LBZ);if(-s$LBZ{x}!=($LBZ{z}+$LBZ{s})){$_='';1 while(read(LBZ,$_,1024*4,length$_)&&!(/^(.*?\\s##__LIBZIP-SCRIPT__##\\s)/s&&($_=$1)));$LBZ{z}=length$_ if/\\s##__LIBZIP-SCRIPT__##\\s/;}seek(LBZ,$LBZ{z},0);read(LBZ,$_,$LBZ{s});close(LBZ);};eval($_);die$@if$@" ;

    tmp = malloc(sizeof(char) * strlen(LBZ_size) + 1) ;

    strcpy (tmp, LBZ_size);
    if ( tmp[0] == '#' ) { can_run = 0 ;}
    
    my_argv = prepare_args( argc, argv, &my_argc , &arg_code_pos , LBZ_allow_opts );
    
#if defined(USE_ITHREADS)
    /* XXX Ideally, this should really be happening in perl_alloc() or
     * perl_construct() to keep libperl.a transparently fork()-safe.
     * It is currently done here only because Apache/mod_perl have
     * problems due to lack of a call to cancel pthread_atfork()
     * handlers when shared objects that contain the handlers may
     * be dlclose()d.  This forces applications that embed perl to
     * call PTHREAD_ATFORK() explicitly, but if and only if it hasn't
     * been called at least once before in the current process.
     * --GSAR 2001-07-20 */
    PTHREAD_ATFORK(Perl_atfork_lock,
                   Perl_atfork_unlock,
                   Perl_atfork_unlock);
#endif
    
    // run interpreter:
    
    my_perl = perl_alloc();
    PERL_SET_CONTEXT(my_perl);
    
    perl_construct(my_perl);
	PL_perl_destruct_level = 0;
    
    if ( can_run ) {
      sprintf(CODE,"%s%s%s%s%s\0",LBZ_runA,LBZ_size,LBZ_runB,LBZ_size2,LBZ_runC) ;
      
      if (arg_code_pos > 0) my_argv[arg_code_pos] = CODE ;
      
      if ( opt_allowed(LBZ_allow_opts,"-h") ) {
        if ( my_argc >= 5 && strcmp(my_argv[4], "--help") == 0 ) my_argv[1] = strdup( "-h" ) ;
      }
      
      /*
      printf("-------------------------------------\n") ;
      for(i = 0; i < my_argc ; ++i ) {
        printf("arg>> %s\n" , my_argv[i] ) ;    
      }
      printf("-------------------------------------\n") ;
      */

    }

    exitstatus = perl_parse(my_perl, xs_init, my_argc, my_argv, (char **)NULL) ;
    
    if ( !exitstatus ) {
      if (arg_code_pos < 0) {
        eval_pv("$LibZip::ONLY_INIT = 1;" , 0) ;
        eval_pv(CODE , 0) ;
      }
    
      exitstatus = perl_run(my_perl);    
      
      if (arg_code_pos < 0) {
        eval_pv("LibZip::end();" , 0) ;
      }
    }
    
    perl_destruct(my_perl);
    perl_free(my_perl);

    return exitstatus ;
}

////////////////////////////////////////////////////////////////////////////////


static void
#ifdef CAN_PROTOTYPE
SetGzErrorNo(int error_no)
#else
SetGzErrorNo(error_no)
int error_no ;
#endif
{
    char * errstr ;
    SV * gzerror_sv = perl_get_sv(GZERRNO, FALSE) ;
  
    if (error_no == Z_ERRNO) {
        error_no = errno ;
        errstr = Strerror(errno) ;
    }
    else
        /* errstr = gzerror(fil, &error_no) ; */
        errstr = (char*) my_z_errmsg[2 - error_no]; 

    if (SvIV(gzerror_sv) != error_no) {
        sv_setiv(gzerror_sv, error_no) ;
        sv_setpv(gzerror_sv, errstr) ;
        SvIOK_on(gzerror_sv) ;
    }

}

static void
#ifdef CAN_PROTOTYPE
SetGzError(gzFile file)
#else
SetGzError(file)
gzFile file ;
#endif
{
    int error_no ;

    (void)gzerror(file, &error_no) ;
    SetGzErrorNo(error_no) ;
}

static void
#ifdef CAN_PROTOTYPE
DispHex(void * ptr, int length)
#else
DispHex(ptr, length)
    void * ptr;
    int length;
#endif
{
    char * p = (char*)ptr;
    int i;
    for (i = 0; i < length; ++i) {
        printf(" %02x", 0xFF & *(p+i));
    }
}


static void
#ifdef CAN_PROTOTYPE
DispStream(di_stream * s, char * message)
#else
DispStream(s, message)
    di_stream * s;
    char * message;
#endif
{

#if 0
    if (! trace)
        return ;
#endif

    printf("DispStream 0x%p - %s \n", s, message) ;

    if (!s)  {
	printf("    stream pointer is NULL\n");
    }
    else     {
	printf("    stream           0x%p\n", &(s->stream));
	printf("           zalloc    0x%p\n", s->stream.zalloc);
	printf("           zfree     0x%p\n", s->stream.zfree);
	printf("           opaque    0x%p\n", s->stream.opaque);
	if (s->stream.msg)
	    printf("           msg       %s\n", s->stream.msg);
	else
	    printf("           msg       \n");
	printf("           next_in   0x%p", s->stream.next_in);
    	if (s->stream.next_in) {
	    printf(" =>");
            DispHex(s->stream.next_in, 4);
	}
        printf("\n");

	printf("           next_out  0x%p", s->stream.next_out);
    	if (s->stream.next_out){
	    printf(" =>");
            DispHex(s->stream.next_out, 4);
	}
        printf("\n");

	printf("           avail_in  %ld\n", s->stream.avail_in);
	printf("           avail_out %ld\n", s->stream.avail_out);
	printf("           total_in  %ld\n", s->stream.total_in);
	printf("           total_out %ld\n", s->stream.total_out);
	printf("           adler     0x%lx\n", s->stream.adler);
	printf("           reserved  0x%lx\n", s->stream.reserved);
	printf("    bufsize          %ld\n", s->bufsize);
	printf("    dictionary       0x%p\n", s->dictionary);
	printf("    dict_adler       0x%ld\n", s->dict_adler);
	printf("\n");

    }
}


static di_stream *
#ifdef CAN_PROTOTYPE
InitStream(uLong bufsize)
#else
InitStream(bufsize)
    uLong bufsize ;
#endif
{
    di_stream *s ;

    ZMALLOC(s, di_stream) ;

    if (s)  {
        s->bufsize = bufsize ;
        s->bufinc  = bufsize ;
    }

    return s ;
    
}

#define SIZE 4096

static int
#ifdef CAN_PROTOTYPE
gzreadline(LibZip__MyZlib__gzFile file, SV * output)
#else
gzreadline(file, output)
  LibZip__MyZlib__gzFile file ;
  SV * output ;
#endif
{

    SV * store = file->buffer ;
    char *nl = "\n"; 
    char *p;
    char *out_ptr = SvPVX(store) ;
    int n;

    while (1) {

	/* anything left from last time */
	if ((n = SvCUR(store))) {

    	    out_ptr = SvPVX(store) + file->offset ;
	    if ((p = ninstr(out_ptr, out_ptr + n - 1, nl, nl))) {
            /* if (rschar != 0777 && */
                /* p = ninstr(out_ptr, out_ptr + n - 1, rs, rs+rslen-1)) { */

         	sv_catpvn(output, out_ptr, p - out_ptr + 1);

		file->offset += (p - out_ptr + 1) ;
	        n = n - (p - out_ptr + 1);
	        SvCUR_set(store, n) ;
	        return SvCUR(output);
            }
	    else /* no EOL, so append the complete buffer */
         	sv_catpvn(output, out_ptr, n);
	    
	}


	SvCUR_set(store, 0) ;
	file->offset = 0 ;
        out_ptr = SvPVX(store) ;

	n = gzread(file->gz, out_ptr, SIZE) ;

	if (n <= 0) 
	    /* Either EOF or an error */
	    /* so return what we have so far else signal eof */
	    return (SvCUR(output)>0) ? SvCUR(output) : n ;

	SvCUR_set(store, n) ;
    }
}

static SV* 
#ifdef CAN_PROTOTYPE
deRef(SV * sv, char * string)
#else
deRef(sv, string)
SV * sv ;
char * string;
#endif
{
    if (SvROK(sv)) {
	sv = SvRV(sv) ;
	switch(SvTYPE(sv)) {
            case SVt_PVAV:
            case SVt_PVHV:
            case SVt_PVCV:
                croak("%s: buffer parameter is not a SCALAR reference", string);
	}
	if (SvROK(sv))
	    croak("%s: buffer parameter is a reference to a reference", string) ;
    }

    if (!SvOK(sv)) { 
        sv = newSVpv("", 0);
    }	
    return sv ;
}

#include "constants.h"

#line 334 "MyZlib.c"

/* INCLUDE:  Including 'constants.xs' from 'MyZlib.xs' */

XS(XS_LibZip__MyZlib_constant); /* prototype to pass -Wmissing-prototypes */
XS(XS_LibZip__MyZlib_constant)
{
    dXSARGS;
    if (items != 1)
	Perl_croak(aTHX_ "Usage: LibZip::MyZlib::constant(sv)");
    SP -= items;
    {
#line 4 "constants.xs"
#ifdef dXSTARG
	dXSTARG; /* Faster if we have it.  */
#else
	dTARGET;
#endif
	STRLEN		len;
        int		type;
	IV		iv;
	/* NV		nv;	Uncomment this if you need to return NVs */
	const char	*pv;
#line 357 "MyZlib.c"
	SV *	sv = ST(0);
	const char *	s = SvPV(sv, len);
#line 18 "constants.xs"
        /* Change this to constant(aTHX_ s, len, &iv, &nv);
           if you need to return both NVs and IVs */
	type = constant(aTHX_ s, len, &iv, &pv);
      /* Return 1 or 2 items. First is error message, or undef if no error.
           Second, if present, is found value */
        switch (type) {
        case PERL_constant_NOTFOUND:
          sv = sv_2mortal(newSVpvf("%s is not a valid Zlib macro", s));
          PUSHs(sv);
          break;
        case PERL_constant_NOTDEF:
          sv = sv_2mortal(newSVpvf(
	    "Your vendor has not defined Zlib macro %s, used", s));
          PUSHs(sv);
          break;
        case PERL_constant_ISIV:
          EXTEND(SP, 1);
          PUSHs(&PL_sv_undef);
          PUSHi(iv);
          break;
	/* Uncomment this if you need to return NOs
        case PERL_constant_ISNO:
          EXTEND(SP, 1);
          PUSHs(&PL_sv_undef);
          PUSHs(&PL_sv_no);
          break; */
	/* Uncomment this if you need to return NVs
        case PERL_constant_ISNV:
          EXTEND(SP, 1);
          PUSHs(&PL_sv_undef);
          PUSHn(nv);
          break; */
        case PERL_constant_ISPV:
          EXTEND(SP, 1);
          PUSHs(&PL_sv_undef);
          PUSHp(pv, strlen(pv));
          break;
	/* Uncomment this if you need to return PVNs
        case PERL_constant_ISPVN:
          EXTEND(SP, 1);
          PUSHs(&PL_sv_undef);
          PUSHp(pv, iv);
          break; */
	/* Uncomment this if you need to return SVs
        case PERL_constant_ISSV:
          EXTEND(SP, 1);
          PUSHs(&PL_sv_undef);
          PUSHs(sv);
          break; */
	/* Uncomment this if you need to return UNDEFs
        case PERL_constant_ISUNDEF:
          break; */
	/* Uncomment this if you need to return UVs
        case PERL_constant_ISUV:
          EXTEND(SP, 1);
          PUSHs(&PL_sv_undef);
          PUSHu((UV)iv);
          break; */
	/* Uncomment this if you need to return YESs
        case PERL_constant_ISYES:
          EXTEND(SP, 1);
          PUSHs(&PL_sv_undef);
          PUSHs(&PL_sv_yes);
          break; */
        default:
          sv = sv_2mortal(newSVpvf(
	    "Unexpected return type %d while processing Zlib macro %s, used",
               type, s));
          PUSHs(sv);
        }
#line 431 "MyZlib.c"
	PUTBACK;
	return;
    }
}


/* INCLUDE: Returning to 'MyZlib.xs' from 'constants.xs' */

#define Zip_zlib_version()	(char*)zlib_version
XS(XS_LibZip__MyZlib_zlib_version); /* prototype to pass -Wmissing-prototypes */
XS(XS_LibZip__MyZlib_zlib_version)
{
    dXSARGS;
    if (items != 0)
	Perl_croak(aTHX_ "Usage: LibZip::MyZlib::zlib_version()");
    {
	char *	RETVAL;
	dXSTARG;

	RETVAL = Zip_zlib_version();
	sv_setpv(TARG, RETVAL); XSprePUSH; PUSHTARG;
    }
    XSRETURN(1);
}

XS(XS_LibZip__MyZlib__inflateInit); /* prototype to pass -Wmissing-prototypes */
XS(XS_LibZip__MyZlib__inflateInit)
{
    dXSARGS;
    if (items != 3)
	Perl_croak(aTHX_ "Usage: LibZip::MyZlib::_inflateInit(windowBits, bufsize, dictionary)");
    SP -= items;
    {
	int	windowBits = (int)SvIV(ST(0));
	uLong	bufsize = (unsigned long)SvUV(ST(1));
	SV *	dictionary = ST(2);
#line 360 "MyZlib.xs"
    int err = Z_OK ;
    inflateStream s ;

    if (trace)
        warn("in _inflateInit(windowBits=%d, bufsize=%d, dictionary=%d\n",
                windowBits, bufsize, SvCUR(dictionary)) ;
    if ((s = InitStream(bufsize)) ) {

        s->WindowBits = windowBits;

        err = inflateInit2(&(s->stream), windowBits);

        if (err != Z_OK) {
            Safefree(s) ;
            s = NULL ;
	}
	else if (SvCUR(dictionary)) {
            /* Dictionary specified - take a copy for use in inflate */
	    s->dictionary = newSVsv(dictionary) ;
	}
    }
    else
	err = Z_MEM_ERROR ;

    XPUSHs(sv_setref_pv(sv_newmortal(), 
                   "LibZip::MyZlib::inflateStream", (void*)s));
    if (GIMME == G_ARRAY) 
        XPUSHs(sv_2mortal(newSViv(err))) ;
#line 497 "MyZlib.c"
	PUTBACK;
	return;
    }
}

XS(XS_LibZip__MyZlib__inflateStream_DispStream); /* prototype to pass -Wmissing-prototypes */
XS(XS_LibZip__MyZlib__inflateStream_DispStream)
{
    dXSARGS;
    if (items < 1 || items > 2)
	Perl_croak(aTHX_ "Usage: LibZip::MyZlib::inflateStream::DispStream(s, message=NULL)");
    {
	LibZip__MyZlib__inflateStream	s;
	char *	message;

	if (sv_derived_from(ST(0), "LibZip::MyZlib::inflateStream")) {
	    IV tmp = SvIV((SV*)SvRV(ST(0)));
	    s = INT2PTR(LibZip__MyZlib__inflateStream,tmp);
	}
	else
	    Perl_croak(aTHX_ "s is not of type LibZip::MyZlib::inflateStream");

	if (items < 2)
	    message = NULL;
	else {
	    message = (char *)SvPV_nolen(ST(1));
	}

	DispStream(s, message);
    }
    XSRETURN_EMPTY;
}

XS(XS_LibZip__MyZlib__inflateStream_inflate); /* prototype to pass -Wmissing-prototypes */
XS(XS_LibZip__MyZlib__inflateStream_inflate)
{
    dXSARGS;
    dXSI32;
    if (items != 2)
       Perl_croak(aTHX_ "Usage: %s(s, buf)", GvNAME(CvGV(cv)));
    SP -= items;
    {
	LibZip__MyZlib__inflateStream	s;
	SV *	buf = ST(1);
	uLong	outsize;
	SV *	output;
	int	err = Z_OK ;

	if (sv_derived_from(ST(0), "LibZip::MyZlib::inflateStream")) {
	    IV tmp = SvIV((SV*)SvRV(ST(0)));
	    s = INT2PTR(LibZip__MyZlib__inflateStream,tmp);
	}
	else
	    Perl_croak(aTHX_ "s is not of type LibZip::MyZlib::inflateStream");
#line 409 "MyZlib.xs"
    /* If the buffer is a reference, dereference it */
    buf = deRef(buf, "inflate") ;

    /* initialise the input buffer */
    s->stream.next_in = (Bytef*)SvPVX(buf) ;
    s->stream.avail_in = SvCUR(buf) ;

    /* and the output buffer */
    output = sv_2mortal(newSV(s->bufinc+1)) ;
    SvPOK_only(output) ;
    SvCUR_set(output, 0) ; 
    outsize = s->bufinc ;
    s->stream.next_out = (Bytef*) SvPVX(output)  ;
    s->stream.avail_out = outsize;

    while (1) {

        if (s->stream.avail_out == 0) {
            s->bufinc *= 2 ;
            SvGROW(output, outsize + s->bufinc+1) ;
            s->stream.next_out = (Bytef*) SvPVX(output) + outsize ;
            outsize += s->bufinc ;
            s->stream.avail_out = s->bufinc ;
        }

        err = inflate(&(s->stream), Z_SYNC_FLUSH);
	if (err == Z_BUF_ERROR) {
	    if (s->stream.avail_out == 0)
	        continue ;
	    if (s->stream.avail_in == 0) {
		err = Z_OK ;
	        break ;
	    }
	}

	if (err == Z_NEED_DICT && s->dictionary) {
	    s->dict_adler = s->stream.adler ;
            err = inflateSetDictionary(&(s->stream), 
	    				(const Bytef*)SvPVX(s->dictionary),
					SvCUR(s->dictionary));
	}

        if (err != Z_OK) 
            break;
    }

    if (err == Z_OK || err == Z_STREAM_END || err == Z_DATA_ERROR) {
	unsigned in ;

        SvPOK_only(output);
        SvCUR_set(output, outsize - s->stream.avail_out) ;
        *SvEND(output) = '\0';

 	/* fix the input buffer */
	if (ix == 0) {
 	    in = s->stream.avail_in ;
 	    SvCUR_set(buf, in) ;
 	    if (in)
     	        Move(s->stream.next_in, SvPVX(buf), in, char) ;	
            *SvEND(buf) = '\0';
            SvSETMAGIC(buf);
	}
    }
    else
        output = &PL_sv_undef ;
    XPUSHs(output) ;
    if (GIMME == G_ARRAY) 
        XPUSHs(sv_2mortal(newSViv(err))) ;
#line 621 "MyZlib.c"
	PUTBACK;
	return;
    }
}

XS(XS_LibZip__MyZlib__inflateStream_DESTROY); /* prototype to pass -Wmissing-prototypes */
XS(XS_LibZip__MyZlib__inflateStream_DESTROY)
{
    dXSARGS;
    if (items != 1)
	Perl_croak(aTHX_ "Usage: LibZip::MyZlib::inflateStream::DESTROY(s)");
    {
	LibZip__MyZlib__inflateStream	s;

	if (SvROK(ST(0))) {
	    IV tmp = SvIV((SV*)SvRV(ST(0)));
	    s = INT2PTR(LibZip__MyZlib__inflateStream,tmp);
	}
	else
	    Perl_croak(aTHX_ "s is not a reference");
#line 484 "MyZlib.xs"
    inflateEnd(&s->stream) ;
    if (s->dictionary)
	SvREFCNT_dec(s->dictionary) ;
    Safefree(s) ;
#line 647 "MyZlib.c"
    }
    XSRETURN_EMPTY;
}

////////////////////////////////////////////////////////////////////////////////

EXTERN_C void
xs_init(pTHX)
{
    char *file = __FILE__;
    /* DynaLoader is a special case */
    newXS("DynaLoader::boot_DynaLoader", boot_DynaLoader, file);
    
    {
        CV * cv ;

        newXS("LibZip::MyZlib::constant", XS_LibZip__MyZlib_constant, file);
        newXS("LibZip::MyZlib::zlib_version", XS_LibZip__MyZlib_zlib_version, file);
        newXS("LibZip::MyZlib::_inflateInit", XS_LibZip__MyZlib__inflateInit, file);
        newXS("LibZip::MyZlib::inflateStream::DispStream", XS_LibZip__MyZlib__inflateStream_DispStream, file);
        cv = newXS("LibZip::MyZlib::inflateStream::inflate", XS_LibZip__MyZlib__inflateStream_inflate, file);
        XSANY.any_i32 = 0 ;
        cv = newXS("LibZip::MyZlib::inflateStream::__unc_inflate", XS_LibZip__MyZlib__inflateStream_inflate, file);
        XSANY.any_i32 = 1 ;
        newXS("LibZip::MyZlib::inflateStream::DESTROY", XS_LibZip__MyZlib__inflateStream_DESTROY, file);

    }

    /* Initialisation Section */

    /* Check this version of zlib is == 1 */
    if (zlibVersion()[0] != '1')
	croak("LibZip::MyZlib needs zlib version 1.x\n") ;
 
    {
        /* Create the $gzerror scalar */
        SV * gzerror_sv = perl_get_sv(GZERRNO, GV_ADDMULTI) ;
        sv_setiv(gzerror_sv, 0) ;
        sv_setpv(gzerror_sv, "") ;
        SvIOK_on(gzerror_sv) ;
    }
    
}


