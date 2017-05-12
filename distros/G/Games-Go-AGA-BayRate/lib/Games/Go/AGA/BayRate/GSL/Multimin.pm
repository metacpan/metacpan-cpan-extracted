#===============================================================================
#     ABSTRACT:  Hook into GSL Multimin FMinimizer and FDFMinimizers
#
#       AUTHOR:  Reid Augustin
#        EMAIL:  reid@LucidPort.com
#      CREATED:  05/27/2011 03:56:12 PM
#===============================================================================

use strict;
use warnings;
package Games::Go::AGA::BayRate::GSL::Multimin;
use parent 'Exporter';

BEGIN {
    our @EXPORT_OK = qw(
        my_gsl_multimin_fminimizer_set
        my_gsl_multimin_fdfminimizer_set
        raw_gsl_multimin_fminimizer_fval
        raw_gsl_multimin_fdfminimizer_f
        raw_gsl_multimin_fdfminimizer_gradient
        raw_gsl_vector_size
    );
}

our $VERSION = '0.119'; # VERSION

my $libs;
BEGIN {     # see if the GSL library is available
    eval {
        $libs = `pkg-config --libs gsl 2>/dev/null`;
    };
    if (not $libs) {
        eval {
            $libs = `gsl-config --libs 2>/dev/null`;
        }
    };

    chomp $libs;
}

$libs ||= '-lgsl -lgslcblas -lm';   # cross yer fingers!

#sub DESTROY {
#    my ($self) = @_;
#
#    print "DESTROY min_struct = $self->{_minimizer_struct}\n";
#    Destroy($self->{_minimizer_struct});
#}

use Inline C => Config => LIBS => $libs;
use Inline 'C';     # C code in __DATA__

Inline->init();

1;

__DATA__
__C__

// perl's Math::GSL::Multimin is still a work in progress.
// use this glue/hack in the meantime

// Gnu Scientific Library include files
#include <gsl/gsl_types.h>
#include <gsl/gsl_multimin.h>
#include <string.h>

typedef struct {
    gsl_multimin_function * multimin_func;  // struct defined by GSL
    SV                    * params_SV;      // perl params pointer
    SV                    * f_callback_SV;  // perl function pointers (SV*)
    SV                    * df_SV;
    SV                    * fdf_SV;
    // hmm, looks like the 'x' vector might be a
    //      Math::GSL::Vector::gsl_vector object, or it might be a
    //      Math::GSL::Matrix::gsl_vector.  If we get it wrong, the
    //      type-checking fails and we die.  'df' and 'dfd' follow 'x'.  So
    //      we'll save the type here and use it when rebuilding the
    //      wrappers.
    char                  * vector_type;    // the 'x' name/type seems to vary
} my_minimizer_struct;

// extract pointer from blessed SV and convert to void pointer
// NOTE: name_cpy is a void* to suppress typemapping (if properly declared
//          as char**, we get "undefined symbol: XS_unpack_charPtrPtr" in
//          some situations).  "use Inline C => Config => prototype => {
//          _SV_to_void => 'DISABLE' }" didn't work...
void * _SV_to_void (SV * ptr, void * name_cpy)
{
//printf("_SV_to_void\n");
// reverse-engineered from SWIG_ConvertPtr in swigperlrun.h

    SV * wrapper  = SvRV(ptr);
//printf("wrapper=0x%0x\n", wrapper);

    MAGIC * magic = mg_find(wrapper, 'P');
//printf("magic=0x%0x\n", magic);

    SV * obj_ref  = magic->mg_obj;
//printf("obj_ref=0x%0x\n", obj_ref);

    SV * raw_obj  = SvRV(obj_ref);
//printf("raw_obj=0x%0x\n", raw_obj);

    if (name_cpy) {
        // get the object's stash name
         HV* stash = SvSTASH(raw_obj);
         char * obj_name = HvNAME(stash);
        // make a copy of the object's stash name

        // allocate space for copy of name
        Newx(*(char **)name_cpy, strlen(obj_name) + 1, char);
        strcpy(*(char **)name_cpy, obj_name);
    }

    return (void *)SvIV(raw_obj);
}

