#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#ifndef CxOLD_OP_TYPE
#  define CxOLD_OP_TYPE(cx)      (0 + (cx)->blk_eval.old_op_type)
#endif

#ifndef SvOURSTASH
# ifdef OURSTASH
#  define SvOURSTASH OURSTASH
# else
#  define SvOURSTASH GvSTASH
# endif
#endif

#ifndef COP_SEQ_RANGE_LOW
#  define COP_SEQ_RANGE_LOW(sv)                  U_32(SvNVX(sv))
#endif
#ifndef COP_SEQ_RANGE_HIGH
#  define COP_SEQ_RANGE_HIGH(sv)                 U_32(SvUVX(sv))
#endif

#ifndef PadARRAY
typedef AV PADNAMELIST;
typedef SV PADNAME;
# if PERL_VERSION < 8 || (PERL_VERSION == 8 && !PERL_SUBVERSION)
typedef AV PADLIST;
typedef AV PAD;
# endif
# define PadlistARRAY		AvARRAY
# define PadlistNAMES(pl)	(*PadlistARRAY(pl))
# define PadnamelistARRAY(pnl)	((PADNAME **)AvARRAY(pnl))
# define PadnamelistMAX(pnl)	AvFILLp(pnl)
# define PadARRAY		AvARRAY
# define PadMAX			AvFILLp
# define PadnamePV(pn)		(SvPOKp(pn) ? SvPVX(pn) : NULL)
# define PadnameLEN(pn)		SvCUR(pn)
# define PadnameIsOUR(pn)	!!(SvFLAGS(pn) & SVpad_OUR)
# define PadnameOUTER(pn)	!!SvFAKE(pn)
# define PadnameSV(pn)	pn
#endif



/* For development testing */
#ifdef PADWALKER_DEBUGGING
# define debug_print(x) printf x
#else
# define debug_print(x)
#endif

#define AvPUSHs( av, sv )  my_av_pushs( aTHX_ av, sv )
#define AvPUSHi( av, sv ) my_av_pushi(  aTHX_ av, sv )
#define AvPUSHpnv( av, p, n ) my_av_pushi( aTHX_ av, p, n )
#define AvELT( av, n ) (AvARRAY( av )[n]) 
#define M_alloc( pad, size) (my_memory_alloc( aTHX_ pad, size) )

void
my_av_pushs( pTHX_ AV*av, SV *val){
    I32 key;
    key = AvFILLp(av)+1;
    if ( key > AvMAX(av))
	av_extend( av, key +5);
    AvFILLp(av) = key;
    SvREFCNT_inc_simple_void_NN( val );
    AvARRAY(av)[key] = val;
}
void 
my_av_pushi( pTHX_ AV *av, IV val ){
    AvPUSHs( av, newSViv(val));
}
void *
my_memory_alloc( pTHX_ AV *temppad, size_t x){
    SV *temp;
    temp = newSVpvn("", 0);
    AvPUSHs( temppad, temp);
    return SvGROW( temp, x );
}

void 
my_av_pushpvn( pTHX_ AV *av, char *p, STRLEN n ){
    AvPUSHs( av, newSVpvn(p,n));
}

void _show_cvpad( CV *cv ){
    if ( cv && CvPADLIST( cv ) ){
        PADLIST *padlist = CvPADLIST( cv );
        PADNAMELIST * padnames = PadlistNAMES(padlist);
        I32 i;
        I32 namefill = PadnamelistMAX( padnames  );
	CV *cvout;
        if ( PL_DBsub && cv == GvCV(PL_DBsub) ){
            fprintf( stderr, " DB::sub");
            return;
        }

	cvout = cv;
        do{
	    if ( CvOUTSIDE( cvout )){
		fprintf( stderr,  " <%u>", CvOUTSIDE_SEQ(cvout));
	    }
	    cvout = CvOUTSIDE( cvout );  
	} while( cvout );
        for(i=0; i<=namefill; ++i){
            PADNAME *name_sv;
            STRLEN name_len;
            name_sv = PadnamelistARRAY( padnames )[i];
            if (name_sv && PadnamePV(name_sv)
                        && ( name_len = PadnameLEN(name_sv)) > 1) {
                char* name_str = PadnamePV(name_sv);
                bool is_my = !PadnameIsOUR(name_sv);
                if ( is_my ) {
                    fprintf(  stderr, " %s(%d,%d)", name_str, COP_SEQ_RANGE_LOW(name_sv),  COP_SEQ_RANGE_HIGH(name_sv) );
                }
            }
        }
    }
}

