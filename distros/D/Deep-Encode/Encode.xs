#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
/* vim: et ts=8 sw=4
 * */

#include "ppport.h"
#define DEEP_FUNCTION      4
#define DEEP_METHOD_TEMP   3
#define DEEP_CALL_INPLACE  2
#define DEEP_PRINT_STRING  1 


#ifndef PERL_UNUSED_VAR
#  define PERL_UNUSED_VAR(var) if (0) var = var
#endif

#ifndef STATIC_INLINE /* a public perl API from 5.13.4 */
#   if defined(__GNUC__) || defined(__cplusplus__) || (defined(__STDC_VERSION__) && (__STDC_VERSION__ >= 199901L))
#       define STATIC_INLINE static inline
#   else
#       define STATIC_INLINE static
#   endif
#endif /* STATIC_INLINE */



#ifndef inline /* don't like borgs definitions */ /* inline is keyword for STDC compiler  */
#   if defined(__GNUC__) || defined(__cplusplus__) || (defined(__STDC_VERSION__) && (__STDC_VERSION__ >= 199901L))
#   else
#	if defined(WIN32) && defined(_MSV) /* Microsoft Compiler */
#	    define inline _inline
#	else 
#	    define inline 
#	endif
#   endif
#endif /* inline  */

#ifndef ARRAY_SIZE
    #define ARRAY_SIZE(x) (sizeof(x)/sizeof(x[0]))
#endif

struct pp_args;
typedef void (*p_callback)(struct pp_args*, SV *);
static U8 m1[] ={ 0, ~31, ~15, ~7, ~3 };
static U8 m2[] ={ 0, 0xff & ~63, 0xff& ~31, 0xff &~15, 0xff & ~7 };


bool _is_utf8( U8 * start, U8 *end ){
    STRLEN ucnt;
    U8 first;
    ucnt = -1;

    START:
    while( start < end ){
	if ( *start < 	128 ){
	    ++start;
	}
	else 
	    goto ENC;
    }
    return 1;

    ENC:
    ucnt = 0; 
    first = *start;
    start++;
    while( start < end && (*start & 0xC0) == 0x80 ) ucnt++, start++;
    
    if ( ucnt == 0 || ucnt > 4 ){
/* 	fprintf( stderr, "z1=%d %x\n", ucnt, first ); */
	return 0 ;
    }
    if ( (first & m1[ucnt]) != m2[ucnt]){
/* 	fprintf( stderr, "z2=%d %x\n", ucnt, first); */
	return 0;
    }
    goto START;
}

inline bool is_utf8(char *z, STRLEN m){
    return _is_utf8( (U8 *)(z), (U8*)(z + m));
}

typedef struct pp_args{
    char  type;
    char  fastinit;

    int   noskip;
    int   argc;
    int   str_pos;
    int   counter;
    char *method;
    CV   *meth1;
    CV   *meth2;
    p_callback callback;    
    SV* argv[10 + 2];
} *pp_func;

void utf8_check_encoding_cb( pp_func pf, SV *data){
    char *ptr;
    STRLEN data_len;
    if (!pf->counter)
	return;
    ptr = SvPV( data, data_len);
    if (!is_utf8( ptr, data_len ))
	pf->counter = 0;

}

void utf8_upgrade_cb( pp_func pf, SV * data){
    if (!SvUTF8(data)){
	(void) sv_utf8_upgrade( data );
	++(pf->counter);
    };
}

void utf8_downgrade_cb( pp_func pf, SV * data){
    if (SvUTF8(data)){
	(void) sv_utf8_downgrade( data , 0);
	++(pf->counter);
    };
}

void utf8_off_cb( pp_func pf, SV * data){
    if (SvUTF8(data)){
	SvUTF8_off(data);
	++(pf->counter);
    };
}

void utf8_on_cb( pp_func pf, SV * data){
    if (!SvUTF8(data)){
		SvUTF8_on(data);
		++(pf->counter);
	}
}

