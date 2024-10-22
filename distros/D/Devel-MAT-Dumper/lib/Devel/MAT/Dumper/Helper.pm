#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2019-2024 -- leonerd@leonerd.org.uk

package Devel::MAT::Dumper::Helper;

use v5.10;
use strict;
use warnings;

our $VERSION = '0.50';

=head1 NAME

C<Devel::MAT::Dumper::Helper> - give XS modules extensions for memory dumping

=head1 SYNOPSIS

=for highlighter language=perl

In F<Build.PL>

   if( eval { require Devel::MAT::Dumper::Helper } ) {
      Devel::MAT::Dumper::Helper->extend_module_build( $build );
   }

In your module's XS source:

=for highlighter language=c

   #ifdef HAVE_DMD_HELPER
   #  define WANT_DMD_API_044
   #  include "DMD_helper.h"
   #endif

   ...

   #ifdef HAVE_DMD_HELPER
   static int dumpstruct(pTHX_ DMDContext *ctx, const SV *sv)
   {
     int ret = 0;

     ret += DMD_ANNOTATE_SV(sv, another_sv,
       "the description of this field");
     ...

     return ret;
   }

   static int dumpmagic(pTHX_ DMDContext *ctx, const SV *sv, MAGIC *mg)
   {
     int ret = 0;

     ret += DMD_ANNOTATE_SV(sv, another_sv,
       "the description of this field");
     ...

     return ret;
   }
   #endif

   ...

   BOOT:
   #ifdef HAVE_DMD_HELPER
     DMD_SET_PACKAGE_HELPER("My::Package", dumpstruct);
     DMD_SET_MAGIC_HELPER(&vtbl, dumpmagic);
   #endif

=head1 DESCRIPTION

This module provides a build-time helper to assist in writing XS modules that
can provide extra information to a L<Devel::MAT> heap dump file when dumping
data structures relating to that module.

Following the example in the L</SYNOPSIS> section above, the C<dumpstruct>
function is called whenever L<Devel::MAT::Dumper> finds an SV blessed into the
given package, and the C<dumpmagic> function is called whenever
L<Devel::MAT::Dumper> finds an SV with extension magic matching the given
magic virtual table pointer. These functions may then inspect the module's
state from the SV or MAGIC pointers, and invoke the C<DMD_ANNOTATE_SV> macro
to provide extra annotations into the heap dump file about how this SV is
related to another one.

The C<WANT_DMD_API_044> macro is required before C<#include>ing the file, so
as to enable the API structure described here. Without that, an earlier
version of the module is provided instead, which will eventually be removed in
some later version.

Under this code structure, a module will cleanly build, install and run just
fine if L<Devel::MAT::Dumper::Helper> is not available at build time, so it is
not necessary to list that as a C<configure_requires> or C<build_requires>
requirement.

Additionally, the way the inserted code is structured does not cause the XS
module to load C<Devel::MAT::Dumper> itself, so there is no runtime dependency
either, even if the support was made available. The newly inserted code is
only invoked if both C<Devel::MAT::Dumper> and this XS module are actually
loaded.

Note that this entire mechanism is currently experimental.

=cut

my $DMD_helper_h = do {
   local $/;
   readline DATA;
};

=head1 FUNCTIONS

=for highlighter language=perl

=cut

=head2 write_DMD_helper_h

   Devel::MAT::Dumper::Helper->write_DMD_helper_h;

Writes the L<DMD_helper.h> file to the current working directory. To cause the
compiler to actually find this file, see L<extra_compiler_flags>.

=cut

sub write_DMD_helper_h
{
   shift;

   open my $out, ">", "DMD_helper.h" or
      die "Cannot open DMD_helper.h for writing - $!\n";

   $out->print( $DMD_helper_h );
}

=head2 extra_compiler_flags

   @flags = Devel::MAT::Dumper::Helper->extra_compiler_flags;

Returns a list of extra flags that the build scripts should add to the
compiler invocation. This enables the C compiler to find the F<DMD_helper.h>
file, and also defines a symbol C<HAVE_DMD_HELPER> which the XS code can then
use in C<#ifdef> guards:

   #ifdef HAVE_DMD_HELPER
   ...
   #endif

=cut

sub extra_compiler_flags
{
   shift;
   return "-DHAVE_DMD_HELPER",
      "-I.";
}

=head2 extend_module_build

   Devel::MAT::Dumper::Helper->extend_module_build( $build );

A convenient shortcut for performing all the tasks necessary to make a
L<Module::Build>-based distribution use the helper.

=cut

sub extend_module_build
{
   my $self = shift;
   my ( $build ) = @_;

   eval { $self->write_DMD_helper_h } or do {
      warn $@;
      return;
   };

   # preserve existing flags
   my @flags = @{ $build->extra_compiler_flags };
   push @flags, $self->extra_compiler_flags;

   $build->extra_compiler_flags( @flags );
}

