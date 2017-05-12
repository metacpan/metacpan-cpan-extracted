use strict;
use warnings FATAL => 'all';

package MarpaX::Java::ClassFile::Struct::ConstantMethodHandleInfo;
use MarpaX::Java::ClassFile::Struct::_Base
  -tiny => [qw/_constant_pool tag reference_kind reference_index/],
  '""' => [
           # [ sub { 'Reference kind' }                      => sub { $_[0]->reference_kind } ],
           [ sub { 'Reference#' . $_[0]->reference_index } => sub { $_[0]->_constant_pool->[$_[0]->reference_index] } ]
         ];

# ABSTRACT: CONSTANT_MethodHandle_info

our $VERSION = '0.008'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

use MarpaX::Java::ClassFile::Struct::_Types qw/U1 U2/;
use Types::Standard qw/ArrayRef/;

has _constant_pool  => ( is => 'rw', required => 1, isa => ArrayRef);
has tag             => ( is => 'ro', required => 1, isa => U1 );
has reference_kind  => ( is => 'ro', required => 1, isa => U1 );
has reference_index => ( is => 'ro', required => 1, isa => U2 );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Java::ClassFile::Struct::ConstantMethodHandleInfo - CONSTANT_MethodHandle_info

=head1 VERSION

version 0.008

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
