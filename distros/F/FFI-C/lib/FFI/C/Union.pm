package FFI::C::Union;

use strict;
use warnings;
use base qw( FFI::C::Struct );

# ABSTRACT: Union data instance for FFI
our $VERSION = '0.11'; # VERSION


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

FFI::C::Union - Union data instance for FFI

=head1 VERSION

version 0.11

=head1 SYNOPSIS

 use FFI::C::UnionDef;
 
 my $def = FFI::C::UnionDef->new(
   name => 'anyint_t',
   class => 'AnyInt',
   members => [
     u8  => 'uint8',
     u16 => 'uint16',
     u32 => 'uint32',
   ],
 );
 
 my $int = AnyInt->new({ u8 => 42 });
 printf "0x%x\n", $int->u32;   # 0x2a on Intel

=head1 DESCRIPTION

This class represents an instance of a C C<union>.  This class can be created using
C<new> on the generated class, if that was specified for the L<FFI::C::UnionDef>,
or by using the C<create> method on L<FFI::C::UnionDef>.

For each member defined in the L<FFI::C::UnionDef> there is an accessor for the
L<FFI::C::Union> instance.

=head1 CONSTRUCTOR

=head2 new

 FFI::C::UnionDef->new( class => 'User::Union::Class', ... );
 my $instance = User::Union::Class->new;

Creates a new instance of the C<union>.

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

This software is copyright (c) 2020,2021 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