void from_to_cb( pp_func pf, SV * data){
    int ret_list_size;
    SV *decoded_sv;
    dSP;
    ENTER;
    SAVETMPS;

    if ( !  pf->fastinit ){
	GV * method_glob;
	HV * encoding_stash;
	pf->meth1 = 0;
	pf->meth2 = 0;
	pf->fastinit = -1;

	encoding_stash = SvSTASH( SvRV( pf->argv[0] ) );
	method_glob = gv_fetchmeth( encoding_stash, "decode", 6, 0 );
	pf->meth1 = GvCV( method_glob );
	

	encoding_stash = SvSTASH( SvRV( pf->argv[1] ) );
	method_glob = gv_fetchmeth( encoding_stash, "encode", 6, 0 );
	pf->meth2 = GvCV( method_glob );

	if ( pf->meth1 && pf->meth2 ){
	    pf->fastinit = 1;
	};
    };

    PUSHMARK(SP);
    XPUSHs( pf->argv[0] ); /*first encoding */
    XPUSHs( data );
    PUTBACK;

    if ( pf->fastinit == 1 ){
    	ret_list_size = call_sv( (SV *) pf->meth1, G_SCALAR);
    }
    else {
    	ret_list_size = call_method("decode", G_SCALAR);
    };

    SPAGAIN;
    if (ret_list_size != 1){
	croak( "A big trouble");
    }
    decoded_sv = POPs;
    PUTBACK;

    PUSHMARK(SP);
    XPUSHs( pf->argv[1] );
    XPUSHs( decoded_sv );
    PUTBACK;


    if ( pf->fastinit == 1 ){
    	ret_list_size = call_sv( (SV *) pf->meth2, G_SCALAR);
    }
    else {
	ret_list_size = call_method("encode", G_SCALAR);
    }
    SPAGAIN;
    if (ret_list_size != 1){
	croak( "A big trouble");
    }
    decoded_sv = POPs;
    sv_setsv( data , decoded_sv );
    PUTBACK;
    FREETMPS;
    LEAVE;
}

void from_to_cb_00( pp_func pf, SV * data){
    int ret_list_size;
    SV *decoded_sv;
    dSP;
    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs( pf->argv[0] ); /*first encoding */
    XPUSHs( data );

    PUTBACK;

    ret_list_size = call_method("decode", G_SCALAR);
    SPAGAIN;
    if (ret_list_size != 1){
	croak( "A big trouble");
    }
    decoded_sv = POPs;
    PUTBACK;

    PUSHMARK(SP);
    XPUSHs( pf->argv[1] );
    XPUSHs( decoded_sv );
    PUTBACK;


    ret_list_size = call_method("encode", G_SCALAR);
    SPAGAIN;
    if (ret_list_size != 1){
	croak( "A big trouble");
    }
    decoded_sv = POPs;
    sv_setsv( data , decoded_sv );
    PUTBACK;
    FREETMPS;
    LEAVE;
}

/*static U8* good_encoding=",cp1251,latin1,utf8,windows1251,cp866,"; */
SV *find_encoding(pp_func pfunc, SV* encoding )
{
    int ret_list;
    SV *enc_obj;
    dSP;
    enc_obj = 0;

    if ( SvROK(encoding) &&  sv_isobject( encoding )) {
	enc_obj = encoding;
    };
    if ( !enc_obj ) {
	PUSHMARK(SP);
	XPUSHs(encoding);
	PUTBACK;

	ret_list = call_pv("Encode::find_encoding", G_SCALAR);
	SPAGAIN;
	if (ret_list != 1)
	    croak( "Big trouble with Encode::find_encoding");
	enc_obj = POPs;	    

	if (!SvOK(enc_obj)) {
	    if ( SvPOK(encoding) )
		croak("Unknown encoding '%.*s'", SvCUR(encoding), SvPV_nolen(encoding));
	    else 
		croak("Unknown encoding ??? (is not string)");
	};
	PUTBACK;
    };
    if (! pfunc->noskip ){
	SV *name_sv;
	char *name;
	STRLEN name_len;

	PUSHMARK(SP);
	XPUSHs(enc_obj);
	PUTBACK;

	ret_list = call_method("name", G_SCALAR);
	SPAGAIN;
	if (ret_list != 1)
	    croak( "Big trouble with Encode::find_encoding");
	name_sv = POPs;	    
	PUTBACK;
	name = SvPV(name_sv, name_len);
	switch( name_len ){
	    case 6:
		if (strEQ("cp1251", name ))
		    return enc_obj;
		break;
	    case 5:
		if (strEQ("cp866", name ))
		    return enc_obj;
		break;
	    case 4:
		if (strEQ("utf8", name ))
		    return enc_obj;
		break;
	    case 10:
		if (strEQ("iso-8859-1", name)){
		    return enc_obj;
		};
		break;
	    default:
		break;
	};
	pfunc->noskip = 1;
	
    };
    return enc_obj;
}

