package FFI::ExtractSymbols;

use strict;
use warnings;
use File::ShareDir::Dist ();
use base qw( Exporter );

my $config = File::ShareDir::Dist::dist_config('FFI-ExtractSymbols');
our @EXPORT = qw( extract_symbols );

# ABSTRACT: Extract symbol names from a shared object or DLL
our $VERSION = '0.06'; # VERSION


$FFI::ExtractSymbols::mode = '';

if($config->{'posix_nm'})
{
  require FFI::ExtractSymbols::PosixNm;
}
elsif($config->{'openbsd_nm'})
{
  require FFI::ExtractSymbols::OpenBSD;
}
elsif($config->{'ms_windows'})
{
  require FFI::ExtractSymbols::Windows;
}
else
{
  die "no appropriate implementation";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

FFI::ExtractSymbols - Extract symbol names from a shared object or DLL

=head1 VERSION

version 0.06

=head1 SYNOPSIS

 use FFI::ExtractSymbols;
 use FFI::CheckLib;
 
 my $libpath = find_lib( lib => 'foo' );
 
 extract_symbols($libpath,
   code => sub {
     print "found a function called $_[0]\n";
   },
 );

=head1 DESCRIPTION

This module extracts the symbol names from a DLL or shared object.  The
method used depends on the platform.

=head1 FUNCTIONS

=head2 extract_symbols

 extract_symbols($lib,
   export => sub { ... },
   code   => sub { ... },
   data   => sub { ... },
 );

Extracts symbols from the dynamic library (DLL on Windows, shared
library most other places) from the library and calls the given
callbacks. Each callback is called once for each symbol that matches
that type.  Each callback gets two arguments.  The first is the symbol
name in a form that can be passed into L<FFI::Platypus#find_symbol>,
L<FFI::Platypus#function> or L<FFI::Platypus#attach>.  The second is the
exact symbol name as it was extracted from the DLL or shared library.
On some platforms this will be prefixed by an underscore.  Some tools,
such as C<c++filt> will require this version as input.  Example:

 extract_symbols( 'libfoo.so',
   export => sub {
     my($symbol1, $symbol2) = @_;
     my $address   = $ffi->find_symbol($symbol1);
     my $demangled = `c++filt $symbol2`;
   },
 );

=over 4

=item export

All exported symbols, both code and data.

=item code

All symbols in the "text" section of the DLL or shared object.
These are usually functions.

=item data

All symbols in the data section of the DLL or shared object.

=back

=head1 CAVEATS

This module I<may> work on static libraries and object files for some
platforms, but that usage is unsupported and may not be portable.

On windows, depending on the implementation available, this module may
not differentiate between code and data symbols.  In that case the
export and code callbacks will be called for both.

On many platforms extra symbols get lumped into DLLs and shared object
files so you should account for and ignore getting unexpected symbols
that you probably don't care about.

=head1 SEE ALSO

=over 4

=item L<FFI::Platypus>

Write Perl bindings to non-Perl libraries without C or XS

=item L<FFI::CheckLib>

Module for checking for the availability of dynamic libraries.

=item L<Parse::nm>

This module can parse the symbol names out of shared object files on
platforms where C<nm> works on those types of files.

It does not work for Windows DLL files.  It also depends on
L<Regexp::Assemble> which appears to be unmaintained.

=back

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Sanko Robinson (SANKO)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