typedef struct my_closure{
    CV *closure_cv;
    PAD **closure_pad;
    long stack_depth;
    CV *outer;
    PAD **outer_pad;
    I32 outer_depth;
    I32 offset_size;
    I32 *position;
    SV **temporary;
    SV * return_value;
    bool ok;
} *p_closure;

long dive_in_stack();

void 
cl_prepare_closure( pTHX_ p_closure cl, int optype );

I32 
find_sv( CV * cv, I32 cv_depth, U32 cop_seq, SV *val ){
    I32 i;
    PADLIST *pad;
    PAD *padval;
    PADNAMELIST *padname;
    pad= CvPADLIST( cv );
    if (!pad)
	return -1;
    padval = PadlistARRAY( pad )[cv_depth];
    padname = PadlistNAMES(pad);
    for ( i=0; i<=PadMAX( padval ); ++i){
	if ( PadARRAY( padval )[i] == val ){
	    if ( PadnameOUTER(AvELT( padname, i))){
	//	fprintf( stderr, "==!!!===%d\n", i);
		return -2;
	    }
	    else {
	//	fprintf( stderr, "========%d\n", i);
		return i;
	    }
	}
    }
    return -1;  
}
void cl_init( pTHX_ p_closure cl, AV*temppad ){
    // We get clusure with ok && closure_cv fields set 
    // And We init all others 
    CV * cv = cl->closure_cv;    
    U32 context_seq;
    CV *curcv;
    I32 curcv_depth;
    PADNAMELIST *names;
    PAD *values;
    long stack_depth;
    int  i;
    bool context_match;
    if ( ! cl->ok ) 
	return;
    if (cv && CvPADLIST( cv ) ){
	PADLIST *padlist = CvPADLIST( cv );
	if (CvDEPTH(cv)){
	    croak( "Fail compile: cv is running" );
	}
	stack_depth = dive_in_stack(); // What about main CV
	if ( stack_depth < 0 ){
	    curcv = PL_main_cv;
	    curcv_depth = CvDEPTH(curcv);
	    context_seq = PL_curcop->cop_seq;
	    cl->stack_depth = -1;
	}
	else {
	    context_seq   = 0;
	    curcv = cxstack[ stack_depth ].blk_sub.cv;
	    curcv_depth =  cxstack[ stack_depth ].blk_sub.olddepth+1;
	    cl->stack_depth = cxstack_ix - stack_depth;
	}

	context_match = FALSE;
	if ( curcv != CvOUTSIDE(cv) ){
	    CV *out;
	    U32 seq;
	    out = CvOUTSIDE(cv);
	    seq = CvOUTSIDE_SEQ(cv);
	    while( out ){
		if ( curcv == out ){
		    context_match = TRUE;
		    context_seq = seq;
		    break;
		};
		seq = CvOUTSIDE_SEQ(out);
		out = CvOUTSIDE(out);
	    }
	    if ( ! context_match )
		warn("Cv from other context %p", CvOUTSIDE(cv) );
	};
	
	cl->outer = curcv;
	cl->outer_depth = curcv_depth;


	cl->offset_size = 0;
	// no pad no work
	if ( ! CvPADLIST( curcv ))
	    return;

	names = PadlistNAMES(padlist);
	values =PadlistARRAY(padlist)[1];
	for (i=0; i<= PadnamelistMAX( names ) ; ++i ){
	    PADNAME *name_sv;
	    SV *val_sv;
	    name_sv = (PadnamelistARRAY(names)[i]);
	    val_sv  = PadARRAY( values )[i];
	    if ( PadnamePV(name_sv) && PadnameOUTER(name_sv) 
		    && !PadnameIsOUR(name_sv)
		    && PadnameLEN(name_sv) > 1 ){
		++(cl->offset_size);
	    }
	}
	// sv_dump( cv );
	// sv_dump( names );
	// sv_dump( AvELT(CvPADLIST( cv ),0) );
	// fprintf( stderr, "%d=%d\n",  cl->offset_size , AvFILLp( names ));


	// alocation 
	cl->position = (I32 *)  M_alloc( temppad, 2*cl->offset_size * sizeof( I32));
	cl->temporary = (SV **) M_alloc( temppad, cl->offset_size * sizeof( SV *));


	cl->offset_size = 0;
	for (i=0; i<= AvFILLp( names ) ; ++i ){
	    PADNAME *name_sv;
	    SV *val_sv;
	    name_sv = (AvARRAY(names)[i]);
	    val_sv  = AvARRAY( values )[i];
	    if ( PadnamePV(name_sv) && PadnameOUTER(name_sv) 
		    && !PadnameIsOUR(name_sv)
		    && PadnameLEN(name_sv) > 1 ){
		I32 position;
		position = find_sv( curcv, curcv_depth, context_seq, val_sv);
		//fprintf( stderr, "%d=\n", position );
		// We are skipping over Fakes in outer sub
		if (position < 0)
		    continue;
		//fprintf( stderr, " %d-%d!", position, i );
		cl->position[ cl->offset_size++] = position;
		cl->position[ cl->offset_size++] = i;
	    } 
	}
	cl->outer_pad = PadlistARRAY( CvPADLIST( curcv ));
	cl->closure_pad = PadlistARRAY( CvPADLIST( cl->closure_cv ));
	cl_prepare_closure( aTHX_ cl, 0 );
	//fprintf( stderr, "\n");
    }
}

