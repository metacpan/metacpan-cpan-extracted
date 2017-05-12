use strict;
use warnings FATAL => 'all';

package MarpaX::Java::ClassFile::Struct::LocalVariableType;
use MarpaX::Java::ClassFile::Struct::_Base
  -tiny => [qw/_constant_pool start_pc length name_index signature_index index/],
  '""' => [
           [ sub { 'Name#' . $_[0]->name_index           } => sub { $_[0]->_constant_pool->[$_[0]->name_index] } ],
           [ sub { 'Signature#' . $_[0]->signature_index } => sub { $_[0]->_constant_pool->[$_[0]->signature_index] } ],
           [ sub { 'Start pc'                            } => sub { $_[0]->start_pc } ],
           [ sub { 'Length'                              } => sub { $_[0]->length } ],
           [ sub { 'Index'                               } => sub { $_[0]->index } ]
          ];

# ABSTRACT: local variable type

our $VERSION = '0.008'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

use MarpaX::Java::ClassFile::Struct::_Types qw/U2/;
use Types::Standard qw/ArrayRef/;

has _constant_pool   => ( is => 'rw', required => 1, isa => ArrayRef);
has start_pc         => ( is => 'ro', required => 1, isa => U2 );
has length           => ( is => 'ro', required => 1, isa => U2 );
has name_index       => ( is => 'ro', required => 1, isa => U2 );
has signature_index  => ( is => 'ro', required => 1, isa => U2 );
has index            => ( is => 'ro', required => 1, isa => U2 );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Java::ClassFile::Struct::LocalVariableType - local variable type

=head1 VERSION

version 0.008

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