SV * 
deep_clone_imp( SV * data, pp_func pf ){
    if (SvROK(data)){
	SV * rv = (SV*) SvRV(data);
	if ( SvTYPE(rv) == SVt_PVAV ){
	    int alen;
	    SV **aitem;
	    int i;
	    AV *copy;
	    SV *R;
	    bool need_clone = 0;
	    copy = newAV();

	    alen = av_len( (AV*)rv );
	    av_extend( copy, alen+1);
	    for ( i=0; i<= alen ;++i ){
		aitem = av_fetch( (AV *) rv , i, 0);
		if (aitem){
		    R = deep_clone_imp( *aitem, pf );
		    if ( R ){
			av_store( copy, i, R );
			need_clone = 1;
		    }
		    else {
			SvREFCNT_inc_simple_void_NN( *aitem );
			av_store( copy, i, *aitem );
		    }
		}
	    }
	    if ( need_clone ){
                return newRV_noinc( (SV *)copy );
            }
	    else{
		SvREFCNT_dec( copy );
		return 0;
	    }
	}
	else if ( SvTYPE(rv) == SVt_PVHV ){
	    STRLEN key_len;
	    HV *hv;
	    HE *he;
	    SV * value;
	    char * key_str;
	    HV   * copy;
	    SV *R;
	    bool need_clone = 0;
	    copy = newHV();
	    hv = (HV *) rv;
	    hv_iterinit(hv);
	    while(  (he = hv_iternext(hv)) ){
		key_str = HePV( he, key_len);
		value = HeVAL( he );
                if (!value){
                    value = hv_iterval(hv, he);
                }
		R = deep_clone_imp( value, pf );
		if ( R ){
		    hv_store( copy, key_str, key_len, R , 0 );
                    need_clone = 1;
		}
		else {
		    SvREFCNT_inc_simple_void_NN( value );
		    hv_store( copy, key_str, key_len, value, 0 );
		}
	    }	 
	    if ( need_clone ){
                return newRV_noinc( (SV *)copy );
            }
	    else{
		SvREFCNT_dec( copy );
		return 0;
	    }
	}
	else {
	    /* Simple assume of REF type */
	    return deep_clone_imp( rv, pf );
	}
    }
    else {
	bool pok = 0;
	if (SvMAGICAL(data)){
	    mg_get(data);
            if (SvPOKp(data)){
                pok = 1;
            }
	}
        else {
            if (SvPOK(data)){
                pok = 1;
            }
        }

	if ( pok  ){
	    U8 *pstr;
	    STRLEN plen;
	    STRLEN curr;
	    int skip;
	    plen = SvCUR( data );
	    pstr = (U8 *)SvPVX( data );

            SV * R = newSVpvn( (char *)pstr, plen );
            if ( SvUTF8( data )){
                SvUTF8_on( R );
            }
            return R;
	}
	else {
            return 0;
        }
    }
}

