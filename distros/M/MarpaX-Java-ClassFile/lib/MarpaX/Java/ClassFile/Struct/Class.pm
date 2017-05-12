use strict;
use warnings FATAL => 'all';

package MarpaX::Java::ClassFile::Struct::Class;
use MarpaX::Java::ClassFile::Util::AccessFlagsStringification qw/accessFlagsStringificator/;
use MarpaX::Java::ClassFile::Struct::_Base
  -tiny => [qw/_constant_pool inner_class_info_index outer_class_info_index inner_name_index inner_class_access_flags/],
  '""' => [
           [ sub { 'Inner class info#' . $_[0]->inner_class_info_index } => sub { $_[0]->_constant_pool->[$_[0]->inner_class_info_index] } ],
           #
           # outer_class_info_index can be zero
           #
           [ sub { 'Outer class Info#' . $_[0]->outer_class_info_index } => sub { ($_[0]->outer_class_info_index > 0) ? $_[0]->_constant_pool->[$_[0]->outer_class_info_index] : '' } ],
           #
           # inner_name_index can be zero
           #
           [ sub { 'Inner name#' . $_[0]->inner_name_index             } => sub { ($_[0]->inner_name_index > 0) ? $_[0]->_constant_pool->[$_[0]->inner_name_index] : '' } ],
           [ sub { 'Inner class access flags'                          } => sub { $_[0]->accessFlagsStringificator($_[0]->inner_class_access_flags) } ]
          ];

# ABSTRACT: classes

our $VERSION = '0.008'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

use MarpaX::Java::ClassFile::Struct::_Types qw/U2/;
use Types::Standard qw/ArrayRef/;

has _constant_pool           => ( is => 'rw', required => 1, isa => ArrayRef);
has inner_class_info_index   => ( is => 'ro', required => 1, isa => U2 );
has outer_class_info_index   => ( is => 'ro', required => 1, isa => U2 );
has inner_name_index         => ( is => 'ro', required => 1, isa => U2 );
has inner_class_access_flags => ( is => 'ro', required => 1, isa => U2 );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Java::ClassFile::Struct::Class - classes

=head1 VERSION

version 0.008

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
