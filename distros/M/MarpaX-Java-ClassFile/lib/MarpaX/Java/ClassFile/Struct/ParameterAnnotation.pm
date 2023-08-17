use strict;
use warnings FATAL => 'all';

package MarpaX::Java::ClassFile::Struct::ParameterAnnotation;
use MarpaX::Java::ClassFile::Util::ArrayStringification qw/arrayStringificator/;
use MarpaX::Java::ClassFile::Struct::_Base
  -tiny => [qw/num_annotations annotations/],
  '""' => [
           [ sub { 'Annotations count' } => sub { $_[0]->num_annotations } ],
           [ sub { 'Annotations'       } => sub { $_[0]->arrayStringificator($_[0]->annotations) } ]
          ];

# ABSTRACT: parameter annotation

our $VERSION = '0.009'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

use MarpaX::Java::ClassFile::Struct::_Types qw/U2 Annotation/;
use Types::Standard qw/ArrayRef/;

has num_annotations => ( is => 'ro', required => 1, isa => U2 );
has annotations     => ( is => 'ro', required => 1, isa => ArrayRef[Annotation] );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Java::ClassFile::Struct::ParameterAnnotation - parameter annotation

=head1 VERSION

version 0.009

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
