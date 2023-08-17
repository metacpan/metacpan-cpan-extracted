use strict;
use warnings FATAL => 'all';

package MarpaX::Java::ClassFile::Struct::MethodInfo;
use MarpaX::Java::ClassFile::Util::ArrayStringification qw/arrayStringificator/;
use MarpaX::Java::ClassFile::Util::AccessFlagsStringification qw/accessFlagsStringificator/;
use MarpaX::Java::ClassFile::Struct::_Base
  -tiny => [qw/_constant_pool access_flags name_index descriptor_index attributes_count attributes/],
  '""' => [
           [ sub { 'Name#' . $_[0]->name_index             } => sub { $_[0]->_constant_pool->[$_[0]->name_index] } ],
           [ sub { 'Descriptor#' . $_[0]->descriptor_index } => sub { $_[0]->_constant_pool->[$_[0]->descriptor_index] } ],
           [ sub { 'Method access flags'                   } => sub { $_[0]->accessFlagsStringificator($_[0]->access_flags) } ],
           [ sub { 'Attributes count'                      } => sub { $_[0]->attributes_count } ],
           [ sub { 'Attributes'                            } => sub { $_[0]->arrayStringificator($_[0]->attributes) } ]
          ];

# ABSTRACT: method_info

our $VERSION = '0.009'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

use MarpaX::Java::ClassFile::Struct::_Types qw/U2 AttributeInfo/;
use Types::Standard qw/ArrayRef/;

has _constant_pool   => ( is => 'rw', required => 1, isa => ArrayRef);
has access_flags     => ( is => 'ro', required => 1, isa => U2 );
has name_index       => ( is => 'ro', required => 1, isa => U2 );
has descriptor_index => ( is => 'ro', required => 1, isa => U2 );
has attributes_count => ( is => 'ro', required => 1, isa => U2 );
has attributes       => ( is => 'ro', required => 1, isa => ArrayRef[AttributeInfo] );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Java::ClassFile::Struct::MethodInfo - method_info

=head1 VERSION

version 0.009

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
