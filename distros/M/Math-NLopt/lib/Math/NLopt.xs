#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <nlopt.h>
#include <limits.h>
#include <stdarg.h>
#include <stdio.h>

#include "const-c.inc"

#if INTSIZE == Size_t_size
#define FMT_SIZE_T "%d"
#else
#define FMT_SIZE_T "%ld"
#endif


#define EXCEPTION "Math::NLopt::Exception"
#define EXC_EXCEPTION           EXCEPTION
#define EXC_FAILURE             EXCEPTION "::Failure"
#define EXC_FORCED_STOP         EXCEPTION "::ForcedStop"
#define EXC_IMPROPER_ARGS       EXCEPTION "::InvalidArgs"
#define EXC_IMPROPER_TYPE       EXCEPTION "::ImproperType"
#define EXC_INTERNAL_ERROR      EXCEPTION "::InternalError"
#define EXC_INVALID_DIMENSIONS  EXCEPTION "::InvalidDimensions"
#define EXC_INVALID_RETURN      EXCEPTION "::InvalidReturn"
#define EXC_INVALID_USE         EXCEPTION "::InvalidUse"
#define EXC_OUT_OF_MEMORY       EXCEPTION "::OutOfMemory"
#define EXC_ROUNDOFF_LIMITED    EXCEPTION "::RoundoffLimited"

/**********************************************************
  Exception handling
*/

static SV*
format_message( pTHX_ const char *format, va_list args ) {
    va_list copy;
    int length;
    int written;
    SV *message;

    if ( ! format )
        format = "";

    va_copy( copy, args );
    length = vsnprintf( NULL, 0, format, copy );
    va_end( copy );
    if ( length < 0 )
        length = 0;

    message = newSV( (STRLEN) ( length ? length : 1 ) );
    SvUPGRADE( message, SVt_PV );
    SvPOK_only( message );
    SvCUR_set( message, (STRLEN) length );
    va_copy( copy, args );
    written = vsnprintf( SvPVX( message ), (size_t) length + 1, format, copy );
    va_end( copy );
    SvCUR_set( message, (STRLEN) ( written < 0 ? 0 : written ));
    *SvEND( message ) = '\0';
    return message;
}

static SV*
new_exception_object_v( pTHX_ const char *pclass, const char *format, va_list args ) {

    SV* object;
    int count;
    SV* message = format_message( aTHX_ format, args );

    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP,2);
    mPUSHs(newSVpv(pclass, 0 ));
    PUSHs(sv_2mortal(message));
    PUTBACK;

    count = call_method( "new", G_SCALAR );

    SPAGAIN;

    if (count != 1)
        croak("Internal Error: new_exception_object: exception constructor returned %d values, expected 1\n", count );

    object = POPs;

    /* increment ref count otherwise the LEAVE below destroys it */
    SvREFCNT_inc_simple_void_NN(object);

    PUTBACK;
    FREETMPS;
    LEAVE;

    return object;
}

static SV*
new_exception_object( pTHX_ const char *pclass, const char *format, ... ) {
    va_list args;
    SV *object;

    va_start( args, format );
    object = new_exception_object_v( aTHX_ pclass, format, args );
    va_end( args );
    return object;
}

static SV*
new_nlopt_exception_v( pTHX_ int iclass, const char *format, va_list args ) {

    const char * pclass;

    switch( iclass ) {
    case NLOPT_FAILURE:
        pclass = EXC_FAILURE;
        if ( NULL == format )
            format = "failure";
        break;

    case NLOPT_OUT_OF_MEMORY:
        pclass = EXC_OUT_OF_MEMORY;
        if ( NULL == format )
            format = "out of memory";
        break;

    case NLOPT_INVALID_ARGS:
        pclass = EXC_IMPROPER_ARGS;
        if ( NULL == format )
            format = "invalid argument";
        break;

    case NLOPT_ROUNDOFF_LIMITED:
        pclass = EXC_ROUNDOFF_LIMITED;
        if ( NULL == format )
            format = "roundoff limited";
        break;

    case NLOPT_FORCED_STOP:
        pclass = EXC_FORCED_STOP;
        if ( NULL == format )
            format = "forced stop";
        break;

    default:
        pclass = EXC_EXCEPTION;
        break;
    }

    return new_exception_object_v( aTHX_ pclass, format, args );
}

static SV*
new_nlopt_exception( pTHX_ int iclass, const char *format, ... ) {
    va_list args;
    SV *object;

    va_start( args, format );
    object = new_nlopt_exception_v( aTHX_ iclass, format, args );
    va_end( args );
    return object;
}

static void
throw_nlopt( pTHX_ int iclass, const char *format, ... ) {
    va_list args;
    SV *exception;

    va_start( args, format );
    exception = new_nlopt_exception_v( aTHX_ iclass, format, args );
    va_end( args );
    croak_sv( exception );
}

static void
throw_class( pTHX_ const char *pclass, const char *format, ... ) {
    va_list args;
    SV *exception;

    va_start( args, format );
    exception = new_exception_object_v( aTHX_ pclass, format, args );
    va_end( args );
    croak_sv( exception );
}


