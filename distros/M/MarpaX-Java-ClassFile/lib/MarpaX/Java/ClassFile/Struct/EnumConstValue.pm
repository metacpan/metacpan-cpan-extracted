use strict;
use warnings FATAL => 'all';

package MarpaX::Java::ClassFile::Struct::EnumConstValue;
use MarpaX::Java::ClassFile::Struct::_Base
  -tiny => [qw/_constant_pool type_name_index const_name_index/],
  '""' => [
           [ sub { 'Type name#' . $_[0]->type_name_index   } => sub { $_[0]->_constant_pool->[$_[0]->type_name_index] } ],
           [ sub { 'Const name#' . $_[0]->const_name_index } => sub { $_[0]->_constant_pool->[$_[0]->const_name_index] } ]
          ];

# ABSTRACT: enum constant value

our $VERSION = '0.008'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

use MarpaX::Java::ClassFile::Struct::_Types qw/U2/;
use Types::Standard qw/ArrayRef/;

has _constant_pool   => ( is => 'rw', required => 1, isa => ArrayRef);
has type_name_index  => ( is => 'ro', required => 1, isa => U2 );
has const_name_index => ( is => 'ro', required => 1, isa => U2 );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Java::ClassFile::Struct::EnumConstValue - enum constant value

=head1 VERSION

version 0.008

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
