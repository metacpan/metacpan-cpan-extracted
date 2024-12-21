#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2022-2024 -- leonerd@leonerd.org.uk

package Future::AsyncAwait::ExtensionBuilder 0.70;

use v5.14;
use warnings;

=head1 NAME

C<Future::AsyncAwait::ExtensionBuilder> - build-time support for extensions to C<Future::AsyncAwait>

=head1 SYNOPSIS

=for highlighter language=perl

In F<Build.PL>:

   use Future::AsyncAwait::ExtensionBuilder;

   my $build = Module::Build->new(
      ...,
      configure_requires => {
         ...
         'Future::AsyncAwait::ExtensionBuilder' => 0,
      }
   );

   Future::AsyncAwait::ExtensionBuilder->extend_module_build( $build );

   ...

=head1 DESCRIPTION

This module provides a build-time helper to assist authors writing XS modules
that provide extensions to L<Future::AsyncAwait>. It prepares a
L<Module::Build>-using distribution to be able to make use of the
C<Future::AsyncAwait> extension API.

=cut

=head1 FUNCTIONS

=cut

=head2 write_AsyncAwait_h

   Future::AsyncAwait::ExtensionBuilder->write_AsyncAwait_h;

This method no longer does anything I<since version 0.67>.

=cut

sub write_AsyncAwait_h
{
}

=head2 extra_compiler_flags

   @flags = Future::AsyncAwait::ExtensionBuilder->extra_compiler_flags;

Returns a list of extra flags that the build scripts should add to the
compiler invocation. This enables the C compiler to find the
F<AsyncAwait.h> file.

=cut

sub extra_compiler_flags
{
   shift;

   require File::ShareDir;
   require File::Spec;
   require Future::AsyncAwait;
   return "-I" . File::Spec->catdir( File::ShareDir::module_dir( "Future::AsyncAwait" ), "include" );
}

=head2 extend_module_build

   Future::AsyncAwait::ExtensionBuilder->extend_module_build( $build );

A convenient shortcut for performing all the tasks necessary to make a
L<Module::Build>-based distribution use the helper.

=cut

sub extend_module_build
{
   my $self = shift;
   my ( $build ) = @_;

   # preserve existing flags
   my @flags = @{ $build->extra_compiler_flags };
   push @flags, $self->extra_compiler_flags;

   $build->extra_compiler_flags( @flags );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