/**********************************************************
  Generic stuff
*/

#define SV2AV(sv) sv2av( aTHX_ sv)

static AV*
sv2av( pTHX_ SV* sv ) {

    if ( SvROK( sv ) && SvTYPE(SvRV(sv)) == SVt_PVAV )
        return (AV*) SvRV(sv);

    if ( SvTYPE(sv) == SVt_PVAV )
        return (AV*) sv;

    throw_class( aTHX_ EXC_INTERNAL_ERROR, "internal error: unknown SV passed to sv2av" );
    /* NOT REACHED */

    return NULL;
}

static double*
new_mortal_double( pTHX_ SSize_t len ) {
    return (double*) SvPVX( sv_2mortal(newSV(len * sizeof(double))) );
}

static SV*
dup_subref( pTHX_ SV* sub ) {
    if ( ! ( SvTYPE(sub) == SVt_PV || (SvROK(sub) && SvTYPE(SvRV(sub)) == SVt_PVCV ) ) )
        throw_class( aTHX_ EXC_IMPROPER_ARGS, "subroutine must either be a codref or string" );

    return newSVsv(sub);
}

static void
assert_UV_range( pTHX_ UV value, unsigned min, const char* var ) {

    if ( (min > 0 && value < min) || ( sizeof(UV) > sizeof(unsigned) && value > UINT_MAX ) ) {
        throw_nlopt( aTHX_ NLOPT_INVALID_ARGS,
                     "%s must be in range [%u,%u]", var, min, UINT_MAX );
    }
}

/**********************************************************
  One dimensional Perl arrays
*/

