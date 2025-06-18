#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <nlopt.h>

#include "const-c.inc"

#if INTSIZE == Size_t_size
#define FMT_SIZE_T "%d"
#else
#define FMT_SIZE_T "%ld"
#endif

#define EXCEPTION "Math::NLopt::Exception"

/* copy a C double array (in) into an AV (out).

   'out' may be NULL, an AV* or an RV pointing to an AV
   if 'out' is NULL, a newly allocated AV is returned.
*/
static SV*
double_to_AV( pTHX_ unsigned n, const double *in, SV* out ) {

    AV* arr;
    SSize_t i;

    if ( NULL == out ) {
        arr = newAV();
        av_extend(arr, n );
        for ( i = 0  ; i < n ; i++ ) {
            av_store(arr, i, newSVnv(in[i]) );
        }
        out = (SV*) arr;
    }
    else {

        if ( SvROK( out ) && SvTYPE(SvRV(out)) == SVt_PVAV ) {
            arr = (AV*) SvRV(out);
        }
        else if ( SvTYPE(out) == SVt_PVAV ) {
            arr = (AV*) out;
        }
        else {
            croak( "internal error: unknown SV passed to double_to_AV" );
        }

        if ( n != av_count(arr) )
             croak( "double_to_AV: inconsistent output Perl arr length: expected %d, got " FMT_SIZE_T,
                    n, av_count(arr) );

        /* possibly cheaper to call AvARR and get a direct pointer to
           the SV* arr, but av_fetch ensures the location is populated
           with an SV, and I don't trust callers not to muck about with
           things in the AV
        */
        for (i = 0; i < n ; i++ ) {
            SV** svp = av_fetch( arr, i, 1 );
            sv_setnv( *svp, in[i] );
        }
    }

    return out;
}

/* copy an AV (in) into a C double array (out).

   'in' must have at n slots which must be populated with SV's.
   it may either by an actual AV or a reference to one

   if 'out' is NULL, a mortal SVPV is created which will hold the C array.
*/
static double*
AV_to_double( pTHX_ unsigned n, SV* in, double *out ) {

    AV* arr;
    SSize_t i;

    if ( SvROK( in ) && SvTYPE(SvRV(in)) == SVt_PVAV ) {
        arr = (AV*) SvRV(in);
    }
    else if ( SvTYPE(in) == SVt_PVAV ) {
        arr = (AV*) in;
    }
    else {
        croak( "internal error: unknown SV passed to AV_to_double" );
    }

    SSize_t len = av_count( arr );
    if ( len != n )
        croak( "AV_to_double: inconsistent input Perl array length: expected %d, got " FMT_SIZE_T,
               n, len );

    if ( NULL == out )
        out = (double*) SvPVX( sv_2mortal(newSV(n * sizeof(double))) );

    /* possibly cheaper to call AvARRAY and get a direct poarrter to
       the SV* array, but av_fetch ensures the location is populated
       with an SV, and I don't trust callers not to muck about with
       tharrgs arr the AV
    */
    for (i = 0; i < n ; i++ ) {
        SV** svp = av_fetch( arr, i, 1 );
        out[i] = SvNVx( *svp );
    }

    return out;
}

static AV*
populate_array ( pTHX_ AV* array, SSize_t n ) {
    SSize_t i;

    av_extend( array, n );
    for ( i = 0 ; i < n ; i ++ )
        av_store( array, i, newSVnv(0) );

    return array;
}


/*
  create a Perl array filled with zeroes.
  returns an RV to the array

  if n == 0, doesn't extend it or populate it.

 */

static SV*
new_array ( pTHX_ SSize_t n ) {

    AV* arr = newAV();
    SV* rv = newRV_noinc((SV*) arr );

    if ( n > 0 )
        populate_array( aTHX_ arr, n );

    return rv;
}


/* keep track of all of our goodies */
typedef struct {
    nlopt_opt  self;
    unsigned int dimension;
    int throw_on_error;
    nlopt_result result;
    nlopt_result optimize_result;
    double optimum_value;
    AV* proxies; /* store proxy structures in AV; will be GC'd in DESTROY */
} ProxyNLopt;

typedef ProxyNLopt* NLopt;

SV* new_ProxyNLopt( pTHX_ nlopt_opt self ) {

    SV* sv_proxy = newSV(sizeof(ProxyNLopt));
    ProxyNLopt * proxy = (ProxyNLopt*) SvPVX( sv_proxy );

    proxy->self = self;
    proxy->dimension = nlopt_get_dimension( self );
    proxy->proxies = newAV();
    proxy->throw_on_error = 1;

    return sv_proxy;
}