=head1 XS MACROS

=for highlighter language=c

The header file provides the following macros, which may be used by the XS
module.

=head2 DMD_SET_PACKAGE_HELPER

   typedef int DMD_Helper(pTHX_ DMDContext *ctx, const SV *sv);

   DMD_SET_PACKAGE_HELPER(char *packagename, DMD_Helper *helper);

This macro should be called from the C<BOOT> section of the XS module to
associate a helper function with a named package. Whenever an instance of an
object blessed into that package is encountered by the dumper, the helper
function will be called to provide extra information about it.

When invoked, the helper function is passed a pointer to the blessed SV
directly - remember this will be the underlying object storage and not the
C<RV> that the Perl code uses to refer to it. It should return an integer that
is the sum total of the return values of all the calls to C<DMD_ANNOTATE_SV>
that it made, or 0 if it did not make any.

The I<ctx> pointer to the helper function points at an opaque structure
internal to the C<Devel::MAT::Dumper> module. Helper functions are not
expected to interact with it, except to pass it on any C<DMD_DUMP_STRUCT>
calls it may make.

=head2 DMD_SET_MAGIC_HELPER

   typedef int DMD_MagicHelper(pTHX_ DMDContext *ctx, const SV *sv, MAGIC *mg);

   DMD_SET_MAGIC_HELPER(MGVTBL *vtbl, DMD_MagicHelper *helper);

This macro should be called from the C<BOOT> section of the XS module to
associate a helper function with a given magic virtual method table. Whenever
an SV with that kind of magic is encountered by the dumper, the helper
function will be called to provide extra information about it.

When invoked, the helper function is passed a pointer to the magical SV as
well as the specific C<MAGIC> instance responsible for this call. It should
return an integer that is the sum total of the return values of all the calls
to C<DMD_ANNOTATE_SV> that it made, or 0 if it did not make any.

The I<ctx> pointer to the helper function points at an opaque structure
internal to the C<Devel::MAT::Dumper> module. Helper functions are not
expected to interact with it, except to pass it on any C<DMD_DUMP_STRUCT>
calls it may make.

=head2 DMD_ADD_ROOT

   DMD_ADD_ROOT(SV *sv, const char *name);

This macro should be called from the C<BOOT> section of the XS module to add
another root SV pointer to be added to the root SVs table. This is useful for
annotating static SV pointers or other storage that can refer to SVs or memory
structures within the module, but which would not be discovered by a normal
heap walk.

The I<name> argument is also used as the description string within the
C<Devel::MAT> UI. It should begin with either a C<+> or C<-> character to
annotate that the root contains a strong or weak reference, respectively.

=head2 DMD_ANNOTATE_SV

   DMD_ANNOTATE_SV(const SV *referrer, const SV *referrant, const char *label);

This macro should be called by a helper function, in order to provide extra
information about the SV it has encountered. The macro notes that a pointer
exists from the SV given by I<referrer>, pointing at the SV given by
I<referrant>, described by the given string label.

Each call to this macro returns an integer, which the helper function must
accumulate the total of, and return that number to the caller.

Not that it is not necessary that either the referrer nor the referrant
actually are the SV that the helper function encountered. Arbitrary
annotations between SVs are permitted. Additionally, it is permitted that
the SV addresses do not in fact point at Perl SVs, but instead point to
arbitarary data structures, which should be written about using
C<DMD_DUMP_STRUCT>.

=head2 DMD_DUMP_STRUCT

   typedef struct {
     const char *name;
     enum {
       DMD_FIELD_PTR,
       DMD_FIELD_BOOL,
       DMD_FIELD_U8,
       DMD_FIELD_U32,
       DMD_FIELD_UINT,
     } type;

     void *ptr;  /* for type=PTR */
     bool  b;    /* for type=BOOL */
     long  n;    /* for the remaining numerical types */
   } DMDNamedField;

   DMD_DUMP_STRUCT(DMDContext *ctx, const char *name, void *addr, size_t size,
      size_t nfields, const DMDNamedField fields[]);

This macro should be called by a helper function, in order to provide extra
information about a memory structure that is not a Perl SV. By using this
macro, the module can write information into the dumpfile about the memory
structure types and values that it operates on, allowing the C<Devel::MAT>
tooling to operate on it - such as by following pointers and finding or
identifying the contents.

The code invoked by this macro at runtime actually does B<two> separate tasks,
which are closely related. The first time a call is made for any particular
string value in I<name>, the function will write metadata information into the
dumpfile which gives the name and type of each of the fields. Every call,
including this first one, will write the values of the fields associated with
a single instance of the structure, by reusing the information provided to the
first call.

