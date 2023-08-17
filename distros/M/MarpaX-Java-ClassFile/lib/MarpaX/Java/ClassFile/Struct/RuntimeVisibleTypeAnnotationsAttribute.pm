use strict;
use warnings FATAL => 'all';

package MarpaX::Java::ClassFile::Struct::RuntimeVisibleTypeAnnotationsAttribute;
use MarpaX::Java::ClassFile::Util::ArrayStringification qw/arrayStringificator/;
use MarpaX::Java::ClassFile::Struct::_Base
  -tiny => [qw/_constant_pool attribute_name_index attribute_length num_annotations annotations/],
  '""' => [
           [ sub { 'Type annotations count'                        } => sub { $_[0]->num_annotations } ],
           [ sub { 'Type annotations'                              } => sub { $_[0]->arrayStringificator($_[0]->annotations) } ]
          ];

# ABSTRACT: RuntimeVisibleTypeAnnotations_attribute

our $VERSION = '0.009'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

use MarpaX::Java::ClassFile::Struct::_Types qw/U1 U2 U4 TypeAnnotation/;
use Types::Standard qw/ArrayRef/;

has _constant_pool        => ( is => 'rw', required => 1, isa => ArrayRef);
has attribute_name_index  => ( is => 'ro', required => 1, isa => U2 );
has attribute_length      => ( is => 'ro', required => 1, isa => U4 );
has num_annotations       => ( is => 'ro', required => 1, isa => U1 );
has annotations           => ( is => 'ro', required => 1, isa => ArrayRef[TypeAnnotation] );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Java::ClassFile::Struct::RuntimeVisibleTypeAnnotationsAttribute - RuntimeVisibleTypeAnnotations_attribute

=head1 VERSION

version 0.009

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