static void
my_throw( pTHX_ const char * pclass, const char* message ) {

    SV* object;
    int count;

    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP,2);
    mPUSHs(newSVpv(pclass, 0 ));
    mPUSHs(newSVpv(message, 0 ));
    PUTBACK;

    count = call_method( "new", G_SCALAR );

    SPAGAIN;

    if (count != 1)
        croak("Big Trouble\n" );

    object = POPs;

    /* increment ref count otherwise the LEAVE below destroys it */
    SvREFCNT_inc_simple_void_NN(object);

    PUTBACK;
    FREETMPS;
    LEAVE;

    croak_sv( object );
}

static void
throw_nlopt( pTHX_ int iclass, const char* message ) {

    SV* object;
    const char * pclass;
    int count;

    switch( iclass ) {
    case NLOPT_FAILURE:
        pclass = "Math::NLopt::Exception::Failure";
        if ( NULL == message )
            message = "failure";
        break;

    case NLOPT_OUT_OF_MEMORY:
        pclass = "Math::NLopt::Exception::OutOfMemory";
        if ( NULL == message )
            message = "out of memory";
        break;

    case NLOPT_INVALID_ARGS:
        pclass = "Math::NLopt::Exception::InvalidArgs";
        if ( NULL == message )
            message = "invalid argument";
        break;

    case NLOPT_ROUNDOFF_LIMITED:
        pclass = "Math::NLopt::Exception::RoundoffLimited";
        if ( NULL == message )
            message = "roundoff limited";
        break;

    case NLOPT_FORCED_STOP:
        pclass = "Math::NLopt::Exception::ForcedStop";
        if ( NULL == message )
            message = "forced stop";
        break;

    default:
        pclass = "Math::NLopt::Exception";
        break;
    }

    my_throw( aTHX_ pclass, message );
}

nlopt_result validate_result ( pTHX_ NLopt opt, nlopt_result result ) {

    opt->result = result;
    if ( ! opt->throw_on_error || result >= NLOPT_SUCCESS)
        return result;

    const char *errmsg = nlopt_get_errmsg( opt->self );
    throw_nlopt( aTHX_ result, errmsg );

    /* shouldn't get here */
    return result;
}

static SV*
dup_subref( pTHX_ SV* sub ) {

    SV*copy;

    if ( ! ( SvTYPE(sub) == SVt_PV || (SvROK(sub) && SvTYPE(SvRV(sub)) == SVt_PVCV ) ) )
        croak( "subroutine must either be a codref or string" );

    copy = newSV(0);
    SvSetSV(copy, sub);
    return copy;
}


typedef struct {
    const char *label = "proxyfunc";
    SV* perl_sub; /* PV or SV to CV */
    SV* x;        /* RV to AV */
    SV* gradient; /* RV to AV */
    SV* data;
    SV* precond;  /* PV containiing possible ProxyPreCondFunc;
                     only used when this is a subsidiary func of that */
} ProxyFunc;


static SV*
new_ProxyFunc( pTHX_ NLopt opt, SV* sub, unsigned n, SV* data ) {

    AV* arr;
    SV* sv_proxy = newSV(sizeof(ProxyFunc));
    av_push( opt->proxies, sv_proxy );
    ProxyFunc* proxy = (ProxyFunc*) SvPVX( sv_proxy );

    proxy->perl_sub = dup_subref( aTHX_ sub);
    av_push(opt->proxies, proxy->perl_sub );

    if ( NULL == data ) {
        proxy->data = &PL_sv_undef;
    }
    else {
        proxy->data = data;
        av_push( opt->proxies, SvREFCNT_inc_simple_NN(data) );
    }

    proxy->x = new_array( aTHX_ n );
    av_push( opt->proxies, proxy->x );

    proxy->gradient = new_array( aTHX_ 0 );
    av_push( opt->proxies, proxy->gradient );

    return sv_proxy;
}