void
cl_prepare_closure( pTHX_ p_closure cl, int optype ){
    I32 i;
    I32 j;
    I32 cv_depth = cl->outer_depth;
    SV **out_values = PadARRAY(cl->outer_pad[cv_depth]);
    SV **closure_values = PadARRAY(cl->closure_pad[1]);
    if ( !cl->ok )
	return;

    for( i = 0, j =0 ; i < cl->offset_size; i+=2, ++j ){
	I32 position_from = cl->position[i];	
	I32 position_to   = cl->position[i+1];
	if ( optype == 0 ){
	    cl->temporary[j] = newSV(0);

	    SvREFCNT_dec( closure_values[ position_to] );
	    closure_values[ position_to ] = cl->temporary[j];
	}
	else if ( optype == 1 ){
	    SV *sv;
	    sv =  out_values [ position_from ];
	    closure_values[ position_to ] = sv;
	}
	else if ( optype == 2 ){
	    SV *sv;
	    sv = out_values [ position_from ];
	    closure_values[ position_to ] = cl->temporary [ j ];
	}
    }
}
void
cl_run_closure( pTHX_ p_closure closure){
    dSP;
    I32 ret_count;
    int i;
    PUSHMARK(SP);
    PUTBACK;
    cl_prepare_closure( aTHX_ closure, 1); 
    ret_count = call_sv( (SV*)closure->closure_cv, G_NOARGS | G_SCALAR |G_EVAL );
    cl_prepare_closure( aTHX_ closure, 2); 
    SPAGAIN;
    if ( ret_count != 1 )
	croak( "Incorrect number of stack items " );
    for( i=0; i<ret_count; ++i){
	closure->return_value = POPs;
    }
    PUTBACK;
}


long
dive_in_stack(){
    long i;
    for( i= cxstack_ix; i>= 0 ;--i ){
	if (CxTYPE(&cxstack[i]) == CXt_SUB) {
	    CV * cur_cv = cxstack[i].blk_sub.cv;
	    if ( PL_DBsub && GvCV(PL_DBsub) == cur_cv ){
		continue;
	    }
	    return i;
	}
	else if ( CxTYPE( &cxstack[i] )  ==CXt_EVAL ) {
	    if (CxOLD_OP_TYPE( &cxstack[i] ) == OP_ENTERTRY ){
		continue;
	    }
	    return -2;
	}
    }
    return -1;
}
static AV *eval_cache=0;

MODULE = Eval::Compile		PACKAGE = Eval::Compile		

void 
cache_eval_undef()
    PREINIT:
    SV *last;
    PPCODE:
    last = eval_cache;
    if ( !eval_cache ){
	XSRETURN(0);
    };
    eval_cache=0;
    SvREFCNT_dec( last );
    last =0 ;
    XSRETURN(0);
	

