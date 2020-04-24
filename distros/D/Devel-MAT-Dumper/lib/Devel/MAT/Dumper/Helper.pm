#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2019 -- leonerd@leonerd.org.uk

package Devel::MAT::Dumper::Helper;

use strict;
use warnings;

our $VERSION = '0.42';

=head1 NAME

C<Devel::MAT::Dumper::Helper> - give XS modules extensions for memory dumping

=head1 SYNOPSIS

In F<Build.PL>

   if( eval { require Devel::MAT::Dumper::Helper } ) {
      Devel::MAT::Dumper::Helper->extend_module_build( $build );
   }

In your module's XS source:

   #ifdef HAVE_DMD_HELPER
   #  include "DMD_helper.h"
   #endif

   ...

   #ifdef HAVE_DMD_HELPER
   static int dumpstruct(pTHX_ const SV *sv)
   {
     int ret = 0;

     ret += DMD_ANNOTATE_SV(sv, another_sv,
       "the description of this field");
     ...

     return ret;
   }

   static int dumpmagic(pTHX_ const SV *sv, MAGIC *mg)
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

=cut

=head2 write_DMD_helper_h

   Devel::MAT::Dumper::Helper->write_DMD_helper_h

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

   @flags = Devel::MAT::Dumper::Helper->extra_compiler_flags

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
   return "-DHAVE_DMD_HELPER", "-I.";
}

=head2 extend_module_build

   Devel::MAT::Dumper::Helper->extend_module_build( $build )

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

#endif