/* proxy passed to NLopt for arguments of type nlopt_func */
static double
proxy_func ( unsigned n, const double *x, double *gradient, void *data ) {

    int count;
    double retval;
    ProxyFunc *proxy = (ProxyFunc *) SvPVX( (SV*) data);

    dTHX;  /* this is called from C, not from a perl routine, so can't
              put it in the argument list */

    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP,2);
    double_to_AV( aTHX_  n, x, proxy->x );
    PUSHs( proxy->x );

    if ( NULL == gradient )
        PUSHs(&PL_sv_undef);
    else {
        AV* array = (AV*) SvRV( proxy->gradient );
        /* populate if not already done so */
        if ( av_count( array ) == 0 )
            populate_array( aTHX_ array, n );
        PUSHs( proxy->gradient );
    }

    PUSHs(proxy->data);
    PUTBACK;

    count = call_sv( proxy->perl_sub, G_SCALAR);

    SPAGAIN;

    if (count != 1)
        croak("Big Trouble\n" );

    retval = POPn;

    if ( NULL != gradient )
        AV_to_double( aTHX_  n, proxy->gradient, gradient );

    PUTBACK;
    FREETMPS;
    LEAVE;

    return retval;
}

typedef struct {
    SV* perl_sub;
    SV* x;        /* RV to AV */
    SV* gradient; /* RV to AV */
    SV* result;   /* RV to AV */
    SV* data;
} ProxyMFunc;

static SV*
new_ProxyMFunc( pTHX_ NLopt opt, SV* sub, unsigned n, unsigned m, SV* data ) {

    SV* sv_proxy = newSV(sizeof(ProxyMFunc));
    av_push( opt->proxies, sv_proxy );

    ProxyMFunc * proxy = (ProxyMFunc*) SvPVX( sv_proxy );

    proxy->perl_sub = dup_subref( aTHX_ sub);
    av_push(opt->proxies, proxy->perl_sub );

    if ( NULL == data ) {
        proxy->data = &PL_sv_undef;
    }
    else {
        proxy->data = data;
        av_push( opt->proxies, SvREFCNT_inc_simple_NN(data) );
    }

    proxy->x = new_array( aTHX_ n );
    av_push( opt->proxies, proxy->x );

    proxy->gradient = new_array( aTHX_ 0 );
    av_push( opt->proxies, proxy->gradient );

    proxy->result = new_array (aTHX_ n );
    av_push( opt->proxies, proxy->result );

    return sv_proxy;
}


static void
proxy_mfunc( unsigned m, double *result, unsigned n, const double* x, double* gradient, void *data) {

    int count;
    ProxyMFunc *proxy = (ProxyMFunc *) SvPVX( (SV*) data);

    dTHX;  /* this is called from C, not from a perl routine, so can't
              put it in the argument list */

    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP,4);

    PUSHs( proxy->result);
    PUSHs( double_to_AV( aTHX_  n, x, proxy->x ) );

    if ( NULL == gradient )
        PUSHs(&PL_sv_undef);
    else {
        AV* array = (AV*) SvRV( proxy->gradient );
        /* populate if not already done so */
        if ( av_count( array ) == 0 )
            populate_array( aTHX_ array, n * m );
        PUSHs( proxy->gradient );
    }

    PUSHs(proxy->data);
    PUTBACK;

    count = call_sv( proxy->perl_sub, G_VOID);

    SPAGAIN;

    if (count != 1)
        croak("Big Trouble\n" );

    AV_to_double( aTHX_  m, proxy->result, result );

    if ( NULL != gradient )
        AV_to_double( aTHX_  n * m, proxy->gradient, gradient );

    PUTBACK;
    FREETMPS;
    LEAVE;
}

typedef struct {
    SV* perl_sub;
    SV* x;     /* RV to AV */
    SV* v;     /* RV to AV */
    SV* vpre;  /* RV to AV */
    SV* data;
} ProxyPreCondFunc;

static SV*
new_ProxyPreCondFunc( pTHX_ NLopt opt, SV* sub, unsigned n, SV* data ) {

    SV* sv_proxy = newSV(sizeof(ProxyPreCondFunc));
    av_push( opt->proxies, sv_proxy );
    ProxyPreCondFunc * proxy = (ProxyPreCondFunc*) SvPVX( sv_proxy );

    proxy->perl_sub = dup_subref( aTHX_ sub);

    if ( NULL == data ) {
        proxy->data = &PL_sv_undef;
    }
    else {
        proxy->data = data;
        av_push( opt->proxies, SvREFCNT_inc_simple_NN(data) );
    }

    proxy->x = new_array( aTHX_ n );
    av_push( opt->proxies, proxy->x );

    proxy->v = new_array( aTHX_ n );
    av_push( opt->proxies, proxy->v );

    proxy->vpre = new_array( aTHX_ n );
    av_push( opt->proxies, proxy->vpre );

    return sv_proxy;
}


