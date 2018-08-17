package FFI::Build::File::Fortran;

use strict;
use warnings;
use 5.008001;
use base qw( FFI::Build::File::C );
use constant default_suffix => '.f';
use constant default_encoding => ':utf8';

# ABSTRACT: Class to track Fortran source file in FFI::Build
our $VERSION = '0.03'; # VERSION


sub accept_suffix
{
  (qr/\.f(90|95)?$/)
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

__END__

=pod

=encoding UTF-8

=head1 NAME

FFI::Build::File::Fortran - Class to track Fortran source file in FFI::Build

=head1 VERSION

version 0.03

=head1 SYNOPSIS

 use FFI::Build::File::Fortran;
 
 my $c = FFI::Build::File::C->new('src/foo.f');

=head1 DESCRIPTION

File class for Fortran source files.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