static AV*
populate_AV1D ( pTHX_ AV* array, SSize_t n ) {
    SSize_t i;

    av_extend( array, n - 1 );
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
new_AV1D ( pTHX_ SSize_t n ) {
    AV* arr = newAV();

    if ( n > 0 )
        populate_AV1D( aTHX_ arr, n );

    return newRV_noinc((SV*) arr );
}

/* create a new AV array from a C double array */
static AV*
newAV1D_double( pTHX_ unsigned n, const double *src ) {
    AV* dst = newAV();
    av_extend(dst, n - 1);

    for ( SSize_t i = 0  ; i < n ; i++ )
        av_store(dst, i, newSVnv(src[i]) );

    return dst;
}


static AV*
cp_double_to_AV1D( pTHX_ SSize_t n, const double *src, AV* dst ) {
    av_clear(dst);
    av_extend(dst, n - 1);

    for ( SSize_t i = 0  ; i < n ; i++ )
        av_store(dst, i, newSVnv(src[i]) );

    return dst;
}

static double *
cp_AV1D_to_double( pTHX_ AV* src, double *dst ) {
    SSize_t len = av_count( src );

    for ( SSize_t i = 0; i < len ; i++ ) {
        SV** svp = av_fetch( src, i, 1 );
        if ( svp == NULL )
            throw_class( aTHX_ EXC_INTERNAL_ERROR, "internal error: NULL svp" );
        dst[i] = SvNVx( *svp );
    }

    return dst;
}

/* copy an AV to a double array created in a mortal SV */
static double *
cp_AV1D_to_mortal_double( pTHX_ AV* src ) {
    return cp_AV1D_to_double( aTHX_ src, new_mortal_double( aTHX_ av_count(src) ) );
}

static void
AV1D_move( pTHX_ AV* src, AV* dst ) {
    SSize_t src_len = av_count( src );
    SSize_t dst_len;
    SSize_t idx;

    if ( src_len == 0 )
        return ;

    dst_len = av_count( dst );
    av_extend( dst, src_len + dst_len - 1 );

    for ( idx = 0 ; idx < src_len ; idx++ )
        av_push( dst, av_shift( src ) );
}

static SV*
validate_length_AV1D( pTHX_ SSize_t len, AV* arr, const char* var ) {
    if ( len == av_count(arr) )
        return NULL;

    return new_exception_object( aTHX_ EXC_INVALID_DIMENSIONS,
                                 "%s has length %" UVuf "; expected %" UVuf,
                                 var, (UV) av_count(arr), (UV) len );
}

static void
assert_AV1D_length( pTHX_ SSize_t len, AV* arr, const char* var ) {

    SV* exception = validate_length_AV1D( aTHX_ len, arr, var );

    if ( exception )
        croak_sv( exception);

    return;
}

/**********************************************************
  Two-dimensional Matrices
*/

static SV*
new_AV2D ( pTHX_ unsigned m, unsigned n ) {
    AV* matrix = newAV();

    av_extend( matrix, m - 1 );
    for ( unsigned i = 0; i < m; i++ )
        av_store( matrix, i, new_AV1D( aTHX_ n ) );

    return newRV_noinc((SV*) matrix );
}


static AV*
cp_double_to_AV2D ( pTHX_ unsigned m, unsigned n, const double *src, AV* dst ) {
    for ( unsigned i = 0; i < m; i++ ) {
        SV** svp = av_fetch( dst, i, 1 );
        cp_double_to_AV1D( aTHX_ n, src + i * n, (AV*) SvRV( *svp ) );
    }

    return dst;
}

static double*
cp_AV2D_to_double ( pTHX_ unsigned m, unsigned n, AV* src, double *dst ) {
    for ( unsigned i = 0; i < m; i++ ) {
        SV** svp = av_fetch( src, i, 1 );
        cp_AV1D_to_double( aTHX_ (AV*) SvRV( *svp ), dst + i * n );
    }

    return dst;
}

static SV*
validate_length_AV2D ( pTHX_ unsigned m, unsigned n, AV* matrix, const char* var ) {
    if ( av_count( matrix ) != m )
        return new_exception_object( aTHX_ EXC_INVALID_DIMENSIONS,
                                     "%s has length %" UVuf "; expected %" UVuf,
                                     var, (UV) av_count( matrix ), (UV) m );

    for ( unsigned i = 0; i < m; i++ ) {
        SV** svp = av_fetch( matrix, i, 1 );
        if ( svp == NULL || !SvROK( *svp ) || SvTYPE( SvRV( *svp ) ) != SVt_PVAV )
            return new_exception_object( aTHX_ EXC_IMPROPER_TYPE,
                                         "%s[%u] is not an ARRAY reference", var, i );

        AV* row = (AV*) SvRV( *svp );
        if ( av_count( row ) != n )
            return new_exception_object( aTHX_ EXC_INVALID_DIMENSIONS,
                                         "%s[%u] has length %" UVuf "; expected %" UVuf,
                                         var, i, (UV) av_count( row ), (UV) n );
    }

    return NULL;
}

/**********************************************************
   Proxy for the NLopt object.
 */

typedef struct {
    nlopt_opt  self;
    unsigned int dimension;
    bool exceptions_enabled;

    /* The first exception raised by a Perl callback.  Callback proxies
       catch Perl exceptions while inside NLopt, request a forced stop,
       and the optimize XSUB rethrows this value after NLopt unwinds. */
    SV* exception;

    nlopt_result result;

    nlopt_result optimize_result;
    double optimum_value;
    AV*  optimum_params;

    /* store proxy structures in AV; will be GC'd in DESTROY */
    AV* cache;
    AV* objective;
    AV* equality_constraints;
    AV* inequality_constraints;
} ProxyNLopt;

typedef ProxyNLopt* NLopt;

SV* new_ProxyNLopt( pTHX_ nlopt_opt self ) {

    SV* sv_proxy = newSV(sizeof(ProxyNLopt));
    ProxyNLopt * proxy = (ProxyNLopt*) SvPVX( sv_proxy );

    proxy->self = self;
    proxy->dimension = nlopt_get_dimension( self );

    proxy->cache = newAV();

    proxy->objective = newAV();
    av_push( proxy->cache, newRV_noinc((SV*) proxy->objective) );

    proxy->inequality_constraints = newAV();
    av_push( proxy->cache, newRV_noinc((SV*) proxy->inequality_constraints) );

    proxy->equality_constraints = newAV();
    av_push( proxy->cache, newRV_noinc( (SV*) proxy->equality_constraints ) );

    proxy->optimum_params = newAV();
    av_push( proxy->cache, newRV_noinc( (SV*) proxy->optimum_params ) );

    proxy->exceptions_enabled = 1;
    proxy->optimize_result = NLOPT_FAILURE;
    proxy->optimum_value = (double) NV_NAN;

    return sv_proxy;
}

nlopt_result
assert_result ( pTHX_ NLopt opt, nlopt_result result ) {

    opt->result = result;

    if ( result < NLOPT_SUCCESS ) {
        const char *errmsg = nlopt_get_errmsg( opt->self );
        throw_nlopt( aTHX_ result, "%s", errmsg ? errmsg : "" );
    }

    return result;
}

/**********************************************************
   Proxy for Optimization and Scalar Constraint functions
*/

typedef struct {
    NLopt opt;
    SV* perl_sub; /* PV or SV to CV */
    SV* x;        /* RV to AV */
    SV* gradient; /* RV to AV */
    SV* data;
    SV* precond;  /* PV containiing possible ProxyPreCondFunc;
                     only used when this is a subsidiary func of that */
} ProxyFunc;

static SV*
new_ProxyFunc( pTHX_ NLopt opt, SV* sub, unsigned n, SV* data, AV* cache ) {

    SV* sv_proxy = newSV(sizeof(ProxyFunc));
    av_push( cache, sv_proxy );
    ProxyFunc* proxy = (ProxyFunc*) SvPVX( sv_proxy );

    proxy->opt = opt;
    proxy->perl_sub = dup_subref( aTHX_ sub);
    av_push(cache, proxy->perl_sub );

    if ( !SvOK(data) ) {
        proxy->data = &PL_sv_undef;
    }
    else {
        proxy->data = newSVsv(data);
        av_push( cache, proxy->data );
    }

    proxy->x = new_AV1D( aTHX_ n );
    av_push( cache, proxy->x );

    proxy->gradient = new_AV1D( aTHX_ 0 );
    av_push( cache, proxy->gradient );

    proxy->precond = NULL;

    return sv_proxy;
}

/* proxy passed to NLopt for arguments of type nlopt_func

   Perl exceptions cannot be allowed to unwind through NLopt's C stack.
   G_EVAL catches them here; the exception is copied into the owning
   optimizer and nlopt_force_stop() lets the enclosing XSUB regain control.
*/
static double
proxy_func ( unsigned n, const double *x, double *gradient, void *data ) {

    int count;
    double retval;
    ProxyFunc *proxy = (ProxyFunc *) SvPVX( (SV*) data);
    NLopt opt = proxy->opt;
    SV* err_tmp = NULL;

    dTHX;  /* this is called from C, not from a perl routine, so can't
              put it in the argument list */

    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP,3);
    cp_double_to_AV1D( aTHX_  n, x, SV2AV(proxy->x) );
    PUSHs( proxy->x );

    if ( NULL == gradient )
        PUSHs(&PL_sv_undef);
    else {
        AV* array = (AV*) SvRV( proxy->gradient );
        /* populate if not already done so */
        if ( av_count( array ) == 0 )
            populate_AV1D( aTHX_ array, n );
        PUSHs( proxy->gradient );
    }

    PUSHs(proxy->data);
    PUTBACK;

    /* if G_SCALAR is used,

         - return() becomes one undef;
         - return (1, 2) becomes one scalar result.

         To get the actual count requires using G_LIST
    */
    count = call_sv( proxy->perl_sub, G_LIST | G_EVAL);

    SPAGAIN;

    err_tmp = ERRSV;
    /* ERRSV remains defined but empty after a successful G_EVAL call.  A
     * reference must still count as an exception when its overloaded
     * boolean value is false. */
    if (SvROK(err_tmp) || SvTRUE(err_tmp) ) {

        /* cache the first exception and stop the active optimization;
           the optimize XSUB rethrows it after NLopt returns. */
        if ( ! opt->exception ) {
            opt->exception = newSVsv( err_tmp );
            nlopt_force_stop( opt->self );
        }

        /* G_LIST | G_EVAL leaves an undef placeholder on the stack
           when the callback dies.  Discard it without converting it. */
        while ( count-- > 0 )
            POPs;
        retval = NV_NAN;
    }
    else {
        if (count != 1) {
            if ( ! opt->exception ) {
                opt->exception = new_exception_object(
                    aTHX_ EXC_INVALID_RETURN,
                    "proxy_func: func returned %d values, expected 1\n", count );
            }
            nlopt_force_stop( opt->self );
            while ( count-- > 0 )
                POPs;
            retval = NV_NAN;
        }
        else
            retval = POPn;

        /* copy this back to the array the caller knows about */
        if ( NULL != gradient ) {
            err_tmp = validate_length_AV1D( aTHX_ n, SV2AV(proxy->gradient), "gradient" );

            if ( err_tmp ) {
                nlopt_force_stop( opt->self );
                if ( ! opt->exception )
                    opt->exception = err_tmp;
                else
                    sv_2mortal(err_tmp);
            }
            else
                cp_AV1D_to_double( aTHX_  SV2AV(proxy->gradient), gradient );
        }
    }

    PUTBACK;
    FREETMPS;
    LEAVE;

    return retval;
}

