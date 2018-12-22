package FFI::Build::File::CXX;

use strict;
use warnings;
use 5.008001;
use base qw( FFI::Build::File::C );
use constant default_suffix => '.cxx';
use constant default_encoding => ':utf8';

# ABSTRACT: Class to track C source file in FFI::Build
our $VERSION = '0.11'; # VERSION


sub accept_suffix
{
  (qr/\.c(xx|pp)$/)
}

sub cc
{
  my($self) = @_;
  $self->platform->cxx;
}

sub ld
{
  my($self) = @_;
  $self->platform->cxx;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

FFI::Build::File::CXX - Class to track C source file in FFI::Build

=head1 VERSION

version 0.11

=head1 SYNOPSIS

 use FFI::Build::File::CXX;
 
 my $c = FFI::Build::File::CXX->new('src/foo.cxx');

=head1 DESCRIPTION

File class for C++ source files.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
