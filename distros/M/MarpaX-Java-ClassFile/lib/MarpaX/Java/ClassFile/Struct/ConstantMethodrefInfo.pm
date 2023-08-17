use strict;
use warnings FATAL => 'all';

package MarpaX::Java::ClassFile::Struct::ConstantMethodrefInfo;
use MarpaX::Java::ClassFile::Struct::_Base
  -tiny => [qw/_constant_pool tag class_index name_and_type_index/],
  -oneLineDescriptionJoinString => '.',
  '""' => [
           [ sub { 'Class#' . $_[0]->class_index                 } => sub { $_[0]->_constant_pool->[$_[0]->class_index] } ],
           [ sub { 'Namd and type#' . $_[0]->name_and_type_index } => sub { $_[0]->_constant_pool->[$_[0]->name_and_type_index] } ]
          ];

# ABSTRACT: CONSTANT_Methodref_info

our $VERSION = '0.009'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

use MarpaX::Java::ClassFile::Struct::_Types qw/U1 U2/;
use Types::Standard qw/ArrayRef/;

has _constant_pool      => ( is => 'rw', required => 1, isa => ArrayRef);
has tag                 => ( is => 'ro', required => 1, isa => U1 );
has class_index         => ( is => 'ro', required => 1, isa => U2 );
has name_and_type_index => ( is => 'ro', required => 1, isa => U2 );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Java::ClassFile::Struct::ConstantMethodrefInfo - CONSTANT_Methodref_info

=head1 VERSION

version 0.009

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
