use strict;
use warnings FATAL => 'all';

package MarpaX::Java::ClassFile::Struct::Annotation;
use MarpaX::Java::ClassFile::Util::ArrayStringification qw/arrayStringificator/;
use MarpaX::Java::ClassFile::Struct::_Base
  -tiny => [qw/_constant_pool type_index num_element_value_pairs element_value_pairs/],
  '""' => [
           [ sub { 'Type#' . $_[0]->type_index } => sub { $_[0]->_constant_pool->[$_[0]->type_index] } ],
           [ sub { 'Element value pairs count' } => sub { $_[0]->num_element_value_pairs } ],
           [ sub { 'Element value pairs'       } => sub { $_[0]->arrayStringificator($_[0]->element_value_pairs) } ]
          ];

# ABSTRACT: annotation

our $VERSION = '0.009'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

use MarpaX::Java::ClassFile::Struct::_Types qw/U2 ElementValuePair/;
use Types::Standard qw/ArrayRef/;

has _constant_pool          => ( is => 'rw', required => 1, isa => ArrayRef);
has type_index              => ( is => 'ro', required => 1, isa => U2 );
has num_element_value_pairs => ( is => 'ro', required => 1, isa => U2 );
has element_value_pairs     => ( is => 'ro', required => 1, isa => ArrayRef[ElementValuePair] );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Java::ClassFile::Struct::Annotation - annotation

=head1 VERSION

version 0.009

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