void 
deep_walk_imp(SV * data, pp_func pf){
    if (SvROK(data)){
	SV * rv = (SV*) SvRV(data);
	if ( SvTYPE(rv) == SVt_PVAV ){
	    int alen;
	    SV **aitem;
	    int i;

	    alen = av_len( (AV*)rv );
	    for ( i=0; i<= alen ;++i ){
		aitem = av_fetch( (AV *) rv , i, 0);
		if (aitem){
			deep_walk_imp( *aitem, pf );
		}
	    }
	}
	else if ( SvTYPE(rv) == SVt_PVHV ){
	    STRLEN key_len;
	    HV *hv;
	    HE *he;
	    SV * value;
	    char * key_str;
	    hv = (HV *) rv;
	    hv_iterinit(hv);
	    while(  (he = hv_iternext(hv)) ){
		key_str = HePV( he, key_len);
		value = HeVAL( he );
                if (value){
                    deep_walk_imp( value, pf );
                }
                else {
                    value = hv_iterval(hv,he);
                    deep_walk_imp( value, pf );
                }
	    }	    
	}
	else {
	    deep_walk_imp( rv, pf );
	}
    }
    else {
	bool pok = 0;
	if (SvMAGICAL(data)){
	    mg_get(data);
	    if (SvPOKp(data)){
		pok = 1;
	    };
	}
	else {
	    if (SvPOK(data))
		pok = 1;
	};
	/* fprintf( stderr, "pok=%d %d\n", pok, SvPOK(data) ); */
	if ( pok  ){
	    U8 *pstr;
	    int argc;
	    STRLEN plen;
	    STRLEN curr;
	    int skip;
	    int ret_list_size;
	    pstr = (U8 *) SvPVX(data);
	    plen = SvCUR( data );

	    if ( !pf->noskip ){
	/* 	fprintf( stderr, "noskip\n");*/
		skip = 1;
		for( curr = 0; curr < plen; ++ curr ){
		    if ( pstr[curr] >= 128 ){
			skip = 0;
			break;
		    };			
		}
		if ( skip && SvUTF8( data ) ){
		    SvUTF8_off( data ); /*  Restore flag */
		}
	    }
	    else {
		skip = 0;
	    };
	    if (!skip) {
	    switch( pf->type ){
		case DEEP_FUNCTION:
		    pf->callback( pf, data );
		   break; 
		case DEEP_METHOD_TEMP:
		   {dSP;
		    ENTER;
		    SAVETMPS;
		    if ( ! pf->fastinit ){
			GV * method_glob;
			HV * encoding_stash;
			pf->meth1 = 0;
			pf->fastinit = -1;

			encoding_stash = SvSTASH( SvRV( pf->argv[0] ) );
			method_glob = gv_fetchmeth( encoding_stash, pf->method, strlen(pf->method), 0 );
			pf->meth1 = GvCV( method_glob );
			
			if ( pf->meth1 ){
			    pf->fastinit = 1;
			};

		    };

		    PUSHMARK(SP);

		    for ( argc = 0; argc < pf->argc; ++argc ){
			if ( argc == pf->str_pos ){
			    XPUSHs( data );
			}
			else {
			    XPUSHs( pf->argv[argc] );
			}
		    };
		    PUTBACK;

		    if ( pf->fastinit != 1){
    			ret_list_size = call_method(pf->method, G_SCALAR);
		    }
		    else {
			ret_list_size = call_sv( (SV*) pf->meth1, G_SCALAR );
		    }
		    SPAGAIN;
		    if (ret_list_size != 1){
			croak( "A big trouble");
		    }
		    sv_setsv( data, POPs );
		    PUTBACK;

		    FREETMPS;
		    LEAVE;
		   };
		    break;
		case DEEP_CALL_INPLACE:
		    {
			dSP;
			ENTER;
			SAVETMPS;
			PUSHMARK(SP);
			for ( argc = 1; argc < pf->argc; ++argc ){
			    if ( argc == pf->str_pos ){
				XPUSHs( data );
			    }
			    else {
				XPUSHs( pf->argv[argc] );
			    }
			};
		    
			/* ARGUMENTS */
			PUTBACK;
			call_sv( pf->argv[0], G_DISCARD );
			FREETMPS;
			LEAVE;
			};
		    break;
		case 1: /* print str */
		default:
		    fprintf( stderr, "'%.*s'\n", (int) plen, pstr);
		    break;
		}
                if (SvMAGICAL(data)){
                    mg_set(data);
                }
	    }
	}
    }
}


MODULE = Deep::Encode		PACKAGE = Deep::Encode		


void 
deep_utf8_decode( SV *data )
    PROTOTYPE: $
    PPCODE:
	struct pp_args a_args;
	a_args.noskip  = 0;
	a_args.type = DEEP_CALL_INPLACE ;
	a_args.str_pos = 1;
	a_args.argc    = 2;
	a_args.argv[0] = (SV *) get_cv( "utf8::decode", 0); 
	if ( ! a_args.argv[0] )
	    croak ("Fail locate &utf8::decode");
	deep_walk_imp( data, & a_args );        

void
deep_utf8_encode( SV *data )
    PROTOTYPE: $
    PPCODE:
	struct pp_args a_args;
	a_args.noskip  = 0;
	a_args.type = DEEP_CALL_INPLACE ;
	
	a_args.str_pos = 1;
	a_args.argc    = 2;
	a_args.argv[0] = (SV *) get_cv( "utf8::encode", 0); 
	if ( ! a_args.argv[0] )
	    croak ("Fail locate &utf8::encode");
	deep_walk_imp( data, & a_args );        

void
deep_from_to_00( SV *data, SV *from, SV* to )
    PROTOTYPE: $$$
    PPCODE:
	struct pp_args a_args;
	a_args.noskip  = 0;
	a_args.type = DEEP_FUNCTION;
	a_args.callback = from_to_cb_00;
	a_args.argv[0] = find_encoding( &a_args, from );
	a_args.argv[1] = find_encoding( &a_args, to );
	deep_walk_imp( data, & a_args );        

void
deep_from_to( SV *data, SV *from, SV* to )
    PROTOTYPE: $$$
    PPCODE:
	struct pp_args a_args;
	a_args.noskip  = 0;
	a_args.type = DEEP_FUNCTION;
	a_args.fastinit = 0;
	a_args.callback = from_to_cb;
	a_args.argv[0] = find_encoding( &a_args, from );
	a_args.argv[1] = find_encoding( &a_args, to );
	deep_walk_imp( data, & a_args );        