The I<ctx> argument must be the value given to the helper function. I<addr>
gives the pointer address of the structure itself. I<size> should give its
total size in bytes (often C<sizeof(*ptr)> is sufficient here).

The I<name>, I<nfields>, and I<fields> parameters between them are used both
by the initial metadata call, and for every structure instance. I<name> gives
a unique name to this type of structure - it should be composed of the base
name of the XS module, and a local name within the module, separated by C</>.
I<nfields> gives the number of individual field instances given in the
I<fields> array, which itself provides a label name, a type, and an actual
value.

The first two fields of the C<DMDNamedField> structure give its name and type,
and one subsequent field should be set to give the value for it. Which field
to use depends on the type.

Note that it is very important, once a structure name has been seen the first
time, that every subsequent call for the same must have exactly the same count
of fields, and the types of each of them. The values of the fields, as well as
the size of the structure overall, are recorded for every call, but the typing
information is stored only once on that first call. It is best to ensure that
the module source contains only a single instance of this macro for a given
structure name, thus ensuring the type information will always be consistent.

=head1 HANDLING C-LEVEL STRUCTURES

For example, given a C struct definition such as:

  struct MyData {
    SV *buf;
    int state;

    AV *more_stuff;
  };

A call to provide this to the dumpfile could look like:

  struct MyData *dat = ...;

  DMD_DUMP_STRUCT(ctx, "Module::Name/MyData", dat, sizeof(struct MyData),
    3, ((const DMDNamedField []){
      {"the buf SV",        DMD_FIELD_PTR,  .ptr = dat->buf},
      {"the state",         DMD_FIELD_UINT, .n   = dat->state},
      {"the more_stuff AV", DMD_FIELD_PTR,  .ptr = dat->more_stuff},
    })
  );

Conventionally, names of unique fields all begin C<"the ...">. Fields that
point to other Perl SVs should explain what kind of SV they point to, so any
discrepencies can be observed in the tooling later on.

A call to this macro alone is likely not enough to fully link the information
in the dumpfile, however. It is unlikely that any pointer value that the
dumper itself will encounter would point to this data structure - if so, Perl
would not know how to deal with it. It's likely that the module would use some
technique such as storing a pointer in the UV field of a blessed SCALAR SV, as
a way to retain it. In that typical example, a helper function should be
attached to the package name that SV would be blessed into. When the dumper
encounters that blessed SV it will invoke the helper function, which can then
call C<DMD_DUMP_STRUCT> and also use C<DMD_ANNOTATE_SV> to provide a linkage
between the blessed SV containing the UV value, and this structure.

  static int dumppackage_mydata(pTHX_ DMDContext *ctx, const SV *sv)
  {
    int ret = 0;

    struct MyData *dat = NUM2PTR(struct MyData *, SvUV((SV *)sv));
    DMD_DUMP_STRUCT(...);

    ret += DMD_ANNOTATE_SV(sv, (SV *)dat, "the MyData structure");

    return ret;
  }

  BOOT:

There is no ordering requirement between these two - the annotation linking
the pointers can be made before, or after, the structure itself has been
written. In fact, there are no ordering constraints at all; feel free to write
the data structures and annotations in whatever order is most natural to the
dumper code,

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;

__DATA__
#ifndef __DEVEL_MAT_DUMPER_HELPER_H__
#define __DEVEL_MAT_DUMPER_HELPER_H__

#define DMD_ANNOTATE_SV(targ, val, name)  S_DMD_AnnotateSv(aTHX_ targ, val, name)
static int S_DMD_AnnotateSv(pTHX_ const SV *targ, const SV *val, const char *name)
{
  dSP;
  if(!targ || !val)
    return 0;

  mXPUSHi(0x87); /* TODO PMAT_SVxSVSVnote */
  XPUSHs((SV *)targ);
  XPUSHs((SV *)val);
  mXPUSHp(name, strlen(name));
  PUTBACK;
  return 4;
}

#ifdef WANT_DMD_API_044
typedef struct DMDContext DMDContext;

typedef int DMD_Helper(pTHX_ DMDContext *ctx, const SV *sv);

#define DMD_SET_PACKAGE_HELPER(package, helper) S_DMD_SetPackageHelper(aTHX_ package, helper)
static void S_DMD_SetPackageHelper(pTHX_ char *package, DMD_Helper *helper)
{
  HV *helper_per_package;
  SV **svp;
  if((svp = hv_fetchs(PL_modglobal, "Devel::MAT::Dumper/%helper_per_package", 0)))
    helper_per_package = (HV *)SvRV(*svp);
  else {
    helper_per_package = newHV();
    hv_stores(PL_modglobal, "Devel::MAT::Dumper/%helper_per_package", newRV_noinc((SV *)helper_per_package));
  }

  hv_store(helper_per_package, package, strlen(package), newSVuv(PTR2UV(helper)), 0);
}

