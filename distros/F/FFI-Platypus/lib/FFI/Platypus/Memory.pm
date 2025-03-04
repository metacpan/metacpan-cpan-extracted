package FFI::Platypus::Memory;

use strict;
use warnings;
use 5.008004;
use FFI::Platypus;
use Exporter qw( import );

# ABSTRACT: Memory functions for FFI
our $VERSION = '2.10'; # VERSION


our @EXPORT = qw( malloc free calloc realloc memcpy memset strdup strndup strcpy );

my $ffi = FFI::Platypus->new( api => 2 );
$ffi->lib(undef);
$ffi->bundle;
sub _ffi { $ffi }

$ffi->attach(malloc  => ['size_t']                     => 'opaque' => '$');
$ffi->attach(free    => ['opaque']                     => 'void'   => '$');
$ffi->attach(calloc  => ['size_t', 'size_t']           => 'opaque' => '$$');
$ffi->attach(realloc => ['opaque', 'size_t']           => 'opaque' => '$$');
$ffi->attach(memcpy  => ['opaque', 'opaque', 'size_t'] => 'opaque' => '$$$');
$ffi->attach(memset  => ['opaque', 'int', 'size_t']    => 'opaque' => '$$$');
$ffi->attach(strcpy  => ['opaque', 'string']           => 'opaque' => '$$');

my $_strdup_impl = 'not-loaded';
sub _strdup_impl { $_strdup_impl }

eval {
  die "do not use c impl" if ($ENV{FFI_PLATYPUS_MEMORY_STRDUP_IMPL}||'libc') eq 'ffi';
  $ffi->attach(strdup  => ['string'] => 'opaque' => '$');
  $_strdup_impl = 'libc';
};
if($@ && $^O eq 'MSWin32')
{
  eval {
    die "do not use c impl" if ($ENV{FFI_PLATYPUS_MEMORY_STRDUP_IMPL}||'libc') eq 'ffi';
    $ffi->attach([ _strdup => 'strdup' ] => ['string'] => 'opaque' => '$');
    $_strdup_impl = 'libc';
  };
}
if($@)
{
  warn "using bundled strdup";
  $_strdup_impl = 'ffi';
  $ffi->attach([ ffi_platypus_memory__strdup => 'strdup' ] => ['string'] => 'opaque' => '$');
}

my $_strndup_impl = 'not-loaded';
sub _strndup_impl { $_strndup_impl }

eval {
  die "do not use c impl" if ($ENV{FFI_PLATYPUS_MEMORY_STRDUP_IMPL}||'libc') eq 'ffi';
  $ffi->attach(strndup  => ['string','size_t'] => 'opaque' => '$$');
  $_strndup_impl = 'libc';
};
if($@)
{
  $_strndup_impl = 'ffi';
  $ffi->attach([ ffi_platypus_memory__strndup => 'strndup' ] => ['string','size_t'] => 'opaque' => '$$');
}

# used internally by FFI::Platypus::Type::WideString, may go away.
eval { $ffi->attach( [ wcslen  => '_wcslen' ]  => [ 'opaque'           ] => 'size_t' => '$' ) };
eval { $ffi->attach( [ wcsnlen => '_wcsnlen' ] => [ 'string', 'size_t' ] => 'size_t' => '$$' ) };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

FFI::Platypus::Memory - Memory functions for FFI

=head1 VERSION

version 2.10

=head1 SYNOPSIS

 use FFI::Platypus::Memory;
 
 # allocate 64 bytes of memory using the
 # libc malloc function.
 my $pointer = malloc 64;
 
 # use that memory wisely
 ...
 
 # free the memory when you are done.
 free $pointer;

=head1 DESCRIPTION

This module provides an interface to common memory functions provided by
the standard C library.  They may be useful when constructing interfaces
to C libraries with FFI.  It works mostly with the C<opaque> type and it
is worth reviewing the section on opaque pointers in L<FFI::Platypus::Type>.

Allocating memory and forgetting to free it is a common source of memory
leaks in C and when using this module.  Very recent Perls have a C<defer>
keyword that lets you automatically call functions like C<free> when a
block ends.  This can be especially handy when you have multiple code
paths or possible exceptions to keep track of.

 use feature 'defer';
 use FFI::Platypus::Memory qw( malloc free );

 sub run {
   my $ptr = malloc 66;
   defer { free $ptr };

   my $data = do_something($ptr);

   # do not need to remember to place free $ptr here, as it will
   # run through defer.

   return $data;
 }

If you are not lucky enough to have the C<defer> feature in your version
of Perl you may be able to use L<Feature::Compat::Defer>, which will use
the feature if available, and provides its own mostly compatible version
if not.

=head1 FUNCTIONS

=head2 calloc

 my $pointer = calloc $count, $size;

The C<calloc> function contiguously allocates enough space for I<$count>
objects that are I<$size> bytes of memory each.

=head2 free

 free $pointer;

The C<free> function frees the memory allocated by C<malloc>, C<calloc>,
C<realloc> or C<strdup>.  It is important to only free memory that you
yourself have allocated.  A good way to crash your program is to try and
free a pointer that some C library has returned to you.

=head2 malloc

 my $pointer = malloc $size;

The C<malloc> function allocates I<$size> bytes of memory.

=head2 memcpy

 memcpy $dst_pointer, $src_pointer, $size;

The C<memcpy> function copies I<$size> bytes from I<$src_pointer> to
I<$dst_pointer>.  It also returns I<$dst_pointer>.

=head2 memset

 memset $buffer, $value, $length;

The C<memset> function writes I<$length> bytes of I<$value> to the address
specified by I<$buffer>.

=head2 realloc

 my $new_pointer = realloc $old_pointer, $size;

The C<realloc> function reallocates enough memory to fit I<$size> bytes.
It copies the existing data and frees I<$old_pointer>.

If you pass C<undef> in as I<$old_pointer>, then it behaves exactly like
C<malloc>:

 my $pointer = realloc undef, 64; # same as malloc 64

=head2 strcpy

 strcpy $opaque, $string;

Copies the string to the memory location pointed to by C<$opaque>.

=head2 strdup

 my $pointer = strdup $string;

The C<strdup> function allocates enough memory to contain I<$string> and
then copies it to that newly allocated memory.  This version of
C<strdup> returns an opaque pointer type, not a string type.  This may
seem a little strange, but returning a string type would not be very
useful in Perl.

=head2 strndup

 my $pointer = strndup $string, $max;

The same as C<strdup> above, except at most C<$max> characters will be
copied in the new string.

=head1 SEE ALSO

=over 4

=item L<FFI::Platypus>

Main Platypus documentation.

=back

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Bakkiaraj Murugesan (bakkiaraj)

Dylan Cali (calid)

pipcet

Zaki Mughal (zmughal)

Fitz Elliott (felliott)

Vickenty Fesunov (vyf)

Gregor Herrmann (gregoa)

Shlomi Fish (shlomif)

Damyan Ivanov

Ilya Pavlov (Ilya33)

Petr Písař (ppisar)

Mohammad S Anwar (MANWAR)

Håkon Hægland (hakonhagland, HAKONH)

Meredith (merrilymeredith, MHOWARD)

Diab Jerius (DJERIUS)

Eric Brine (IKEGAMI)

szTheory

José Joaquín Atria (JJATRIA)

Pete Houston (openstrike, HOUSTON)

Lukas Mai (MAUKE)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015-2022 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