void 
cache_eval (SV * eval_string,  ... )
    ALIAS:
	ceval=1
	cached_eval=2
    PROTOTYPE: $@
    PREINIT:
    I32 ret_count;
    //I32 i;
    SV **value;
    char *pstr;
    STRLEN plen;
    AV* temppad;
    HV* closure_cache;
    p_closure closure;
    dXSTARG;
    PPCODE:
    PERL_UNUSED_VAR(ix);
    if ( !eval_cache ){
	eval_cache = newAV();
	temppad = eval_cache;
	closure_cache = newHV();
	AvPUSHs( eval_cache, (SV*)closure_cache );
    }
    else {
	temppad = eval_cache;
	closure_cache =( HV*)  AvELT( eval_cache,  0);
	if ( SvTYPE( closure_cache ) != SVt_PVHV )
	    croak( "panic: not a hash" );
    }
    temppad = (AV *) eval_cache;
    sv_setpvn( TARG, &PL_curcop, sizeof( &PL_curcop ));
    sv_catsv(  TARG, eval_string );

    pstr = SvPV( TARG, plen );
    value = hv_fetch( closure_cache , pstr, plen, 0);

    if ( value){
	closure = (p_closure) SvIV( * value );
	// XPUSHs(*value);
	// XSRETURN(1);
    };

    if ( !value ){
	SV *text;
	SV *anonsub;
	// Allocation of closure body
	closure = ( p_closure ) M_alloc( temppad,  sizeof( *closure) );

	hv_store( closure_cache, pstr, plen, newSViv( PTR2IV( closure )),0);
	
	
	text= sv_newmortal( );
	// TODO
	
	sv_setpv( text , "sub {\n" );
	sv_catpvf( text, "#line 0 \"<%s:%d>\"\n", CopFILE( PL_curcop ), CopLINE( PL_curcop ));
	sv_catsv( text,  eval_string );
	sv_catpv( text, ";\n};\n" );
	// fprintf( stderr, "%s\n", SvPV_nolen( text ));


	{
	dSP;
	sv_setpvn( ERRSV, "", 0);
	eval_sv( text , G_SCALAR | G_KEEPERR  );
	SPAGAIN;
	anonsub = POPs;
	PUTBACK;
	};
	
	// TODO
	//sv_dump( anonsub );
	closure->ok = 0;

	if ( SvOK(anonsub) && !SvTRUE(ERRSV)){
	    AvPUSHs( temppad, anonsub );
	    closure->ok = 1;
	    closure->closure_cv = (CV *)SvRV(anonsub);
	    cl_init( aTHX_ closure, temppad);
	}
	else {
	    warn( "%s", SvPVx_nolen_const( ERRSV ));
	    closure->ok = 0;
	    closure->return_value = newSVsv( ERRSV );
	    AvPUSHs( temppad, closure->return_value );
	    cl_init( aTHX_ closure, temppad);
	};
    }

    if ( closure->ok ){
	SV *result;
	ENTER;
	PUSHMARK(SP);
	cl_prepare_closure( aTHX_ closure, 1); 
	ret_count = call_sv( (SV *) closure->closure_cv, G_SCALAR | G_EVAL |  G_NOARGS );
	cl_prepare_closure( aTHX_ closure, 2); 

	SPAGAIN;
	result = POPs;
	if (ret_count != 1)
	    croak( "Invalid sub call" );
	if ( SvTRUE(ERRSV) )
	    warn("%s", SvPV_nolen( ERRSV ));
	PUTBACK;
	PUSHs(result);
	LEAVE;
	//sv_dump( result );
	XSRETURN(1);
    }
    else {
	sv_setsv( ERRSV, closure->return_value );
	XSRETURN_UNDEF;
    }
    
void 
cache_this ( SV * key, CV * calc_sv )
    PREINIT:
    I32 ret_count;
    //I32 i;
    SV **value;
    char *pstr;
    STRLEN plen;
    dXSTARG;
    PPCODE:
    if ( ! (PL_op->op_private & OPpENTERSUB_HASTARG )){
	croak( "panic: XS sub no target " );
    };
    if (SvTYPE(TARG) != SVt_PVHV ){
	(void)SvUPGRADE( TARG , SVt_PVHV );
    }
    pstr = SvPV( key, plen );
    value = hv_fetch( (HV*) TARG, pstr, plen, 0);
    if (value){
	XPUSHs(*value);
	XSRETURN(1);
    };
    PUSHMARK(SP);
    XPUSHs(ST(0));
    PUTBACK;
    ret_count = call_sv( (SV *)calc_sv, G_SCALAR | G_EVAL);
    SPAGAIN;
    if (ret_count != 1)
	croak( "Invalid sub call" );
    if ( SvTRUE(ERRSV) )
	warn("%s", SvPV_nolen( ERRSV ));
    else {
	SV *ret = POPs;
	SvREFCNT_inc_simple_void_NN(ret);
	(void) hv_store( (HV *)TARG, pstr, plen, ret , 0);
    }
    PUTBACK;
    XSRETURN(1);
    


    

