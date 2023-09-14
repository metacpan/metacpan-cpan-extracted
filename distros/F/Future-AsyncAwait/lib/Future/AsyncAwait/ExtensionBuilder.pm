#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2022 -- leonerd@leonerd.org.uk

package Future::AsyncAwait::ExtensionBuilder 0.66;

use v5.14;
use warnings;

=head1 NAME

C<Future::AsyncAwait::ExtensionBuilder> - build-time support for extensions to C<Future::AsyncAwait>

=head1 SYNOPSIS

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

require Future::AsyncAwait::ExtensionBuilder_data;

=head1 FUNCTIONS

=cut

=head2 write_AsyncAwait_h

   Future::AsyncAwait::ExtensionBuilder->write_AsyncAwait_h

Writes the F<AsyncAwait.h> file to the current working directory. To cause
the compiler to actually find this file, see L</extra_compiler_flags>.

=cut

sub write_AsyncAwait_h
{
   shift;

   open my $out, ">", "AsyncAwait.h" or
      die "Cannot open AsyncAwait.h for writing - $!\n";

   $out->print( Future::AsyncAwait::ExtensionBuilder_data->ASYNCAWAIT_H );
}

=head2 extra_compiler_flags

   @flags = Future::AsyncAwait::ExtensionBuilder->extra_compiler_flags

Returns a list of extra flags that the build scripts should add to the
compiler invocation. This enables the C compiler to find the
F<AsyncAwait.h> file.

=cut

sub extra_compiler_flags
{
   shift;
   return "-I.";
}

=head2 extend_module_build

   Future::AsyncAwait::ExtensionBuilder->extend_module_build( $build )

A convenient shortcut for performing all the tasks necessary to make a
L<Module::Build>-based distribution use the helper.

=cut

sub extend_module_build
{
   my $self = shift;
   my ( $build ) = @_;

   eval { $self->write_AsyncAwait_h } or do {
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
