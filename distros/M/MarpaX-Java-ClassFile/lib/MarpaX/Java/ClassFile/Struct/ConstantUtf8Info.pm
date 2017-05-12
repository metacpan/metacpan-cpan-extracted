use strict;
use warnings FATAL => 'all';

package MarpaX::Java::ClassFile::Struct::ConstantUtf8Info;
use MarpaX::Java::ClassFile::Struct::_Base
  -tiny => [qw/_perlvalue tag length bytes/],
  '""' => [
           [ sub { $_[0]->_perlvalue // ''} ] # Can be undef
          ];

# ABSTRACT: CONSTANT_Utf8_info

our $VERSION = '0.008'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

use MarpaX::Java::ClassFile::Struct::_Types qw/U1 U2/;
use Types::Encodings qw/Bytes/;
use Types::Standard qw/Str Undef/;

has _perlvalue   => ( is => 'ro', required => 1, isa => Str|Undef);
has tag          => ( is => 'ro', required => 1, isa => U1 );
has length       => ( is => 'ro', required => 1, isa => U2 );
has bytes        => ( is => 'ro', required => 1, isa => Bytes|Undef );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Java::ClassFile::Struct::ConstantUtf8Info - CONSTANT_Utf8_info

=head1 VERSION

version 0.008

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
