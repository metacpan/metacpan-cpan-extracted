use strict;
use warnings FATAL => 'all';

package MarpaX::Java::ClassFile::Struct::ArrayValue;
use MarpaX::Java::ClassFile::Util::ArrayStringification qw/arrayStringificator/;
use MarpaX::Java::ClassFile::Struct::_Base
  -tiny => [qw/num_values values/],
  '""' => [
           [ sub { 'Values count' } => sub { $_[0]->num_values } ],
           [ sub { 'Values'       } => sub { $_[0]->arrayStringificator($_[0]->values) } ]
          ];

# ABSTRACT: constant value

our $VERSION = '0.009'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

use MarpaX::Java::ClassFile::Struct::_Types qw/U2 ElementValue/;
use Types::Standard qw/ArrayRef/;

has num_values => ( is => 'ro', required => 1, isa => U2 );
has values     => ( is => 'ro', required => 1, isa => ArrayRef[ElementValue] );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Java::ClassFile::Struct::ArrayValue - constant value

=head1 VERSION

version 0.009

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