static void
proxy_precond( unsigned n, const double *x, const double *v, double *vpre, void *f_data) {

    int count;
    /* there's only one user data available when using
       preconditioners, but two functions, so we piggy back on the
       user data for the main objective function */
    ProxyPreCondFunc *proxy;

    dTHX;  /* this is called from C, not from a perl routine, so can't
              put it in the argument list */

    proxy = (ProxyPreCondFunc*) SvPVX( ((ProxyFunc *) SvPVX( (SV*) f_data))->precond );

    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP,4);

    PUSHs( double_to_AV( aTHX_  n, x, proxy->x ) );
    PUSHs( double_to_AV( aTHX_  n, v, proxy->v ) );
    PUSHs( proxy->vpre );

    PUSHs(proxy->data);
    PUTBACK;

    count = call_sv( proxy->perl_sub, G_VOID);

    SPAGAIN;

    if (count != 1)
        croak("Big Trouble\n" );

    AV_to_double( aTHX_  n, proxy->vpre, vpre );

    PUTBACK;
    FREETMPS;
    LEAVE;
}

typedef nlopt_result validated_result;

MODULE = Math::NLopt		PACKAGE = Math::NLopt		PREFIX = nlopt_

TYPEMAP: <<EOT
const char *					T_PTROBJ
const double *					T_PTROBJ
double *					T_PTROBJ
int *						T_PTROBJ

# enums
nlopt_algorithm					T_ENUM
nlopt_result					T_ENUM
validated_result				T_VALIDATED_RESULT

# object pointer
NLopt				                T_NLopt

# convert from our object directly to nlopt_opt
nlopt_opt                                       T_nlopt_opt

# pointers to functions; they are passed a void* user data
# which the proxy functions use to associate a particular
# perl sub instance.
nlopt_func					T_PTROBJ
nlopt_mfunc					T_PTROBJ
nlopt_precond					T_PTROBJ

INPUT