// create a new wrapper, insert a raw GSL object into it
// returns:
//  wrapper IV(ROK)
//     |
//     +-->magic_ref PVHV(OBJECT, RMG <--has 'other' magic: 'P' == tied?)
//            |
//            +-->magic MAGIC(tied)
//            |     |
//            |     +-->obj_ref IV(ROK)
//            |           |
//            |           +-->raw_obj = void*
//            |           +-->STASH = "name"
//            +-->STASH = "name"

SV * _new_wrapper(char * name, void * raw_obj)
{
// reverse engineered from SWIG_Perl_MakePtr in swigperlrun.h

//printf("_new_wrapper(%s, raw_obj=0x%0x, %d)\n", name, (int)raw_obj, (int)raw_obj);

    // create NULL SV to put raw_object into
    SV *obj_ref = newSV(0);
//printf("obj_ref=0x%0x\n", obj_ref);

    // put raw_obj in obj_ref, bless obj_ref if name is non-NULL
    sv_setref_pv(obj_ref, name, raw_obj);

    // create magic HASH
    HV *magic = newHV();
//printf("magic=0x%0x\n", magic);

    // add 'P' (tied?) magic to magic, put obj_ref in the mg_obj field
    sv_magic((SV *)magic, (SV *)obj_ref, 'P', Nullch, 0);
    // sv_magic incremented obj_ref refcount, back it down again
    SvREFCNT_dec(obj_ref);

    // create ref to magic
    SV * magic_ref = newRV_noinc((SV *)magic);
//printf("magic_ref=0x%0x\n", magic_ref);

    // create wrapper
    // SV * wrapper = sv_newmortal();
    SV * wrapper = newSV(0);
//printf("wrapper=0x%0x\n", wrapper);

    // put magic_ref into wrapper value
    sv_setsv(wrapper, magic_ref);

    // ??
    SvREFCNT_dec((SV *)magic_ref);

    // get STASH pointer from obj_ref
    HV *stash = SvSTASH(SvRV(obj_ref));
//printf("stash=0x%0x\n", stash);

    // bless wrapper into stash
    sv_bless(wrapper, stash);

    return wrapper;
}

// make a wrapper for a raw gsl_vector
SV * _wrap_raw_vector(const gsl_vector * raw_vector)
{
    return _new_wrapper("Math::GSL::Matrix::gsl_vector", (void*)raw_vector);
}

// make a Math::GSL::Vector wrapper around a wrapped raw gsl_vector,
// resulting in a full-fledged Math::GSL::Vector object
SV * _wrap_vector(const gsl_vector * raw_vector)
{
    // make an object HASH
    HV * gsl_vector_obj = (HV*)sv_2mortal((SV*)newHV());

    // store vector size in hash{_length}
    SV * length_SV = newSViv((int)raw_vector->size);
    hv_store(gsl_vector_obj, "_length", 7, length_SV, 0);

    // get a wrapper around raw_vector
    SV * vector_wrapper = _wrap_raw_vector(raw_vector);
    // store wrapper in hash{_vector}
//printf("Storing vector=0x%0x\n", raw_vector);
    hv_store(gsl_vector_obj, "_vector", 7, vector_wrapper, 0);

//printf("Get gsl_vector_ref from _obj=0x%0x\n", gsl_vector_obj);
    SV * gsl_vector_ref = newRV((SV*)gsl_vector_obj);
//printf("gsl_vector_ref=0x%0x\n", gsl_vector_ref);
    HV * stash = gv_stashpv("Math::GSL::Vector", GV_ADD);
//printf("stash=0x%0x\n", stash);
    sv_bless(gsl_vector_ref, stash);
//printf("return=0x%0x\n", gsl_vector_ref);

    return vector_wrapper;
}

