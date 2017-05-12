package FFI::Platypus::Lang::CPP::Demangle::XS;

use strict;
use warnings;
use 5.008001;
use Carp qw( croak );
use base qw( Exporter );

our @EXPORT = qw( demangle );

# ABSTRACT: Demangle C++ symbols using the C++ ABI API
our $VERSION = '0.02'; # VERSION


require XSLoader;
XSLoader::load('FFI::Platypus::Lang::CPP::Demangle::XS', $VERSION);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

FFI::Platypus::Lang::CPP::Demangle::XS - Demangle C++ symbols using the C++ ABI API

=head1 VERSION

version 0.02

=head1 SYNOPSIS

 use FFI::Platypus::Lang::CPP::Demangle::XS;
 
 my $demangled = demangle($c_symbol);

=head1 DESCRIPTION

This module provides an interface for demangling C++ symbols.

It is an alternative to C<c++filt> for L<FFI::Platyus::Lang::CPP>.

Perl 5.8.1 or newer is required.  

=head1 FUNCTIONS

=head2 demangle

 my $demangled = demangle($c_symbol);

Demangle the given symbol.  If the input symbol is not a valid
C++ symbol, then it will return C<undef>.  If there is any other
error (memory allocation, for example), it will throw an exception.

=head1 SEE ALSO

=over 4

=item L<FFI::Platypus::Lang::CPP>

Documentation and tools for using C++ and FFI / Platypus

=item L<FFI::Platypus>

Write extensions for Perl without XS or a compiler

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