void run_sub( SV * code )
    PREINIT:
    I32 ret_count;
    int i;
    PPCODE:
    dSP;
    PUSHMARK(SP);
    PUTBACK;
    ret_count = call_sv( code, G_NOARGS | G_SCALAR );
    SPAGAIN;
    for( i=0; i<ret_count; ++i){
	sv_dump( POPs );
    }
    PUTBACK;



void
compile_sub( SV *codetext)
    PREINIT:
    SV *text;
    SV *anonsub;
    PPCODE:
    //dSP;
    text= sv_newmortal( );
    sv_setpv( text , "sub {\n" );
    sv_catsv( text,  codetext );
    sv_catpv( text, "\n};\n" );

    anonsub = eval_pv( SvPV_nolen(text) , 0 );
    if ( !SvTRUE(ERRSV)){
	XPUSHs(&PL_sv_no);
	XPUSHs( anonsub );
	XPUSHs( codetext );
    }
    else {
	XPUSHs( ERRSV );
    };


void
callers( CV * cv, SV *eval_string )
    PREINIT:
    int i;
    PADNAMELIST *names;
    PAD *values;
    CV *subcv;
    long subcv_depth;
    long stack_depth;
    bool context_match;
    U32  context_seq;
    AV *results;
    PPCODE:
    if (cv && CvPADLIST( cv ) ){
	PADLIST *padlist = CvPADLIST( cv );
	if (CvDEPTH(cv)){
	    croak( "Fail compile: cv is running" );
	}
	stack_depth = dive_in_stack();
	if ( stack_depth < 0 ){
	    warn( "found no variables " );
	}
	context_match = FALSE;
	context_seq   = 0;
	if ( cxstack[ stack_depth ].blk_sub.cv != CvOUTSIDE(cv) ){
	    CV *out;
	    U32 seq;
	    out = CvOUTSIDE(cv);
	    seq = CvOUTSIDE_SEQ(cv);
	    while( out ){
		if ( cxstack[ stack_depth ].blk_sub.cv == out ){
		    context_match = TRUE;
		    context_seq = seq;
		    break;
		};
		seq = CvOUTSIDE_SEQ(out);
		out = CvOUTSIDE(out);
	    }
	    if ( ! context_match )
		warn("Cv from other context %p", CvOUTSIDE(cv) );
	};
	subcv = cxstack[ stack_depth ].blk_sub.cv;
	subcv_depth =  cxstack[ stack_depth ].blk_sub.olddepth+1;
	results = newAV();
	sv_2mortal( (SV *) results );
	AvPUSHi( results, 1 ) ; //0:  set that everything ok
	AvPUSHi( results, cxstack_ix - stack_depth ); //1: stack depth
	AvPUSHs( results, newRV((SV*)subcv));//2: context_cv
	AvPUSHs( results, eval_string );     //3:eval string
	AvPUSHs( results, newRV( (SV*)cv ) );//4: cv
	mXPUSHi(cxstack_ix - stack_depth); //  5: context_depth
	AvPUSHi( results, context_seq); //     6: seq

	_show_cvpad( cxstack[ stack_depth ].blk_sub.cv );

	names = PadlistNAMES(padlist);
	values =PadlistARRAY(padlist)[1];

	for (i=0; i<= PadnamelistMAX( names ) ; ++i ){
	    PADNAME *padn;
	    SV *val_sv;
	    padn = (PadnamelistARRAY(names)[i]);
	    val_sv  = PadARRAY( values )[i];
	    if ( PadnamePV(padn) && PadnameOUTER(padn) 
		    && !PadnameIsOUR(padn)
		    && PadnameLEN(padn) > 1 ){
		I32 position;
		SV * const name_sv = PadnameSV(padn);
		XPUSHs(name_sv);
		mXPUSHi( i );
		position = find_sv( subcv, subcv_depth, context_seq, val_sv);
		mXPUSHi( position );
		AvPUSHi( results, position );
		if ( position < 0){
		    sv_setiv( AvARRAY( results )[0] , 0 );
		}
		AvPUSHs( results, name_sv);
		AvPUSHi( results, i );
	    } 
	}
    }
    else {
	XSRETURN(0);
    }