// call converters: wrappers to convert C callbacks to perl conventions
// the GSL library will callback to these functions.
double call_f (const gsl_vector * x, void * params) {
    int count;
    double ret;
    my_minimizer_struct * self = params;    // use params to pass instance ptr

    dSP;       // init perl stack pointer
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(_new_wrapper(self->vector_type, (void*)x));
    XPUSHs(self->params_SV);
    PUTBACK;
    count = call_sv(self->f_callback_SV, G_EVAL|G_SCALAR);
    SPAGAIN;

    /* Check the eval */
    if (SvTRUE(ERRSV))
        croak ("call_f: %s\n", SvPV(ERRSV, PL_na));
    else if (count != 1)
        croak("call to f returned %d items (expecting 1)\n", count);

    ret = POPn;
    PUTBACK;
    FREETMPS;
    LEAVE;
    return ret;
}

void call_df (const gsl_vector * v, void * params, const gsl_vector * df) {

    my_minimizer_struct * self = params;    // use params to pass instance ptr

    dSP;       // init perl stack pointer
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);

    XPUSHs(_new_wrapper(self->vector_type, (void*)v));
    XPUSHs(self->params_SV);
    XPUSHs(_new_wrapper(self->vector_type, (void*)df));
    PUTBACK;

    call_sv(self->df_SV, G_EVAL|G_SCALAR);
    SPAGAIN;

    /* Check the eval */
    if (SvTRUE(ERRSV))
        croak ("call_df: %s\n", SvPV(ERRSV, PL_na));
    PUTBACK;
    FREETMPS;
    LEAVE;
}

void call_fdf (const gsl_vector * x, void * params, double *f, const gsl_vector * df) {

    my_minimizer_struct * self = params;    // use params to pass instance ptr

    dSP;       // init perl stack pointer
    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
//printf("call _new_wrapper(self->vector_type=%s, x=0x%x)\n", self->vector_type, (int)x);
    XPUSHs(_new_wrapper(self->vector_type, (void*)x));
    XPUSHs(self->params_SV);
    SV* f_callback_SV = newSV(0);            // create f
    SV* sv_f_ref = newRV_inc(f_callback_SV); // ptr to f so fdf can say *f=...
    XPUSHs(sv_f_ref);
//printf("call _wrap_raw_vector(self->vector_type=%s, df=0x%x)\n", self->vector_type, (int)df);
    XPUSHs(_new_wrapper(self->vector_type, (void*)df));
    PUTBACK;

    call_sv(self->fdf_SV, G_EVAL|G_SCALAR);
    SPAGAIN;

    /* Check the eval */
    if (SvTRUE(ERRSV))
        croak ("call_fdf: %s\n", SvPV(ERRSV, PL_na));
    *f = SvNV(f_callback_SV);
    PUTBACK;
    SvREFCNT_dec(sv_f_ref);

    FREETMPS;
    LEAVE;
}

