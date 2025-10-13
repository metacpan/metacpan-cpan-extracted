package FFI::Platypus::Lang::Zig;

use strict;
use warnings;
use feature qw( state );
use File::ShareDir::Dist qw( dist_share );
use 5.020;

# ABSTRACT: Documentation and tools for using Platypus with the Zig programming language
our $VERSION = '0.02'; # VERSION

sub native_type_map {
  state $map = do {
    my %map = (
      u8        => 'uint8',
      u16       => 'uint16',
      u32       => 'uint32',
      u64       => 'uint64',
      # u128 unsupported by Platypus
      i8        => 'sint8',
      i16       => 'sint16',
      i32       => 'sint32',
      i64       => 'sint64',
      # i128 unsupported by Platypus
      # f16 unsupported by Platypus
      f32       => 'float',
      f64       => 'double',
      f128      => 'longdouble',
      anyopaque => 'opaque',
    );

    # computed at installtime:
    # isize, usize, c_short c_ushort c_int c_uint
    # c_longlong c_ulonglong c_longdouble bool

    my $dir = dist_share( 'FFI-Platypus-Lang-Zig' );
    my $map2 = require "$dir/types.pl";

    %map = (%map, %$map2);

    \%map;
  };

  $map;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

FFI::Platypus::Lang::Zig - Documentation and tools for using Platypus with the Zig programming language

=head1 VERSION

version 0.02

=head1 SYNOPSIS

Zig:

 pub export fn add(a: i32, b: i32) i32 {
     return a + b;
 }

Perl:

 use FFI::Platypus 2.00;
 use FFI::CheckLib qw( find_lib_or_die );
 use File::Basename qw( dirname );
 
 my $ffi = FFI::Platypus->new( api => 2, lang => 'Zig' );
 $ffi->lib(
   find_lib_or_die(
     lib        => 'add',
     libpath    => [dirname __FILE__],
     systempath => [],
   )
 );
 
 $ffi->attach( add => ['i32','i32'] => 'i32' );
 
 print add(1,2), "\n";  # prints 3

=head1 DESCRIPTION

This module provides native Zig types for FFI::Platypus in order to
reduce cognitive load and concentrate on Zig and forget about C types.
This document also covers using Platypus with Zig, and includes a
number of examples.

Note that in addition to using pre-compiled Zig libraries, you can
bundle Zig code with your Perl distribution using L<FFI::Build> and
L<FFI::Build::File::Zig>.

=head1 EXAMPLES

The examples in this discussion are bundled with this distribution and
can be found in the C<examples> directory.

=head2 Passing and Returning Integers

=head3 Zig Source

 pub export fn add(a: i32, b: i32) i32 {
     return a + b;
 }

=head3 Perl Source

 use FFI::Platypus 2.00;
 use FFI::CheckLib qw( find_lib_or_die );
 use File::Basename qw( dirname );
 
 my $ffi = FFI::Platypus->new( api => 2, lang => 'Zig' );
 $ffi->lib(
   find_lib_or_die(
     lib        => 'add',
     libpath    => [dirname __FILE__],
     systempath => [],
   )
 );
 
 $ffi->attach( add => ['i32','i32'] => 'i32' );
 
 print add(1,2), "\n";  # prints 3

=head3 Execute

 $ zig build-lib -dynamic add.zig
 $ perl add.pl
 3

=head3 Notes

Basic types like integers and floating points are the easiest to pass
across the FFI boundary.  The Platypus Zig language plugin (this module)
provides the basic types used by Zig (for example: C<bool>, C<i32>, C<u64>,
C<f64>, C<isize> and others) will all work as a Zig programmer would expect.
This is nice because you don't have to think about what the equivalent types
would be in C when you are writing your Perl extension in Zig.

Zig functions do not use the same ABI as C by default, so if you want
to be able to call Zig functions from Perl they need to be declared
with the C calling convention C<callconv(.C)> as in this example.

=head1 METHODS

Generally you will not use this class directly, instead interacting
with the FFI::Platypus instance. However, the public methods used by
Platypus are documented here.

=head2 native_type_map

 my $hashref = FFI::Platypus::Lang::Zig->native_type_map;

This returns a hash reference containing the native aliases for the
Zig programming languages. That is the keys are native Zig types
and the values are libffi native types.

=head1 CAVEATS

Only one example so far!  Hopefully more to come soon.

=head1 SEE ALSO

=over 4

=item L<FFI::Platypus>

The Core Platypus documentation

=item L<Zig Language Reference|https://ziglang.org/documentation/master/>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022-2025 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