void
deep_encode_00( SV *data, SV* encoding )
    PROTOTYPE: $$
    PPCODE:
	struct pp_args a_args;
	a_args.type = DEEP_METHOD_TEMP;
	a_args.fastinit = -1;
	a_args.method  = "encode";
	a_args.noskip  = 0;
	a_args.str_pos = 1;
	a_args.argc    = 2;
	a_args.argv[0] = find_encoding( & a_args, encoding );
	a_args.argv[1] = 0;
	deep_walk_imp( data, & a_args );        


void
deep_decode_00( SV *data, SV* encoding )
    PROTOTYPE: $$
    PPCODE:
	struct pp_args a_args;
	a_args.type = DEEP_METHOD_TEMP;
	a_args.fastinit = -1;
	a_args.method   = "decode";
	a_args.noskip   = 0;
	a_args.str_pos  = 1;
	a_args.argc     = 2;
	a_args.argv[0] = find_encoding( & a_args, encoding );
	a_args.argv[1] = 0;
	deep_walk_imp( data, & a_args );        



void
deep_encode( SV *data, SV* encoding )
    PROTOTYPE: $$
    PPCODE:
	struct pp_args a_args;
	a_args.type = DEEP_METHOD_TEMP;
	a_args.method  = "encode";
	a_args.noskip  = 0;
	a_args.str_pos = 1;
	a_args.fastinit = 0;
	a_args.argc    = 2;
	a_args.argv[0] = find_encoding( & a_args, encoding );
	a_args.argv[1] = 0;
	deep_walk_imp( data, & a_args );        


void
deep_decode( SV *data, SV* encoding )
    PROTOTYPE: $$
    PPCODE:
	struct pp_args a_args;
	a_args.type = DEEP_METHOD_TEMP;
	a_args.method   = "decode";
	a_args.noskip   = 0;
	a_args.str_pos  = 1;
	a_args.argc     = 2;
	a_args.fastinit = 0;
	a_args.argv[0] = find_encoding( & a_args, encoding );
	a_args.argv[1] = 0;
	deep_walk_imp( data, & a_args );        

void
deep_utf8_off( SV *data)
    PROTOTYPE: $
    PPCODE:
	struct pp_args a_args;
        a_args.noskip  = 1;
        a_args.type = DEEP_FUNCTION;
        a_args.callback = utf8_off_cb;
	a_args.counter = 0;
        deep_walk_imp( data, & a_args );
	mXPUSHi( a_args.counter );

void
deep_utf8_on( SV *data)
    PROTOTYPE: $
    PPCODE:
	struct pp_args a_args;
        a_args.noskip  = 1;
        a_args.type = DEEP_FUNCTION;
        a_args.callback = utf8_on_cb;
	a_args.counter = 0;
        deep_walk_imp( data, & a_args );
	mXPUSHi( a_args.counter );

void
deep_utf8_downgrade( SV *data)
    PROTOTYPE: $
    PPCODE:
	struct pp_args a_args;
        a_args.noskip  = 1;
        a_args.type = DEEP_FUNCTION;
        a_args.callback = utf8_downgrade_cb;
	a_args.counter = 0;
        deep_walk_imp( data, & a_args );
	mXPUSHi( a_args.counter );

void
deep_utf8_upgrade( SV *data)
    PROTOTYPE: $
    PPCODE:
	struct pp_args a_args;
        a_args.noskip  = 1;
        a_args.type = DEEP_FUNCTION;
        a_args.callback = utf8_upgrade_cb;
	a_args.counter = 0;
        deep_walk_imp( data, & a_args );
	mXPUSHi( a_args.counter );

void
deep_utf8_check( SV *data)
    PROTOTYPE: $
    PPCODE:
	struct pp_args a_args;
        a_args.noskip  = 1;
        a_args.type = DEEP_FUNCTION;
        a_args.callback = utf8_check_encoding_cb;
	a_args.counter = 1;
        deep_walk_imp( data, &a_args );
	mXPUSHi( a_args.counter );

void 
deep_str_clone( SV *data )
    PROTOTYPE: $
    PPCODE:
    struct pp_args a_args;
    SV * R;
    a_args.noskip = 0;
    R = deep_clone_imp( data, &a_args );
    if ( R ){
	sv_2mortal( R );
	XPUSHs( R );
    }
    else {
	XPUSHs( data );
    }