// combine struct allocation/initialization and minimzer_set
// void my_gsl_multimin_fminimizer_set (
//     $gsl_multimin_fminimizer_nmsimplex2,    # type
//     \&_my_f,   # gsl_multimin_function . f       function
//     $count,    # gsl_multimin_function . n       number of free variables
//     $self,     # gsl_multimin_function . params  function params passed to f, df, and fdf
//     $x->raw,   # gsl vector
//     $ss->raw); # step size
void my_gsl_multimin_fminimizer_set (
    SV * f_type_SV,
    SV * f_callback_SV,
    int  dimensions,
    SV * params_SV,
    SV * x_vector_SV,
    SV * ss_vector_SV
    ) {
    Inline_Stack_Vars;      // initialize Inline:: stack variables
    gsl_multimin_fminimizer_type * f_type = _SV_to_void(f_type_SV, NULL);

    gsl_multimin_fminimizer * f_state = gsl_multimin_fminimizer_alloc(f_type, dimensions);

    my_minimizer_struct * self;             // ptr to my_minimizer_struct
    Newxz(self, 1, my_minimizer_struct);    // allocate my_minimizer_struct BUGBUG: never gets deallocated!

    gsl_multimin_function * multimin_func;
    Newxz(multimin_func, 1, gsl_multimin_function);  // allocate GSL multimin struct BUGBUG: never gets deallocated!

    self->multimin_func   = multimin_func;
    multimin_func->f      = call_f;     // perl call converter
    multimin_func->n      = dimensions; // degrees of freedom
    multimin_func->params = self;       // use params to pass pointer to my_minimizer_struct
    // GSL calls f, df, and f with params as an argument, so
    //   now our perl-call-converter has access to my_minimizer_struct.

    self->f_callback_SV      = newSVsv(f_callback_SV);    // save perl callback addresses
    // put real params here:
    self->params_SV = newSVsv(params_SV);   // pass GSL param to perl here

    // get the x vector (and its name/type), and the single-step vector
    gsl_vector * x_vector  = _SV_to_void(x_vector_SV, &self->vector_type);
    gsl_vector * ss_vector = _SV_to_void(ss_vector_SV, NULL);

    // initialize the minimizer:
    gsl_multimin_fminimizer_set (f_state, multimin_func, x_vector, ss_vector);
    Inline_Stack_Reset;
    Inline_Stack_Push(_new_wrapper("Math::GSL::Multimin::gsl_multimin_fminimizer", (void*)f_state));
    Inline_Stack_Done;
    Inline_Stack_Return(1);
}

// combine struct allocation/initialization and minimzer_set
// my_gsl_multimin_fdfminimizer_set (
//     $gsl_multimin_fdfminimizer_vector_bfgs2,    # type
//     \&_my_f,   # gsl_multimin_function_fdf . f       function
//     \&_my_df,  # gsl_multimin_function_fdf . df      derivative of f
//     \&_my_fdf, # gsl_multimin_function_fdf . fdf     f and df
//     $count,    # gsl_multimin_function_fdf . n       number of free variables
//     $self,     # gsl_multimin_function_fdf . params  function params passed to f, df, and fdf
//     $x->raw,   # gsl vector
//     2.0,       # step size
//     0.1);      # accuracy required (tol?)
void my_gsl_multimin_fdfminimizer_set (
    SV * fdf_type_SV,
    SV * f_callback_SV,
    SV * df_SV,
    SV * fdf_SV,
    int dimensions,
    SV * params_SV,
    SV * x_vector_SV,
    double step_size,
    double tol
    ) {
    Inline_Stack_Vars;      // initialize Inline:: stack variables
    gsl_multimin_fdfminimizer_type * fdf_type = _SV_to_void(fdf_type_SV, NULL);

    gsl_multimin_fdfminimizer * fdf_state = gsl_multimin_fdfminimizer_alloc(fdf_type, dimensions);

    my_minimizer_struct * self;             // ptr to my_minimizer_struct
    Newxz(self, 1, my_minimizer_struct);    // allocate my_minimizer_struct BUGBUG: never gets deallocated!

    gsl_multimin_function_fdf * multimin_func_fdf;
    Newxz(multimin_func_fdf, 1, gsl_multimin_function_fdf);  // allocate GSL multimin struct BUGBUG: never gets deallocated!

    self->multimin_func = (gsl_multimin_function *)multimin_func_fdf;   // fake it
    multimin_func_fdf->f        = call_f;    // perl call converters
    multimin_func_fdf->df       = call_df;
    multimin_func_fdf->fdf      = call_fdf;
    multimin_func_fdf->n        = dimensions;
    multimin_func_fdf->params = self;     // use params to pass pointer to my_minimizer_struct
    // GSL calls f, df, and fdf with params as an argument, so
    //   now our perl-call-converters have access to my_minimizer_struct.

    self->f_callback_SV = newSVsv(f_callback_SV);    // save perl callback addresses
    self->df_SV         = newSVsv(df_SV);   //    the call converters
    self->fdf_SV        = newSVsv(fdf_SV);  //    get to perl via these
    // put real params here:
    self->params_SV     = newSVsv(params_SV);   // pass GSL param to perl here

    // get the vector (and its name/type)
    gsl_vector * x_vector = _SV_to_void(x_vector_SV, &self->vector_type);
//printf("x_vector_SV(0x%0x)->x_vector(0x%0x, %d, %s)\n", x_vector_SV, x_vector, x_vector, self->vector_type);

    // initialize the minimizer:
    gsl_multimin_fdfminimizer_set (fdf_state, multimin_func_fdf, x_vector, step_size, tol);
    Inline_Stack_Reset;
    Inline_Stack_Push(_new_wrapper("Math::GSL::Multimin::gsl_multimin_fdfminimizer", (void*)fdf_state));
    Inline_Stack_Done;
    Inline_Stack_Return(1);
}

