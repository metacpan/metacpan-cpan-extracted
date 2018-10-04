package FFI::Build::File::Fortran;

use strict;
use warnings;
use 5.008001;
use base qw( FFI::Build::File::C );
use constant default_suffix => '.f';
use constant default_encoding => ':utf8';

our $VERSION = '0.09';

=head1 NAME

FFI::Build::File::Fortran - Class to track Fortran source file in FFI::Build
Fortran

=head1 SYNOPSIS

 use FFI::Build::File::Fortran;
 
 my $c = FFI::Build::File::C->new('src/foo.f');

=head1 DESCRIPTION

File class for Fortran source files.

=cut

sub accept_suffix
{
  (qr/\.f(90|95|or)?$/)
}

sub cc
{
  my($self) = @_;
  $self->platform->for;
}

sub ld
{
  my($self) = @_;
  $self->platform->for;
}

1;

=head1 SEE ALSO

=over 4

=item L<FFI::Platypus>

The Core Platypus documentation.

=item L<FFI::Build>

Tool to build bundled libraries with your Perl dist.

=item L<Module::Build::FFI::Fortran>

Bundle Fortran with your FFI / Perl extension.

=back

=head1 AUTHOR

Graham Ollis E<lt>plicease@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Graham Ollis

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
