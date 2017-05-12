package FFI::Util;

use strict;
use warnings;
use constant;
use 5.008001;
use Config;
use FFI::Platypus;
use FFI::Platypus::Buffer ();
use Scalar::Util qw( refaddr );
use Exporter::Tidy
  deref => do {
    our @types = qw( ptr str int uint short ushort char uchar float double int64 uint64 long ulong );
    [map { ("deref_$_\_get","deref_$_\_set") } (@types, qw( size_t time_t dev_t gid_t uid_t ))];
  },
  buffer => [qw( scalar_to_buffer buffer_to_scalar )],
  types => [qw( _size_t _time_t _dev_t _gid_t _uid_t )],
  locate_module_share_lib => [qw( locate_module_share_lib )],
;

# ABSTRACT: Some useful pointer utilities when writing FFI modules (Deprecated)
our $VERSION = '0.16'; # VERSION



sub locate_module_share_lib (;$$)
{
  require FFI::Platypus::ConfigData;
  my($module, $modlibname) = @_;
  ($module, $modlibname) = caller() unless defined $modlibname;
  my @modparts = split(/::/,$module);
  my $modfname = $modparts[-1];
  my $modpname = join('/',@modparts);
  my $c = @modparts;
  $modlibname =~ s,[\\/][^\\/]+$,, while $c--;    # Q&D basename
  foreach my $dlext (@{ FFI::Platypus::ConfigData->config('config_dlext') })
  {
    my $file = "$modlibname/auto/$modpname/$modfname.$dlext";
    unless(-e $file)
    {
      $modlibname =~ s,[\\/][^\\/]+$,,;
      $file = "$modlibname/arch/auto/$modpname/$modfname.$dlext";
    }
    return $file if -e $file;
  }
  ();
};

our $ffi = FFI::Platypus->new;
$ffi->package;
$ffi->attach( [lookup_type => '_lookup_type'] => ['string'] => 'string');

# nicked this from FFI/Raw.pm
sub _ffi_void ()     { ord 'v' }
sub _ffi_int ()      { ord 'i' }
sub _ffi_uint ()     { ord 'I' }
sub _ffi_short ()    { ord 'z' }
sub _ffi_ushort ()   { ord 'Z' }
sub _ffi_long ()     { ord 'l' }
sub _ffi_ulong ()    { ord 'L' }
sub _ffi_int64 ()    { ord 'x' }
sub _ffi_uint64 ()   { ord 'X' }
sub _ffi_char ()     { ord 'c' }
sub _ffi_uchar ()    { ord 'C' }
sub _ffi_float ()    { ord 'f' }
sub _ffi_double ()   { ord 'd' }
sub _ffi_str ()      { ord 's' }
sub _ffi_ptr ()      { ord 'p' }

foreach my $type (qw( size_t time_t dev_t gid_t uid_t ))
{
  my $real_type = _lookup_type($type);
  if($real_type)
  {
    constant->import("_$type" => eval "_ffi_$real_type\()");
  }
}

$ffi->type( void             => 'raw_void'   );
$ffi->type( string           => 'raw_str'    );
$ffi->type( int              => 'raw_int'    );
$ffi->type( 'unsigned int'   => 'raw_uint'   );
$ffi->type( short            => 'raw_short'  );
$ffi->type( 'unsigned short' => 'raw_ushort' );
$ffi->type( long             => 'raw_long'   );
$ffi->type( 'unsigned long'  => 'raw_ulong'  );
$ffi->type( 'uint64'         => 'raw_uint64' );
$ffi->type( 'sint64'         => 'raw_int64'  );
$ffi->type( 'signed char'    => 'raw_char'   );
$ffi->type( 'unsigned char'  => 'raw_uchar'  );
$ffi->type( 'float'          => 'raw_float'  );
$ffi->type( 'double'         => 'raw_double' );

$ffi->custom_type(raw_ptr => {
  perl_to_native => sub { ref($_[0]) ? ${$_[0]} : $_[0] },
  native_to_perl => sub { $_[0] },
});

for (qw( ptr str int uint short ushort long ulong char uchar float double int64 uint64 ))
{
  $ffi->attach( "deref_${_}_get" => ['raw_ptr']          => "raw_$_" => '$'  );
  $ffi->attach( "deref_${_}_set" => ['raw_ptr',"raw_$_"] => 'void'   => '$$' );
}