T_nlopt_opt
    if (sv_isa($arg, \"$Package\")) {
        $var = ((ProxyNLopt*) SvPVX( SvRV($arg) ))->self;
    }
    else {
        const char* refstr = SvROK($arg) ? \"\" : SvOK($arg) ? \"scalar \" : \"undef\";
        Perl_croak_nocontext(\"%s: Expected %s to be of type %s; got %s%\" SVf \" instead\",
                ${$ALIAS?\q[GvNAME(CvGV(cv))]:\qq[\"$pname\"]},
                \"$var\", \"Math::NLopt\",
                refstr, $arg
        );
    }

T_NLopt
    if (sv_isa($arg, \"$Package\")) {
      $var = (ProxyNLopt*) SvPVX( SvRV($arg) );
    }
    else {
        const char* refstr = SvROK($arg) ? \"\" : SvOK($arg) ? \"scalar \" : \"undef\";
        Perl_croak_nocontext(\"%s: Expected %s to be of type %s; got %s%\" SVf \" instead\",
                ${$ALIAS?\q[GvNAME(CvGV(cv))]:\qq[\"$pname\"]},
                \"$var\", \"$Package\",
                refstr, $arg
        );
    }

OUTPUT

# this mess assumes that the first argument, ST(0), is an NLopt . it's equivalent to validate_result( opt, RETVAL)
T_VALIDATED_RESULT
        ${ "$var" eq "RETVAL" ? \"$arg = newSViv(validate_result(aTHX_ (ProxyNLopt*) SvPVX( SvRV(ST(0))),$var));" : croak('INTERNAL ERROR VALIDATED_RESULT ONLY USES RETVAL'); }


# vendored fix from 5.15.4

TYPEMAP

AV*                                             T_MY_AVREF_REFCOUNT_FIXED

INPUT

T_MY_AVREF_REFCOUNT_FIXED
        STMT_START {
                SV* const xsub_tmp_sv = $arg;
                SvGETMAGIC(xsub_tmp_sv);
                if (SvROK(xsub_tmp_sv) && SvTYPE(SvRV(xsub_tmp_sv)) == SVt_PVAV){
                    $var = (AV*)SvRV(xsub_tmp_sv);
                }
                else{
                    Perl_croak_nocontext(\"%s: %s is not an ARRAY reference\",
                                ${$ALIAS?\q[GvNAME(CvGV(cv))]:\qq[\"$pname\"]},
                                \"$var\");
                }
        } STMT_END


OUTPUT

# Copy
T_MY_AVREF_REFCOUNT_FIXED
        ${ "$var" eq "RETVAL" ? \"$arg = newRV_noinc((SV*)$var);" : \"sv_setrv_noinc($arg, (SV*)$var);" }

EOT

PROTOTYPES: DISABLE

INCLUDE: const-xs.inc

validated_result
nlopt_add_equality_constraint(opt, h, ... )
        NLopt	opt
        SV*	h
    PREINIT:
        SV* func;
        SV*	h_data;
        double	tol;
    CODE:
        if (items > 4)
            croak_xs_usage(cv, "too many arguments" );
        h_data = items > 2 ? ST(2) : &PL_sv_undef;
        tol = items > 3 ? (double) SvNV(ST(3)) : 0;
        func = new_ProxyFunc( aTHX_ opt, h, opt->dimension, h_data );
        RETVAL = nlopt_add_equality_constraint( opt->self, &proxy_func, (void*) func, tol);
    OUTPUT:
        RETVAL

validated_result
nlopt_add_inequality_constraint(opt, fc, ... )
        NLopt	opt
        SV*	fc
    PREINIT:
        SV* func;
        SV*	fc_data;
        double	tol;
    CODE:
        if (items > 4)
            croak_xs_usage(cv, "too many arguments" );
        fc_data = items > 2 ? ST(2) : &PL_sv_undef;
        tol = items > 3 ? (double) SvNV(ST(3)) : 0;
        func = new_ProxyFunc( aTHX_ opt, fc, opt->dimension, fc_data );
        RETVAL = nlopt_add_inequality_constraint( opt->self, &proxy_func, (void*) func, tol);
    OUTPUT:
        RETVAL

validated_result
nlopt_add_equality_mconstraint(opt, m, h, ... )
        NLopt	 opt
        unsigned m
        SV*  	 h
    PREINIT:
        SV* func;
        SV*	 h_data;
        SV*	 tol;
        double *c_tol = NULL;
    CODE:
        if (items > 5)
            croak_xs_usage(cv, "too many arguments" );
        h_data = items > 3 ? ST(3) : &PL_sv_undef;
        tol = items > 4 ? ST(4) : &PL_sv_undef;
        func = new_ProxyMFunc( aTHX_ opt,  h, opt->dimension, m, h_data );
        if ( tol != &PL_sv_undef )
            c_tol = AV_to_double( aTHX_  m, tol, NULL );
        RETVAL = nlopt_add_equality_mconstraint( opt->self, m, &proxy_mfunc, (void*) func, c_tol);
    OUTPUT:
        RETVAL

validated_result
nlopt_add_inequality_mconstraint(opt, m, fc, ... )
        NLopt	 opt
        unsigned m
        SV*  	 fc
    PREINIT:
        SV* func;
        SV*	 fc_data;
        SV*	 tol;
        double *c_tol = NULL;
    CODE:
        if (items > 5)
            croak_xs_usage(cv, "too many arguments" );
        fc_data = items > 3 ? ST(3) : &PL_sv_undef;
        tol = items > 4 ? ST(4) : &PL_sv_undef;
        func = new_ProxyMFunc( aTHX_ opt,  fc, opt->dimension, m, fc_data );
        if ( tol != &PL_sv_undef )
            c_tol = AV_to_double( aTHX_  m, tol, NULL);
        RETVAL = nlopt_add_inequality_mconstraint( opt->self, m, &proxy_mfunc, (void*) func, c_tol);
    OUTPUT:
       RETVAL

nlopt_algorithm
nlopt_algorithm_from_string(name)
        const char *	name

const char *
nlopt_algorithm_name(a)
        nlopt_algorithm	a

const char *
nlopt_algorithm_to_string(algorithm)
        nlopt_algorithm	algorithm

# NLopt
# nlopt_copy(opt)
#	NLopt	opt

SV*
new(classname, algorithm, n)
        SV* classname
        nlopt_algorithm	algorithm
        unsigned	n
    PREINIT:
        SV* rv;
    CODE:
        rv = newRV( new_ProxyNLopt( aTHX_ nlopt_create( algorithm, n ) ) );
        sv_bless( rv, gv_stashsv( classname, GV_NOADD_NOINIT ) );
        RETVAL = rv;
    OUTPUT:
        RETVAL

SV*
nlopt_create(algorithm, n)
        nlopt_algorithm	algorithm
        unsigned	n
    PREINIT:
        SV* rv;
        HV* stash;
    CODE:
        rv = newRV( new_ProxyNLopt( aTHX_ nlopt_create( algorithm, n ) ));
        stash = gv_stashpvs( "Math::NLopt", GV_NOADD_NOINIT );
        sv_bless( rv, stash );
        RETVAL = rv;
    OUTPUT:
        RETVAL

void
DESTROY(opt)
        NLopt	opt
      CODE:
        /* all of the proxy SV's should be in the
           proxies AV in opt; drop its refcount
           and that should delete them all
         */
        nlopt_destroy(opt->self);
        SvREFCNT_dec( opt->proxies );

validated_result
nlopt_force_stop(opt)
        nlopt_opt opt

nlopt_algorithm
nlopt_get_algorithm(opt)
        nlopt_opt	opt

unsigned
nlopt_get_dimension(opt)
     NLopt	opt
     CODE:
        RETVAL = opt->dimension;
     OUTPUT:
        RETVAL

const char *
nlopt_get_errmsg(opt)
        nlopt_opt	opt

int
nlopt_get_force_stop(opt)
        nlopt_opt	opt

double
nlopt_get_ftol_abs(opt)
        nlopt_opt	opt

double
nlopt_get_ftol_rel(opt)
        nlopt_opt	opt

AV*
nlopt_get_initial_step(opt, x)
        NLopt  opt
        AV*   x
     PREINIT:
        unsigned n;
        double* c_x;
        double* c_dx;
     CODE:
        n = opt->dimension;
        c_x = AV_to_double( aTHX_  n, (SV*) x, NULL);
        c_dx = (double*) SvPVX( sv_2mortal(newSV(n * sizeof(double))) );
        validate_result( aTHX_ opt, nlopt_get_initial_step( opt->self, c_x, c_dx ) );
        RETVAL = (AV*) double_to_AV( aTHX_  n, c_dx, NULL );
     OUTPUT:
       RETVAL

AV*
nlopt_get_lower_bounds(opt)
        NLopt	opt
     PREINIT:
        unsigned n;
        double* c_lb;
     CODE:
        n = opt->dimension;
        c_lb = (double*) SvPVX( sv_2mortal(newSV(n * sizeof(double))) );
        validate_result( aTHX_ opt, nlopt_get_lower_bounds(opt->self, c_lb ) );
        RETVAL = (AV*) double_to_AV( aTHX_  n, c_lb, NULL );
     OUTPUT:
        RETVAL

int
nlopt_get_maxeval(opt)
        nlopt_opt	opt

double
nlopt_get_maxtime(opt)
        nlopt_opt	opt

int
nlopt_get_numevals(opt)
        nlopt_opt	opt

double
nlopt_get_param(opt, name, defaultval)
        nlopt_opt	opt
        const char *	name
        double	defaultval

unsigned
nlopt_get_population(opt)
        nlopt_opt	opt

double
nlopt_get_stopval(opt)
        nlopt_opt	opt

AV*
nlopt_get_upper_bounds(opt)
        NLopt	opt
     PREINIT:
        unsigned n;
        double* c_ub;
     CODE:
        n = opt->dimension;
        c_ub = (double*) SvPVX( sv_2mortal(newSV(n * sizeof(double))) );
        validate_result( aTHX_ opt, nlopt_get_upper_bounds( opt->self, c_ub ) );
        RETVAL = (AV*) double_to_AV( aTHX_  n, c_ub, NULL );
     OUTPUT:
        RETVAL

unsigned
nlopt_get_vector_storage(opt)
        nlopt_opt	opt

AV*
nlopt_get_x_weights(opt)
        NLopt	opt
      PREINIT:
        unsigned n;
        double* c_w;
      CODE:
        n = opt->dimension;
        c_w = (double*) SvPVX( sv_2mortal(newSV(n * sizeof(double))) );
        validate_result( aTHX_ opt, nlopt_get_x_weights( opt->self, c_w ) );
        RETVAL = (AV*) double_to_AV( aTHX_  n, c_w, NULL );
      OUTPUT:
        RETVAL

AV*
nlopt_get_xtol_abs(opt)
        NLopt	opt
      PREINIT:
        unsigned n;
        double* c_tol;
      CODE:
        n = opt->dimension;
        c_tol = (double*) SvPVX( sv_2mortal(newSV(n * sizeof(double))) );
        validate_result( aTHX_ opt, nlopt_get_xtol_abs( opt->self, c_tol ) );
        RETVAL = (AV*) double_to_AV( aTHX_  n, c_tol, NULL );
      OUTPUT:
        RETVAL

double
nlopt_get_xtol_rel(opt)
        nlopt_opt	opt

int
nlopt_has_param(opt, name)
        nlopt_opt	opt
        const char *	name

const char *
nlopt_nth_param(opt, n)
        nlopt_opt	opt
        unsigned	n

unsigned
nlopt_num_params(opt)
        nlopt_opt	opt

nlopt_result
last_optimize_result ( opt )
        NLopt opt
     CODE:
        RETVAL = opt->optimize_result;
     OUTPUT:
        RETVAL

double
last_optimum_value ( opt )
        NLopt opt
     CODE:
        RETVAL = opt->optimum_value;
     OUTPUT:
        RETVAL

AV*
nlopt_optimize(opt, x)
      NLopt	opt
      AV*	x
    PREINIT:
        unsigned n;
        double* c_x;
    CODE:
        n = opt->dimension;
        c_x = AV_to_double( aTHX_  n, (SV*) x, NULL );
        /* store result first, then validate it, so that if validate_result throws
           the result is available via last_optimize_result
         */
        opt->optimize_result = nlopt_optimize( opt->self, c_x, &(opt->optimum_value) );
        validate_result( aTHX_ opt, opt->optimize_result );
        RETVAL = (AV*) double_to_AV( aTHX_  n, c_x, NULL );
    OUTPUT:
        RETVAL

validated_result
nlopt_remove_equality_constraints(opt)
        nlopt_opt	opt

validated_result
nlopt_remove_inequality_constraints(opt)
        nlopt_opt	opt

nlopt_result
nlopt_result_from_string(name)
        const char *	name

const char *
nlopt_result_to_string(algorithm)
        nlopt_result	algorithm

validated_result
nlopt_set_force_stop(opt, val)
        nlopt_opt	opt
        int	val

validated_result
nlopt_set_ftol_abs(opt, tol)
        nlopt_opt	opt
        double	tol

validated_result
nlopt_set_ftol_rel(opt, tol)
        nlopt_opt	opt
        double	tol

validated_result
nlopt_set_initial_step(opt, dx)
        NLopt	opt
        AV* 	dx
      PREINIT:
        double *c_dx = NULL;
      CODE:
        c_dx = AV_to_double( aTHX_  opt->dimension, (SV*)  dx, NULL);
        RETVAL = nlopt_set_initial_step( opt->self, c_dx );
      OUTPUT:
        RETVAL

validated_result
nlopt_set_initial_step1(opt, dx)
        nlopt_opt	opt
        double	dx

validated_result
nlopt_set_local_optimizer(opt, local_opt)
        nlopt_opt	opt
        nlopt_opt	local_opt

validated_result
nlopt_set_lower_bound(opt, i, lb)
        nlopt_opt	opt
        int	i
        double	lb

validated_result
nlopt_set_lower_bounds(opt, lb)
        NLopt	opt
        AV*	lb
     PREINIT:
        double* c_lb;
     CODE:
        /* NLopt makes a copy of c_lb, so don't need to keep it around */
        c_lb = AV_to_double( aTHX_  opt->dimension, (SV*) lb, NULL );
        RETVAL = nlopt_set_lower_bounds( opt->self, c_lb);
     OUTPUT:
       RETVAL

validated_result
nlopt_set_lower_bounds1(opt, lb)
        nlopt_opt	opt
        double	lb

validated_result
nlopt_set_max_objective(opt, f, ...)
        NLopt	opt
        SV*	f
      PREINIT:
        SV* func;
        SV *	f_data;
      CODE:
        if (items > 4)
            croak_xs_usage(cv, "too many arguments" );
        f_data = items > 3 ? ST(3) : &PL_sv_undef;
        func = new_ProxyFunc( aTHX_ opt, f, opt->dimension, f_data );
        RETVAL = nlopt_set_max_objective( opt->self, &proxy_func, (void*) func );
      OUTPUT:
        RETVAL

validated_result
nlopt_set_maxeval(opt, maxeval)
        nlopt_opt	opt
        int	maxeval

validated_result
nlopt_set_maxtime(opt, maxtime)
        nlopt_opt	opt
        double	maxtime

validated_result
nlopt_set_min_objective(opt, f, ... )
        NLopt	opt
        SV*	f
      PREINIT:
        SV * func;
        SV * f_data;
      CODE:
        if (items > 3)
            croak_xs_usage(cv, "too many arguments" );
        f_data = items > 2 ? ST(2) : &PL_sv_undef;
        func = new_ProxyFunc( aTHX_ opt, f, opt->dimension, f_data );
        RETVAL = nlopt_set_min_objective( opt->self, &proxy_func, (void*) func );
      OUTPUT:
        RETVAL

validated_result
nlopt_set_param(opt, name, val)
        nlopt_opt	opt
        const char *	name
        double	val

validated_result
nlopt_set_population(opt, pop)
        nlopt_opt	opt
        unsigned	pop

validated_result
nlopt_set_precond_max_objective(opt, f, pre, ...)
        NLopt	opt
        SV*	f
        SV*	pre
      PREINIT:
        unsigned n;
        SV* prefunc;
        SV* func;
        SV * f_data;
      CODE:
        if (items > 4)
            croak_xs_usage(cv, "too many arguments" );
        f_data = items > 3 ? ST(3) : &PL_sv_undef;
        n = opt->dimension;
        prefunc = new_ProxyPreCondFunc( aTHX_ opt, f, n, f_data );
        func = new_ProxyFunc( aTHX_ opt, f, n, f_data );
        ((ProxyFunc*) SvPVX( func ))->precond = prefunc;
        RETVAL = nlopt_set_precond_max_objective( opt->self, &proxy_func, &proxy_precond, (void*) func );
      OUTPUT:
        RETVAL

validated_result
nlopt_set_precond_min_objective(opt, f, pre, ...)
        NLopt	opt
        SV*	f
        SV*	pre
      PREINIT:
        unsigned n;
        SV* prefunc;
        SV* func;
        SV *	f_data;
      CODE:
        if (items > 4)
            croak_xs_usage(cv, "too many arguments" );
        f_data = items > 3 ? ST(3) : &PL_sv_undef;
        n = opt->dimension;
        prefunc = new_ProxyPreCondFunc( aTHX_ opt, f, n, f_data );
        func = new_ProxyFunc( aTHX_ opt, f, n, f_data );
        ((ProxyFunc*) SvPVX( func ))->precond = prefunc;
        RETVAL = nlopt_set_precond_min_objective( opt->self, &proxy_func, &proxy_precond, (void*) func );
      OUTPUT:
        RETVAL

validated_result
nlopt_set_stopval(opt, stopval)
        nlopt_opt	opt
        double	stopval

validated_result
nlopt_set_upper_bound(opt, i, ub)
        nlopt_opt	opt
        int	i
        double	ub

validated_result
nlopt_set_upper_bounds(opt, ub)
        NLopt	opt
        AV*	ub
     PREINIT:
        double* c_ub;
     CODE:
        /* NLopt makes a copy of c_ub, so don't need to keep it around */
        c_ub = AV_to_double( aTHX_  opt->dimension, (SV*) ub, NULL );
        RETVAL = nlopt_set_upper_bounds( opt->self, c_ub);
     OUTPUT:
        RETVAL

validated_result
nlopt_set_upper_bounds1(opt, ub)
        nlopt_opt	opt
        double	ub

validated_result
nlopt_set_vector_storage(opt, dim)
        nlopt_opt	opt
        unsigned	dim

validated_result
nlopt_set_x_weights(opt, w)
        NLopt	opt
        AV *	w
     PREINIT:
        double* c_w;
     CODE:
        c_w = AV_to_double( aTHX_  opt->dimension, (SV*) w, NULL );
        RETVAL = nlopt_set_x_weights( opt->self, c_w);
     OUTPUT:
       RETVAL

validated_result
nlopt_set_x_weights1(opt, w)
        nlopt_opt	opt
        double	w

validated_result
nlopt_set_xtol_abs(opt, tol)
        NLopt	opt
        AV*	tol
     PREINIT:
        double* c_tol;
     CODE:
        c_tol = AV_to_double( aTHX_  opt->dimension, (SV*) tol, NULL );
        RETVAL = nlopt_set_xtol_abs( opt->self, c_tol);
     OUTPUT:
        RETVAL

validated_result
nlopt_set_xtol_abs1(opt, tol)
        nlopt_opt	opt
        double	tol

validated_result
nlopt_set_xtol_rel(opt, tol)
        nlopt_opt	opt
        double	tol

void
nlopt_srand(seed)
        unsigned long	seed

void
nlopt_srand_time()

void
nlopt_version( OUTLIST major, OUTLIST minor, OUTLIST bugfix)
        int 	major
        int 	minor
        int 	bugfix

# this is NOT part of the public API
nlopt_result
_validate_result ( opt, result )
        NLopt opt
        nlopt_result result
     CODE:
         RETVAL = validate_result( aTHX_ opt, result );
     OUTPUT:
        RETVAL

