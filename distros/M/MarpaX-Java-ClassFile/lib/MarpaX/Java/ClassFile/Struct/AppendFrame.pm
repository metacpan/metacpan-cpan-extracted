use strict;
use warnings FATAL => 'all';

package MarpaX::Java::ClassFile::Struct::AppendFrame;
use MarpaX::Java::ClassFile::Util::FrameTypeStringification qw/frameTypeStringificator/;
use MarpaX::Java::ClassFile::Util::ArrayStringification qw/arrayStringificator/;
use MarpaX::Java::ClassFile::Struct::_Base
  -tiny => [qw/frame_type offset_delta locals/],
  '""' => [
           [ sub { 'Frame type'   } => sub { $_[0]->frameTypeStringificator($_[0]->frame_type) } ],
           [ sub { 'Offset delta' } => sub { $_[0]->offset_delta } ],
           [ sub { 'Locals count' } => sub { $_[0]->frame_type - 251 } ],
           [ sub { 'Locals'       } => sub { $_[0]->arrayStringificator($_[0]->locals) } ]
          ];

# ABSTRACT: append_frame

our $VERSION = '0.009'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

use MarpaX::Java::ClassFile::Struct::_Types qw/U1 U2 VerificationTypeInfo/;
use Types::Standard qw/ArrayRef/;

has frame_type   => ( is => 'ro', required => 1, isa => U1 );
has offset_delta => ( is => 'ro', required => 1, isa => U2 );
has locals       => ( is => 'ro', required => 1, isa => ArrayRef[VerificationTypeInfo] );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Java::ClassFile::Struct::AppendFrame - append_frame

=head1 VERSION

version 0.009

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
