package FFI::C::UnionDef;

use strict;
use warnings;
use 5.008001;
use FFI::C::Union;
use FFI::Platypus 1.24;
use constant _is_union => 1;
use base qw( FFI::C::StructDef );

# ABSTRACT: Union data definition for FFI
our $VERSION = '0.15'; # VERSION


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

FFI::C::UnionDef - Union data definition for FFI

=head1 VERSION

version 0.15

=head1 SYNOPSIS

In your C code:

 #include <stdint.h>
 #include <stdio.h>
 
 typedef union {
   uint8_t  u8;
   uint16_t u16;
   uint32_t u32;
 } anyint_t;
 
 void
 print_anyint_as_u32(anyint_t *any)
 {
   printf("0x%x\n", any->u32);
 }

In your Perl code:

 use FFI::Platypus 1.00;
 use FFI::C::UnionDef;
 
 my $ffi = FFI::Platypus->new( api => 1 );
 # See FFI::Platypus::Bundle for how bundle works.
 $ffi->bundle;
 
 my $def = FFI::C::UnionDef->new(
   $ffi,
   name => 'anyint_t',
   class => 'AnyInt',
   members => [
     u8  => 'uint8',
     u16 => 'uint16',
     u32 => 'uint32',
   ],
 );
 
 $ffi->attach( print_anyint_as_u32 => ['anyint_t'] );
 
 my $int = AnyInt->new({ u8 => 42 });
 print_anyint_as_u32($int);  # 0x2a on Intel,

=head1 DESCRIPTION

This class creates a def for a C C<union>.

=head1 CONSTRUCTOR

=head2 new

 my $def = FFI::C::UnionDef->new(%opts);
 my $def = FFI::C::UnionDef->new($ffi, %opts);

For standard def options, see L<FFI::C::Def>.

=over 4

=item members

This should be an array reference containing name, type pairs.
For a union, the order doesn't matter.

=back

=head1 METHODS

=head2 create

 my $instance = $def->create;
 my $instance = $def->class->new;          # if class was specified
 my $instance = $def->create(\%init);
 my $instance = $def->class->new(\%init);  # if class was specified

This creates an instance of the C<union>, returns a L<FFI::C::Union>.

You can optionally initialize member values using C<%init>.

=head1 SEE ALSO

=over 4

=item L<FFI::C>

=item L<FFI::C::Array>

=item L<FFI::C::ArrayDef>

=item L<FFI::C::Def>

=item L<FFI::C::File>

=item L<FFI::C::PosixFile>

=item L<FFI::C::Struct>

=item L<FFI::C::StructDef>

=item L<FFI::C::Union>

=item L<FFI::C::UnionDef>

=item L<FFI::C::Util>

=item L<FFI::Platypus::Record>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020-2022 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