/**********************************************************
   Proxy for Vector Constraint functions
 */

typedef struct {
    NLopt opt;
    SV* perl_sub;
    SV* x;        /* RV to AV */
    SV* gradient; /* RV to AV */
    SV* result;   /* RV to AV */
    SV* data;
} ProxyMFunc;

static SV*
new_ProxyMFunc( pTHX_ NLopt opt, SV* sub, unsigned n, unsigned m, SV* data, AV* cache ) {

    SV* sv_proxy = newSV(sizeof(ProxyMFunc));
    av_push( cache, sv_proxy );

    ProxyMFunc * proxy = (ProxyMFunc*) SvPVX( sv_proxy );

    proxy->opt = opt;
    proxy->perl_sub = dup_subref( aTHX_ sub);
    av_push(cache, proxy->perl_sub );

    if ( ! SvOK(data) ) {
        proxy->data = &PL_sv_undef;
    }
    else {
        proxy->data = newSVsv(data);
        av_push( cache, proxy->data );
    }

    proxy->x = new_AV1D( aTHX_ n );
    av_push( cache, proxy->x );

    proxy->gradient = new_AV2D( aTHX_ m, n );
    av_push( cache, proxy->gradient );

    proxy->result = new_AV1D (aTHX_ m );
    av_push( cache, proxy->result );

    return sv_proxy;
}