double raw_gsl_multimin_fminimizer_fval (SV * f_state_SV) {
    gsl_multimin_fminimizer * f_state = _SV_to_void(f_state_SV, NULL);
    return f_state->fval;
}

double raw_gsl_multimin_fdfminimizer_f (SV * fdf_state_SV) {
    gsl_multimin_fdfminimizer * fdf_state = _SV_to_void(fdf_state_SV, NULL);
    return fdf_state->f;
}

void raw_gsl_multimin_fdfminimizer_gradient (SV * fdf_state_SV) {
    Inline_Stack_Vars;
    gsl_multimin_fdfminimizer * fdf_state = _SV_to_void(fdf_state_SV, NULL);

    Inline_Stack_Reset;
    XPUSHs(_wrap_raw_vector(fdf_state->gradient));
    Inline_Stack_Done;
    Inline_Stack_Return(1);
}

int raw_gsl_vector_size (SV * vector_SV) {
    gsl_vector * vector = _SV_to_void(vector_SV, NULL);
    return vector->size;
}

// TODO this never gets called, thus we leak memory...
void
Destroy(SV* obj) {
    SV* wrapper = SvIV(obj);
    my_minimizer_struct * minimizer_struct = SvIV(wrapper);

printf("Safefree(minimizer_struct->multimin_func=0x%0x);\n", minimizer_struct->multimin_func);
    Safefree(minimizer_struct->multimin_func);
printf("Safefree(minimizer_struct->vector_type=0x%0x);\n", minimizer_struct->vector_type);
    Safefree(minimizer_struct->vector_type);
printf("gsl_multimin_fminimizer_free(minimizer_struct->multimin_func=0x%0x);\n", minimizer_struct->multimin_func);
    gsl_multimin_fminimizer_free(minimizer_struct->multimin_func);
printf("Safefree(minimizer_struct=0x%0x);\n", minimizer_struct);
    Safefree(minimizer_struct);
}
__END__


=head1 SYNOPSIS

  use Games::Go::AGA::BayRate::GSL::Multimin;

    .  .  .

  # minimizer 'state'
  my $state = my_gsl_multimin_fminimizer_set (
      $gsl_multimin_fminimizer_nmsimplex,    # minimizer type
      # gsl_multimin_function_f structure members:
          \&my_f,     # f       callback function
          2,          # n       number of free variables
          \@params,   # params  function params passed to f
      # end of gsl_multimin_function_f structure members:
      $x->raw,    # starting point vector
      $ss->raw,   # step size
  );

    .  .  .

  gsl_multimin_fminimizer_iterate($state);

  # For full examples, see f_test.pl and fdf_test.pl in the
  #    extra/ subdirectory of this distribution.


=head1 DESCRIPTION