typedef int DMD_MagicHelper(pTHX_ DMDContext *ctx, const SV *sv, MAGIC *mg);

#define DMD_SET_MAGIC_HELPER(vtbl, helper) S_DMD_SetMagicHelper(aTHX_ vtbl, helper)
static void S_DMD_SetMagicHelper(pTHX_ MGVTBL *vtbl, DMD_MagicHelper *helper)
{
  HV *helper_per_magic;
  SV **svp;
  if((svp = hv_fetchs(PL_modglobal, "Devel::MAT::Dumper/%helper_per_magic", 0)))
    helper_per_magic = (HV *)SvRV(*svp);
  else {
    helper_per_magic = newHV();
    hv_stores(PL_modglobal, "Devel::MAT::Dumper/%helper_per_magic", newRV_noinc((SV *)helper_per_magic));
  }

  SV *keysv = newSViv((IV)vtbl);
  hv_store_ent(helper_per_magic, keysv, newSVuv(PTR2UV(helper)), 0);
  SvREFCNT_dec(keysv);
}

typedef struct
{
   const char *name;
   enum {
      DMD_FIELD_PTR,
      DMD_FIELD_BOOL,
      DMD_FIELD_U8,
      DMD_FIELD_U32,
      DMD_FIELD_UINT,
   }           type;
   struct {
      void       *ptr;
      bool        b;
      long        n;
   };
} DMDNamedField;

#define DMD_DUMP_STRUCT(ctx, name, addr, size, nfields, fields)  \
    S_DMD_DumpStruct(aTHX_ ctx, name, addr, size, nfields, fields)
static void S_DMD_DumpStruct(pTHX_ DMDContext *ctx, const char *name, void *addr, size_t size,
   size_t nfields, const DMDNamedField fields[])
{
  static void (*func)(pTHX_ DMDContext *ctx, const char *, void *, size_t,
     size_t, const DMDNamedField []);
  if(!func) {
    SV **svp = hv_fetchs(PL_modglobal, "Devel::MAT::Dumper/writestruct()", 0);
    if(svp)
      func = INT2PTR(void (*)(pTHX_ DMDContext *ctx, const char *, void *, size_t,
            size_t, const DMDNamedField[]), SvUV(*svp));
    else
      func = (void *)(-1);
  }

  if(func != (void *)(-1))
    (*func)(aTHX_ ctx, name, addr, size, nfields, fields);
}

#else
typedef int DMD_Helper(pTHX_ const SV *sv);

#define DMD_SET_PACKAGE_HELPER(package, helper) S_DMD_SetPackageHelper(aTHX_ package, helper)
static void S_DMD_SetPackageHelper(pTHX_ char *package, DMD_Helper *helper)
{
  HV *helper_per_package = get_hv("Devel::MAT::Dumper::HELPER_PER_PACKAGE", GV_ADD);

  hv_store(helper_per_package, package, strlen(package), newSVuv(PTR2UV(helper)), 0);
}

typedef int DMD_MagicHelper(pTHX_ const SV *sv, MAGIC *mg);

#define DMD_SET_MAGIC_HELPER(vtbl, helper) S_DMD_SetMagicHelper(aTHX_ vtbl, helper)
static void S_DMD_SetMagicHelper(pTHX_ MGVTBL *vtbl, DMD_MagicHelper *helper)
{
  HV *helper_per_magic = get_hv("Devel::MAT::Dumper::HELPER_PER_MAGIC", GV_ADD);
  SV *keysv = newSViv((IV)vtbl);

  hv_store_ent(helper_per_magic, keysv, newSVuv(PTR2UV(helper)), 0);

  SvREFCNT_dec(keysv);
}
#endif

#define DMD_IS_ACTIVE()  S_DMD_is_active(aTHX)
static bool S_DMD_is_active(pTHX)
{
#ifdef MULTIPLICITY
  return !!get_cv("Devel::MAT::Dumper::dump", 0);
#else
  static bool active;
  static bool cached = FALSE;
  if(!cached) {
    active = !!get_cv("Devel::MAT::Dumper::dump", 0);
    cached = TRUE;
  }
  return active;
#endif
}

#define DMD_ADD_ROOT(sv, name) S_DMD_add_root(aTHX_ sv, name)
static void S_DMD_add_root(pTHX_ SV *sv, const char *name)
{
  AV *moreroots = get_av("Devel::MAT::Dumper::MORE_ROOTS", GV_ADD);

  av_push(moreroots, newSVpvn(name, strlen(name)));
  av_push(moreroots, sv);
}

#endif