static void
proxy_mfunc( unsigned m, double *result, unsigned n, const double* x, double* gradient, void *data) {

    ProxyMFunc *proxy = (ProxyMFunc *) SvPVX( (SV*) data);
    NLopt opt = proxy->opt;
    SV* err_tmp = NULL;

    dTHX;  /* this is called from C, not from a perl routine, so can't
              put it in the argument list */

    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP,4);

    PUSHs( proxy->result);
    cp_double_to_AV1D( aTHX_  n, x, SV2AV(proxy->x) );
    PUSHs( proxy->x  );

    /* Perl sees the constraint gradient as [m][n]: one row per constraint
       component, with one column per optimization parameter.  NLopt's
       buffer is row-major in the same order. */
    if ( NULL == gradient )
        PUSHs(&PL_sv_undef);
    else {
        AV* array = (AV*) SvRV( proxy->gradient );
        cp_double_to_AV2D( aTHX_ m, n, gradient, array );
        PUSHs( proxy->gradient );
    }

    PUSHs(proxy->data);
    PUTBACK;

    /* Results of vector constraint functions are written through the
       result/gradient arguments, not returned from Perl.  G_VOID therefore
       both supplies the correct Perl context and leaves no return values
       to process after the call. */
    call_sv( proxy->perl_sub, G_VOID | G_EVAL );

    err_tmp = ERRSV;
    if (SvROK(err_tmp) || SvTRUE(err_tmp) ) {

        /* cache the first exception and stop the active optimization;
           the optimize XSUB rethrows it after NLopt returns. */
        if ( ! opt->exception ) {
            opt->exception = newSVsv( err_tmp );
            nlopt_force_stop( opt->self );
        }
    }
    else {
        /* copy this back to the array the caller knows about */
        err_tmp = validate_length_AV1D( aTHX_ m, SV2AV(proxy->result), "result" );
        if ( err_tmp ) {
            nlopt_force_stop( opt->self );
            if ( ! opt->exception )
                opt->exception = err_tmp;
            else
                sv_2mortal(err_tmp);
        }
        else {
            cp_AV1D_to_double( aTHX_  SV2AV(proxy->result), result );

            /* and this as well */
            if ( NULL != gradient ) {
                err_tmp = validate_length_AV2D( aTHX_ m, n, SV2AV(proxy->gradient), "gradient" );
                if ( err_tmp ) {
                    nlopt_force_stop( opt->self );
                    if ( ! opt->exception )
                        opt->exception = err_tmp;
                    else
                        sv_2mortal(err_tmp);
                }
                else
                    cp_AV2D_to_double( aTHX_ m, n, SV2AV(proxy->gradient), gradient );
            }
        }
    }

    FREETMPS;
    LEAVE;
}

/**********************************************************
   Proxy for Pre-conditioned optimization functions
 */

typedef struct {
    NLopt opt;
    SV* perl_sub;
    SV* x;     /* RV to AV */
    SV* v;     /* RV to AV */
    SV* vpre;  /* RV to AV */
    SV* data;
} ProxyPreCondFunc;

static SV*
new_ProxyPreCondFunc( pTHX_ NLopt opt, SV* sub, unsigned n, SV* data, AV* cache ) {

    SV* sv_proxy = newSV(sizeof(ProxyPreCondFunc));
    av_push( cache, sv_proxy );
    ProxyPreCondFunc * proxy = (ProxyPreCondFunc*) SvPVX( sv_proxy );

    proxy->opt = opt;
    proxy->perl_sub = dup_subref( aTHX_ sub);
    av_push(cache, proxy->perl_sub );

    if ( ! SvOK(data) ) {
        proxy->data = &PL_sv_undef;
    }
    else {
        proxy->data = newSVsv(data);
        av_push( cache, proxy->data );
    }

    proxy->x = new_AV1D( aTHX_ n );
    av_push( cache, proxy->x );

    proxy->v = new_AV1D( aTHX_ n );
    av_push( cache, proxy->v );

    proxy->vpre = new_AV1D( aTHX_ n );
    av_push( cache, proxy->vpre );

    return sv_proxy;
}


static void
proxy_precond( unsigned n, const double *x, const double *v, double *vpre, void *f_data) {

    /* there's only one user data available when using
       preconditioners, but two functions, so we piggy back on the
       user data for the main objective function */
    ProxyPreCondFunc *proxy;
    NLopt opt;
    SV* err_tmp = NULL;

    dTHX;  /* this is called from C, not from a perl routine, so can't
              put it in the argument list */

    proxy = (ProxyPreCondFunc*) SvPVX( ((ProxyFunc *) SvPVX( (SV*) f_data))->precond );
    opt = proxy->opt;

    dSP;
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP,4);

    /* transfer from C arrays to Perl array, and push the Perl array on the argument stack */
    cp_double_to_AV1D( aTHX_  n, x, SV2AV(proxy->x) );
    PUSHs( proxy->x  );
    cp_double_to_AV1D( aTHX_  n, v, SV2AV(proxy->v) );
    PUSHs( proxy->v );
    PUSHs( proxy->vpre );

    PUSHs(proxy->data);
    PUTBACK;

    call_sv( proxy->perl_sub, G_VOID | G_EVAL );

    err_tmp = ERRSV;
    if (SvROK(err_tmp) || SvTRUE(err_tmp) ) {

        /* cache the first exception and stop the active optimization;
           the optimize XSUB rethrows it after NLopt returns. */
        if ( ! opt->exception ) {
            opt->exception = newSVsv( err_tmp );
            nlopt_force_stop( opt->self );
        }
    }
    else {
        /* return the results to the caller */
        err_tmp = validate_length_AV1D( aTHX_ n, SV2AV(proxy->vpre), "vpre" );
        if ( err_tmp ) {
            nlopt_force_stop( opt->self );
            if ( ! opt->exception )
                opt->exception = err_tmp;
            else
                sv_2mortal(err_tmp);
        }
        else
        cp_AV1D_to_double( aTHX_  SV2AV(proxy->vpre), vpre );
    }

    FREETMPS;
    LEAVE;

}