As of this writing, Math::GSL::Multimin is only partially implemented.  No
doubt this is due to the (let's be generous) difficult interface to the
fminimizer and fdf_minimizer functions in the GSL library.

Games::Go::AGA::BayRate::GSL::Multimin uses Inline::C to interface to
fminimizer and fdfminimizer in the GSL library.  Other aspects of GSL
are required, for which you must also have Math::GSL installed.

The following documentation uses names similar to the names found in the
Multimin section of the GSL Reference Manual.  Referring to that manual
will probably make things clearer.

=head1 FUNCITONS

=over

=item my_gsl_multimin_fminimizer_set

Similar to gsl_multimin_fminimizer_set as defined the the GSL library, but
with the members of gsl_multimin_function passed individually instead of as
members of a structure.  gsl_multimin_fminimizer_alloc is called internally
(which is why the B<type> is required).

 my $state = my_gsl_multimin_fminimizer_set (
     $gsl_multimin_fminimizer_nmsimplex2,    # type
     \&my_f,    # gsl_multimin_function . f       callback function
     $count,    # gsl_multimin_function . n       number of free variables
     $params,   # gsl_multimin_function . params  function params passed to f, df, and fdf
     $x->raw,   # gsl vector
     $ss->raw); # step size

B<$x> and B<$ss> are assumed to be Math::GSL::Vector objects here.  Use the B<raw>
method to extract the low-level GSL vectors.

=item my_gsl_multimin_fdfminimizer_set

Similar to gsl_multimin_fdfminimizer_set as defined the the GSL library,
but with the members of gsl_multimin_function_fdf passed individually
instead of as members of a structure.  gsl_multimin_fminimizer_alloc is
called internally (which is why the B<type> is required).

 my $state = my_gsl_multimin_fdfminimizer_set (
     $gsl_multimin_fdfminimizer_vector_bfgs2,    # type
     \&my_f,    # gsl_multimin_function_fdf . f       function
     \&my_df,   # gsl_multimin_function_fdf . df      derivative of f
     \&my_fdf,  # gsl_multimin_function_fdf . fdf     f and df
     $count,    # gsl_multimin_function_fdf . n       number of free variables
     $params,   # gsl_multimin_function_fdf . params  function params passed to f, df, and fdf
     $x->raw,   # gsl vector
     2.0,       # step size
     0.1);      # accuracy required (tol?)

B<$x> is assumed to be a Math::GSL::Vector object here.  Use the B<raw>
method to extract the low-level GSL vector.

=item raw_gsl_multimin_fminimizer_fval($state)

Returns the 'fval' member of the gsl_multimin_fminimizer.

=item raw_gsl_multimin_fdfminimizer_f($state)

Returns the 'f' member of the gsl_multimin_fdfminimizer.

=item raw_gsl_multimin_fdfminimizer_gradient($state)

Returns the 'gradient' member of the gsl_multimin_fdfminimizer.

=item raw_gsl_vector_size($vector->raw);

Returns the 'size' member of a (raw) gsl_vector.

=back

=head1 CALLBACKS

GSL Multimin requires callbacks.  For details, see the GSL Multimin
documentation.  The requirements here are similar, but translated to perl.
Here are the details:

=over

=item my_f($x, $params);

The 'f' callback.  B<$x> is a I<raw> gsl_vector, not a Math::GSL::Vector.
B<$params> is specified in the appropriate
B<my_gsl_multimin_f(df)minimizer_set> call.

=item my_df($x, $params, $df);

The 'df' callback.  B<$x> and B<$df> are I<raw> gsl_vectors, not
Math::GSL::Vectors.  B<$params> is specified in the appropriate
B<my_gsl_multimin_f(df)minimizer_set> call.

=item my_fdf($x, $params, $f, $df);

The 'fdf' callback.  B<$x> and B<$df> are I<raw> gsl_vectors, not
Math::GSL::Vectors.  $f is a reference to a floating point number which
should be altered by this function.  B<$params> is specified in the
appropriate B<my_gsl_multimin_f(df)minimizer_set> call.

This definition of my_fdf is usually appropriate:

  sub my_fdf {
      my ($raw_v, $params, $f, $raw_df) = @_;

      ${$f} = my_f( $raw_v, $params );
      my_df( $raw_v, $params, $raw_df );
  }

=back
