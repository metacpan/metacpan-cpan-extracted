package FFI;

use strict;
use warnings;
use Carp ();
use FFI::Platypus;
use constant _is_win32 => $^O =~ /^(MSWin32|cygwin|msys2?)$/ && FFI::Platypus->abis->{stdcall};

# ABSTRACT: Perl Foreign Function Interface based on libffi
our $VERSION = '1.15'; # VERSION

our $ffi = FFI::Platypus->new;
$ffi->lib(undef);

my $stdcall_ffi = _is_win32
  ? do {
    my $ffi = FFI::Platypus->new;
    $ffi->lib(undef);
    $ffi->abi('stdcall');
  }
  : $ffi;

our %typemap = qw(
  c   char
  C   uchar
  s   short
  S   ushort
  i   int
  I   uint
  l   long
  L   ulong
  f   float
  d   double
  p   string
  v   void
  o   opaque
);

sub _ffi
{
  if($_[0] =~ s/^([sc])//)
  {
    return $stdcall_ffi if $1 eq 's';
  }
  else
  {
    Carp::croak("first character of signature must be s or c");
  }
  
  $ffi;
}

sub call
{
  my $addr = shift;
  my $signature = shift;
  my $ffi = _ffi($signature);
  my($ret_type, @args_types) = map { $typemap{$_} } split //, $signature;
  $ffi->function($addr => \@args_types => $ret_type)->call(@_);
}

sub callback
{
  my($signature, $sub) = @_;
  my $ffi = _ffi($signature);
  my($ret_type, @args_types) = map { $typemap{$_} } split //, $signature;
  my $type = '(' . join(',', @args_types) . ')->' . $ret_type;
  my $closure = $ffi->closure($sub);
  bless {
    addr    => $ffi->cast($type => 'opaque', $closure),
    sub     => $sub,
    closure => $closure,
  }, 'FFI::Callback';
}

package FFI::Callback;

sub addr { shift->{addr} }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

FFI - Perl Foreign Function Interface based on libffi

=head1 VERSION

version 1.15

=head1 SYNOPSIS

 # for a more portable interface see FFI::Library
 $clib_file = ($^O eq "MSWin32") ? "MSVCRT40.DLL" : "-lc";
 $clib = DynaLoader::dl_findfile($clib_file);
 $strlen = DynaLoader::dl_find_symbol($clib, "strlen");
 $n = FFI::call($strlen, "cIp", $my_string);
 DynaLoader::dl_free_file($clib);

=head1 DESCRIPTION

B<NOTE>: Newer and better maintained FFI modules such as L<FFI::Platypus>
provide more functionality and so it is strongly recommend that you use
one of them for new projects and even consider migrating to one of
them for existing projects.

This module provides a low-level foreign function interface to Perl. It 
allows the calling of any function for which the user can supply an 
address and calling signature. Furthermore, it provides a method of 
encapsulating Perl subroutines as callback functions whose addresses can 
be passed to C code.

=head1 FUNCTIONS

=head2 call

 my $ret = FFI::call($address, $signature, @arguments);

Call the function at the given C<$address> with the given C<$signature>>
(see below) and the given C<@arguments>.

=head2 callback

 my $address = FFI::callback($signature, \&subref);

Creates a c callback that will call a Perl subref.

=head1 FUNCTION SIGNATURES

Function interfaces are defined by I<signatures>. A function's signature 
is a string which specifies the function's return type, argument types 
and calling convention. The first character of the string is the 
function's calling convention. This is one of

    s   The standard calling convention for dynamically linked functions
    c   The calling convention used by C functions

Note that on many platforms, these two calling conventions may be 
identical. On the Windows platform, the C<s> code corresponds to the 
C<stdcall> calling convention, which is used for most dynamic link 
libraries.  The C<c> code corresponds to the C<cdecl> calling 
convention, which is used for C functions, such as those in the C 
runtime library.

The remaining characters of the string are the return type of the 
function, followed by the argument types, in left-to-right order. Valid 
values are based on the codes used for the L<pack> function, namely

    c   A signed char value.
    C   An unsigned char value.
    s   A signed short value.
    S   An unsigned short value.
    i   A signed integer value.
    I   An unsigned integer value.
    l   A signed long value.
    L   An unsigned long value.
    f   A single-precision float.
    d   A double-precision float.
    p   A pointer to a Perl scalar.
    o   A opaque pointer, ie, an address.
    v   No value (only valid as a return type).

Note that all of the above codes refer to "native" format values.

The C<p> code as an argument type simply passes the address of the Perl 
value's memory to the foreign function. It is the caller's 
responsibility to be sure that the called function does not overwrite 
memory outside that allocated by Perl.

The C<p> code as a return type treats the returned value as a 
null-terminated string, and passes it back to Perl as such. There is 
currently no support for functions which return pointers to structures, 
or to other blocks of memory which do not contain strings, nor for 
functions which return memory which the caller must free.

To pass pointers to strings, use the C<p> code. Perl ensures that 
strings are null-terminated for you. To pass pointers to structures, use 
L<pack>. To pass an arbitrary block of memory, use something like the 
following:

    $buf = ' ' x 100;
    # Use $buf via a 'p' parameter as a 100-byte memory block

At the present time, there is no direct support for passing pointers to 
'native' types (like int). To work around this, use C<$buf = pack('i', 
12);> to put an integer into a block of memory, then use the C<p> 
pointer type, and obtain any returned value using C<$n = unpack('i', 
$buf);> In the future, better support may be added (but remember that 
this is intended as a low-level interface!)

=head1 SUPPORT

Please open any support tickets with this project's GitHub repository 
here:

L<https://github.com/Perl5-FFI/FFI/issues>

=head1 SEE ALSO

=over 4

=item L<FFI::Library>

Higher level interface to libraries using this module.

=item L<FFI::CheckLib>

Portable functions for finding libraries.

=item L<FFI::Platypus>

Platypus is another FFI interface based on libffi.  It has a more 
extensive feature set, and libffi has a less restrictive license.

=back

=head1 AUTHOR

Original author: Paul Moore E<lt>gustav@morpheus.demon.co.ukE<gt>

Current maintainer: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Anatoly Vorobey E<lt>avorobey@pobox.comE<gt>

Gaal Yahas E<lt>gaal@forum2.orgE<gt>

Mitchell Charity E<lt>mcharity@vendian.orgE<gt>

Reini Urban E<lt>E<lt>RURBAN@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016-2018 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