/**********************************************************
   Perl to C typemaps
 */

typedef nlopt_result validated_result;

MODULE = Math::NLopt		PACKAGE = Math::NLopt		PREFIX = nlopt_

TYPEMAP: <<EOT
const char *					T_PV
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

# convert from an input Math::NLopt object to the underlying NLopt object

T_nlopt_opt
    if (sv_isa($arg, \"$Package\")) {
        ProxyNLopt* proxy = (ProxyNLopt*) SvPVX( SvRV($arg) );
        if ( ! proxy->self )
            throw_class( aTHX_ EXC_INVALID_USE, \"attempt to use object after destruction\" );
        $var = proxy->self;
    }
    else {
        const char* refstr = SvROK($arg) ? \"\" : SvOK($arg) ? \"scalar \" : \"undef\";
        throw_class( aTHX_ EXC_IMPROPER_TYPE, \"%s: Expected %s to be of type %s; got %s%\" SVf \" instead\",
                ${$ALIAS?\q[GvNAME(CvGV(cv))]:\qq[\"$pname\"]},
                \"$var\", \"Math::NLopt\",
                refstr, $arg
        );
    }

# convert from an input Math::NLopt object to the proxy object

T_NLopt
    if (sv_isa($arg, \"$Package\")) {
        ProxyNLopt* proxy = (ProxyNLopt*) SvPVX( SvRV($arg) );
        ${ $pname =~ /DESTROY$/ ? \q[] : \qq[
        if ( ! proxy->self )
            throw_class( aTHX_ EXC_INVALID_USE, \"attempt to use object after destruction\" );
        ]}
        $var = proxy;
    }
    else {
        const char* refstr = SvROK($arg) ? \"\" : SvOK($arg) ? \"scalar \" : \"undef\";
        throw_class( aTHX_ EXC_IMPROPER_TYPE, \"%s: Expected %s to be of type %s; got %s%\" SVf \" instead\",
                ${$ALIAS?\q[GvNAME(CvGV(cv))]:\qq[\"$pname\"]},
                \"$var\", \"$Package\",
                refstr, $arg
        );
    }

OUTPUT

# automatically handle throwing exceptions for routines which return an nlopt_result

# this mess assumes that the first argument, ST(0), is an NLopt . it's equivalent to assert_result( opt, RETVAL)
T_VALIDATED_RESULT
        ${ "$var" eq "RETVAL" ? \"$arg = newSViv(assert_result(aTHX_ (ProxyNLopt*) SvPVX( SvRV(ST(0))),$var));" : croak('INTERNAL ERROR VALIDATED_RESULT ONLY USES RETVAL'); }


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
                    throw_class( aTHX_ EXC_IMPROPER_TYPE, \"%s: %s is not an ARRAY reference\",
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
_add_equality_constraint(opt, func, tol_SV, data )
        NLopt	opt
        SV*	 func
        SV*  	 tol_SV
        SV*	 data
    ALIAS:
        _add_equality_constraint = 1
        _add_inequality_constraint = 2
    PREINIT:
        SV*	 proxy;
        AV*      tcache;
        double tol = 0;
    CODE:
        if ( SvOK(tol_SV) )
            tol = SvNV(tol_SV);
        sv_2mortal( (SV*) ( tcache = newAV() ) );
        proxy = new_ProxyFunc( aTHX_ opt, func, opt->dimension, data, tcache );
        if ( ix == 1 )
            RETVAL = nlopt_add_equality_constraint( opt->self, &proxy_func, (void*) proxy, tol);
        else
            RETVAL = nlopt_add_inequality_constraint( opt->self, &proxy_func, (void*) proxy, tol);

        if ( RETVAL == NLOPT_SUCCESS )
            AV1D_move( aTHX_ tcache, ix == 1 ? opt->equality_constraints : opt->inequality_constraints);
        else
            av_clear( tcache );
    OUTPUT:
        RETVAL

validated_result
_add_equality_mconstraint(opt, func, m, tol_SV, data )
        NLopt	 opt
        SV*	 func
        UV       m
        SV*  	 tol_SV
        SV*	 data
    ALIAS:
        _add_equality_mconstraint = 1
        _add_inequality_mconstraint = 2
    PREINIT:
        SV*	 proxy;
        AV*      tcache;
        double *tol = NULL;
    CODE:
        assert_UV_range( aTHX_ m, 1, "m" );
        sv_2mortal( (SV*) ( tcache = newAV() ) );
        proxy = new_ProxyMFunc( aTHX_ opt,  func, opt->dimension, m, data, tcache );

        /* NLopt copies the tolerances, so we just need a temp C array */
        if ( SvOK(tol_SV ) ) {
            AV* tol_AV = SV2AV(tol_SV);
            assert_AV1D_length( aTHX_ m, tol_AV, "tol" );
            tol = cp_AV1D_to_mortal_double( aTHX_  tol_AV );
        }
        if ( ix == 1 )
            RETVAL = nlopt_add_equality_mconstraint( opt->self, m, &proxy_mfunc, (void*) proxy, tol);
        else
            RETVAL = nlopt_add_inequality_mconstraint( opt->self, m, &proxy_mfunc, (void*) proxy, tol);

        if ( RETVAL == NLOPT_SUCCESS )
            AV1D_move( aTHX_ tcache, ix == 1 ? opt->equality_constraints : opt->inequality_constraints);
        else
            av_clear( tcache );
    OUTPUT:
        RETVAL

# nlopt_algorithm is unsigned, but nlopt_algorithm_from_string returns -1 on error,
# which gets mangled when cast to a signed int, so just call it what it is
int
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
        UV	n
    PREINIT:
        SV* rv;
        nlopt_opt opt;
    CODE:
        assert_UV_range( aTHX_ n, 1, "n" );
        if ( algorithm < 0 || algorithm >= NLOPT_NUM_ALGORITHMS )
            throw_nlopt( aTHX_ NLOPT_INVALID_ARGS, "invalid algorithm" );

        opt = nlopt_create( algorithm, n );
        if ( NULL == opt )
            throw_nlopt( aTHX_ NLOPT_OUT_OF_MEMORY, NULL );

        rv = newRV_noinc( new_ProxyNLopt( aTHX_ opt ) );
        sv_bless( rv, gv_stashsv( classname, GV_NOADD_NOINIT ) );
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
        if ( opt->self ) {
            nlopt_destroy(opt->self);
            SvREFCNT_dec( opt->cache );
            opt->self = NULL;
        }

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
        assert_AV1D_length( aTHX_ n, x, "x" );
        c_x = cp_AV1D_to_mortal_double( aTHX_  x);
        c_dx = new_mortal_double( aTHX_ n);
        assert_result( aTHX_ opt, nlopt_get_initial_step( opt->self, c_x, c_dx ) );
        RETVAL = newAV1D_double( aTHX_  n, c_dx );
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
        c_lb = new_mortal_double( aTHX_ n);
        assert_result( aTHX_ opt, nlopt_get_lower_bounds(opt->self, c_lb ) );
        RETVAL = newAV1D_double( aTHX_  n, c_lb );
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
        c_ub = new_mortal_double( aTHX_ n);
        assert_result( aTHX_ opt, nlopt_get_upper_bounds( opt->self, c_ub ) );
        RETVAL = (AV*) newAV1D_double( aTHX_  n, c_ub );
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
        c_w = new_mortal_double( aTHX_ n);
        assert_result( aTHX_ opt, nlopt_get_x_weights( opt->self, c_w ) );
        RETVAL = newAV1D_double( aTHX_  n, c_w );
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
        c_tol = new_mortal_double( aTHX_ n);
        assert_result( aTHX_ opt, nlopt_get_xtol_abs( opt->self, c_tol ) );
        RETVAL = (AV*) newAV1D_double( aTHX_  n, c_tol );
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
last_optimum_params ( opt )
        NLopt opt
     CODE:
         RETVAL = (AV*) SvREFCNT_inc((SV*)opt->optimum_params);
     OUTPUT:
        RETVAL

void
set_exceptions_enabled( opt, enable )
      NLopt	opt
      bool      enable
    CODE:
      opt->exceptions_enabled = enable;

bool
get_exceptions_enabled( opt )
      NLopt	opt
    CODE:
      RETVAL = opt->exceptions_enabled;
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
        assert_AV1D_length( aTHX_ n, x, "x" );
        c_x = cp_AV1D_to_mortal_double( aTHX_ x );
        /* store result first, then validate it, so that if assert_result throws
           the result is available via last_optimize_result
         */
        opt->exception = NULL;
        opt->optimize_result = nlopt_optimize( opt->self, c_x, &(opt->optimum_value) );
        cp_double_to_AV1D( aTHX_ n, c_x, opt->optimum_params);
        if ( opt->exception ) {
            SV* exception = opt->exception;
            opt->exception = NULL;
            sv_2mortal( exception );
            croak_sv(exception);
        }
        if ( opt->exceptions_enabled )
            assert_result( aTHX_ opt, opt->optimize_result );
        else
            opt->result = opt->optimize_result;
        RETVAL = (AV*) SvREFCNT_inc( (SV*) opt->optimum_params);
    OUTPUT:
        RETVAL

validated_result
nlopt_remove_equality_constraints(opt)
        NLopt	opt
    CODE:
        RETVAL = nlopt_remove_equality_constraints( opt->self );
        av_clear( opt->equality_constraints );
    OUTPUT:
        RETVAL

validated_result
nlopt_remove_inequality_constraints(opt)
        NLopt	opt
    CODE:
        RETVAL = nlopt_remove_inequality_constraints( opt->self );
        av_clear( opt->inequality_constraints );
    OUTPUT:
        RETVAL

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
        assert_AV1D_length( aTHX_ opt->dimension, dx, "dx" );
        /* NLopt makes a copy; don't need to keep it around */
        c_dx = cp_AV1D_to_mortal_double( aTHX_ dx);
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
        assert_AV1D_length( aTHX_ opt->dimension, lb, "lb" );
        /* NLopt makes a copy; don't need to keep it around */
        c_lb = cp_AV1D_to_mortal_double( aTHX_ lb );
        RETVAL = nlopt_set_lower_bounds( opt->self, c_lb);
     OUTPUT:
       RETVAL

validated_result
nlopt_set_lower_bounds1(opt, lb)
        nlopt_opt	opt
        double	lb

validated_result
nlopt_set_maxeval(opt, maxeval)
        nlopt_opt	opt
        int	maxeval

validated_result
nlopt_set_maxtime(opt, maxtime)
        nlopt_opt	opt
        double	maxtime

validated_result
set_min_objective(opt, f, ... )
        NLopt	opt
        SV*	f
      ALIAS:
        set_min_objective = 1
        set_max_objective = 2
      PREINIT:
        SV * func;
        SV * f_data;
        AV * tcache;
      CODE:
        if (items > 3)
            croak_xs_usage(cv, "too many arguments" );
        f_data = items > 2 ? ST(2) : &PL_sv_undef;
        sv_2mortal( (SV*) ( tcache = newAV() ) );
        func = new_ProxyFunc( aTHX_ opt, f, opt->dimension, f_data, tcache );
        if ( ix == 1 )
            RETVAL = nlopt_set_min_objective( opt->self, &proxy_func, (void*) func );
        else
            RETVAL = nlopt_set_max_objective( opt->self, &proxy_func, (void*) func );

        if ( RETVAL == NLOPT_SUCCESS ) {
            av_clear( opt->objective );
            AV1D_move( aTHX_ tcache, opt->objective);
        }
        else
            av_clear( tcache );
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
        UV		pop
    CODE:
        assert_UV_range( aTHX_ pop, 0, "pop" );
        RETVAL = nlopt_set_population(opt, pop);
    OUTPUT:
        RETVAL

validated_result
set_precond_min_objective(opt, func, pre, ...)
        NLopt	opt
        SV*	func
        SV*	pre
      ALIAS:
        set_precond_min_objective = 1
        set_precond_max_objective = 2
      PREINIT:
        unsigned n;
        SV* proxy_f;
        SV* proxy_pre;
        SV* data;
        AV* tcache;
      CODE:
        if (items > 4)
            croak_xs_usage(cv, "too many arguments" );
        data = items > 3 ? ST(3) : &PL_sv_undef;
        n = opt->dimension;
        sv_2mortal( (SV*) ( tcache = newAV() ) );
        proxy_pre = new_ProxyPreCondFunc( aTHX_ opt, pre, n, data, tcache );
        proxy_f = new_ProxyFunc( aTHX_ opt, func, n, data, tcache );
        ((ProxyFunc*) SvPVX( proxy_f ))->precond = proxy_pre;
        if ( ix == 1 )
            RETVAL = nlopt_set_precond_min_objective( opt->self, &proxy_func, &proxy_precond, (void*) proxy_f );
        else
            RETVAL = nlopt_set_precond_max_objective( opt->self, &proxy_func, &proxy_precond, (void*) proxy_f );

        if ( RETVAL == NLOPT_SUCCESS ) {
            av_clear( opt->objective );
            AV1D_move( aTHX_ tcache, opt->objective);
        }
        else
            av_clear( tcache );
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
        assert_AV1D_length( aTHX_ opt->dimension, ub, "ub" );
        /* NLopt makes a copy; don't need to keep it around */
        c_ub = cp_AV1D_to_mortal_double( aTHX_ ub );
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
        UV		dim
    CODE:
        assert_UV_range( aTHX_ dim, 0, "dim" );
        RETVAL = nlopt_set_vector_storage(opt, dim);
    OUTPUT:
        RETVAL

validated_result
nlopt_set_x_weights(opt, w)
        NLopt	opt
        AV *	w
     PREINIT:
        double* c_w;
     CODE:
        assert_AV1D_length( aTHX_ opt->dimension, w, "w" );
        /* NLopt makes a copy; don't need to keep it around */
        c_w = cp_AV1D_to_mortal_double( aTHX_ w );
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
        assert_AV1D_length( aTHX_ opt->dimension, tol, "tol" );
        c_tol = cp_AV1D_to_mortal_double( aTHX_ tol );
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
_assert_result ( opt, result )
        NLopt opt
        nlopt_result result
     CODE:
         RETVAL = assert_result( aTHX_ opt, result );
     OUTPUT:
        RETVAL