foreach my $type (our @types)
{
  my $code_type = eval qq{ _ffi_$type };
  foreach my $otype (qw( size_t time_t dev_t gid_t uid_t ))
  {
    if((_lookup_type($otype)||'') eq $type)
    {
      no strict 'refs';
      *{"deref_$otype\_get"} = \&{"deref_$type\_get"};
      *{"deref_$otype\_set"} = \&{"deref_$type\_set"};
    }
  }
}


use constant _incantation => 
  $^O eq 'MSWin32' && $Config{archname} =~ /MSWin32-x64/
  ? 'Q'
  : 'L!';


sub scalar_to_buffer ($)
{
  (unpack(_incantation, pack 'P', $_[0]), do { use bytes; length $_[0] });
}


sub buffer_to_scalar ($$)
{
  unpack 'P'.$_[1], pack _incantation, defined $_[0] ? $_[0] : 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

FFI::Util - Some useful pointer utilities when writing FFI modules (Deprecated)

=head1 VERSION

version 0.16

=head1 SYNOPSIS

 use FFI::Util;

=head1 DESCRIPTION

B<Note>: This module has largely been obsoleted by L<FFI::Platypus>, which
I recommend that you use instead of this module.  This module may be removed
from CPAN at a future date, but not before 31 January 2017.

This module provides some useful memory manipulation that is either difficult
or impossible in pure Perl.  It was originally intended to be used by
L<Archive::Libarchive::FFI>, but it may be useful in other projects.

=head1 FUNCTIONS

=head2 locate_module_share_lib

 my $path = locate_module_share_lib();
 my $path = locate_module_share_lib($module_name, $module_filename);

Returns the path to the shared library for the current module, or the
module specified by C<$module_name> (example: Foo::Bar) 
C<$module_filename>(example /full/path/Foo/Bar.pm).

=head2 scalar_to_buffer

 my($ptr, $size) = scalar_to_buffer $scalar;

Given a scalar string value, return a pointer to where the data is stored
and the size of the scalar in bytes.

=head2 buffer_to_scalar

 my $scalar = buffer_to_scalar($ptr, $size);

Given a pointer to a memory location and a size, construct a new scalar
with the same content and size.

=head2 deref_ptr_get

 my $ptr2 = deref_ptr_get($ptr1);

equivalent to

 void *ptr1;
 void *ptr2;
 *ptr2 = *ptr1;

=head2 deref_ptr_set

 deref_ptr_set($ptr1, $ptr2);

equivalent to

 void **ptr1;
 void *ptr2;
 *ptr1 = ptr2;

=head2 deref_str_get

 my $string = deref_str_get($ptr);

equivalent to

 const char *string;
 const char **ptr;
 string = *ptr;

=head2 deref_str_set

 deref_str_set($ptr, $string);

equivalent to

 const char **ptr;
 const char *string;
 *ptr = string;

=head2 deref_int_get

 my $integer = deref_int_get($ptr);

equivalent to

 int *ptr;
 int integer;
 integer = *ptr;

=head2 deref_int_set

 deref_int_set($ptr, $integer);

equivalent to

 int *ptr;
 int integer;
 *ptr = integer;

=head2 deref_uint_get

 my $unsigned_integer = deref_uint_get($ptr);

equivalent to

 unsigned int unsigned_integer;
 unsigned int *ptr;
 unsigned_integer = *ptr;

=head2 deref_uint_set

 deref_uint_set($ptr, $unsigned_integer);

equivalent to

 unsigned int *ptr;
 unsigned int unsigned_integer;
 *ptr = unsigned_integer;

=head2 deref_short_get

 my $short_integer = deref_short_get($ptr);

equivalent to

 short short_integer;
 short *ptr;
 short_integer = *ptr;

=head2 deref_short_set

 deref_short_set($ptr, $short_integer);

equivalent to

 short *ptr;
 short short_integer;
 *ptr = short_integer;

=head2 deref_ushort_get

 my $unsigned_short_integer = deref_ushort_get($ptr);

equivalent to

 unsigned short unsigned_short_integer;
 unsigned short *ptr;
 unsigned unsigned_short_integer = *ptr;

=head2 deref_ushort_set

 deref_ushort_set($ptr, $unsigned_short_integer);

equivalent to

 unsigned short *ptr;
 unsigned short unsigned_short_integer;
 *ptr = unsigned_short_integer;

=head2 deref_long_get

 my $long_integer = deref_long_get($ptr);

equivalent to

 long long_integer;
 long *ptr;
 long_integer = *ptr;

=head2 deref_long_set

 deref_long_set($ptr, $long_integer);

equivalent to

 long *ptr;
 long long_integer;
 *ptr = long_integer;

=head2 deref_ulong_get

 my $unsigned_long_integer = deref_ulong_get($ptr);

equivalent to

 unsigned long unsigned_long_integer;
 unsigned long *ptr;
 unsigned unsigned_long_integer = *ptr;

=head2 deref_ulong_set

 deref_ulong_set($ptr, $unsigned_long_integer);

equivalent to

 unsigned long *ptr;
 unsigned long unsigned_long_integer;
 *ptr = unsigned_long_integer;

=head2 deref_char_get

 my $char_integer = deref_char_get($ptr);

equivalent to

 char char_integer;
 char *ptr;
 char_integer = *ptr;

=head2 deref_char_set

 deref_char_set($ptr, $char_integer);

equivalent to

 char *ptr;
 char char_integer;
 *ptr = char_integer;

=head2 deref_uchar_get

 my $unsigned_char_integer = deref_uchar_get($ptr);

equivalent to

 unsigned char unsigned char_integer;
 unsigned char *ptr;
 unsigned_char_integer = *ptr;

=head2 deref_uchar_set

 deref_uchar_set($ptr, $unsigned_char_integer);

equivalent to

 unsigned char *ptr;
 unsigned char unsigned_char_integer;
 *ptr = unsigned_char_integer;

=head2 deref_float_get

 my $single_float = deref_float_get($ptr);

equivalent to

 float single_float;
 float *ptr;
 single_float = *ptr;

=head2 deref_float_set

 deref_float_set($ptr, $single_float);

equivalent to

 float *ptr;
 float single_float;
 *ptr = single_float;

=head2 deref_double_get

 my $double_float = deref_double_get($ptr);

equivalent to

 double double_float;
 double *ptr;
 double_float = *ptr;

=head2 deref_double_set

 deref_double_set($ptr, $double_float);

equivalent to

 double *ptr;
 double double_float;
 *ptr = double_float;

=head2 deref_int64_get

 my $int64 = deref_int64_get($ptr);

equivalent to

 int64_t int64;
 int64_t *ptr;
 int64 = *ptr;

=head2 deref_int64_set

 deref_int64_set($ptr, $int64);

equivalent to

 int64_t *ptr;
 int64_t int64;
 *ptr = int64;

=head2 deref_uint64_get

 my $uint64 = deref_uint64_get($ptr);

equivalent to

 uint64_t uint64;
 uint64_t *ptr;
 uint64 = *ptr;

=head2 deref_uint64_set

 deref_uint64_set($ptr, $uint64);

equivalent to

 uint64_t *ptr;
 uint64_t uint64;
 *ptr = uint64;

=head2 deref_dev_t_get

Alias for appropriate C<derf_..._get> if dev_t is provided by your compiler.

=head2 deref_dev_t_set

Alias for appropriate C<derf_..._set> if dev_t is provided by your compiler.

=head2 deref_gid_t_get

Alias for appropriate C<derf_..._get> if gid_t is provided by your compiler.

=head2 deref_gid_t_set

Alias for appropriate C<derf_..._set> if gid_t is provided by your compiler.

=head2 deref_size_t_get

Alias for appropriate C<derf_..._get> if size_t is provided by your compiler.

=head2 deref_size_t_set

Alias for appropriate C<derf_..._set> if size_t is provided by your compiler.

=head2 deref_time_t_get

Alias for appropriate C<derf_..._get> if time_t is provided by your compiler.

=head2 deref_time_t_set

Alias for appropriate C<derf_..._set> if time_t is provided by your compiler.

=head2 deref_uid_t_get

Alias for appropriate C<derf_..._get> if uid_t is provided by your compiler.

=head2 deref_uid_t_set

Alias for appropriate C<derf_..._set> if uid_t is provided by your compiler.

=head1 SEE ALSO

=over 4

=item L<Module::Build::FFI>

=item L<FFI::Platypus>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
