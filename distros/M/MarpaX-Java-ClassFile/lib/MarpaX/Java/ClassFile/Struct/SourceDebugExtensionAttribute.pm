use strict;
use warnings FATAL => 'all';

package MarpaX::Java::ClassFile::Struct::SourceDebugExtensionAttribute;
use MarpaX::Java::ClassFile::Struct::_Base
  -tiny => [qw/_constant_pool attribute_name_index attribute_length debug_extension/],
  '""' => [
           #
           # (I believe it) can be undef
           #
           [ sub { 'Debug extension'                               } => sub { $_[0]->debug_extension // '' } ]
          ];

# ABSTRACT: SourceDebugExtension_attribute

our $VERSION = '0.009'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

use MarpaX::Java::ClassFile::Struct::_Types qw/U1 U2 U4/;
use Types::Standard qw/ArrayRef Str Undef/;

has _constant_pool       => ( is => 'rw', required => 1, isa => ArrayRef);
has attribute_name_index => ( is => 'ro', required => 1, isa => U2 );
has attribute_length     => ( is => 'ro', required => 1, isa => U4 );
has debug_extension      => ( is => 'ro', required => 1, isa => Str|Undef );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Java::ClassFile::Struct::SourceDebugExtensionAttribute - SourceDebugExtension_attribute

=head1 VERSION

version 0.009

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
