use strict;
use warnings FATAL => 'all';

package MarpaX::Java::ClassFile::Struct::TypePath;
use MarpaX::Java::ClassFile::Util::ArrayStringification qw/arrayStringificator/;
use MarpaX::Java::ClassFile::Struct::_Base
  -tiny => [qw/path_length path/],
  '""' => [
           [ sub { 'Path count' } => sub { $_[0]->path_length } ],
           [ sub { 'Path'       } => sub { $_[0]->arrayStringificator($_[0]->path) } ]
          ];

# ABSTRACT: type_path

our $VERSION = '0.008'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

use MarpaX::Java::ClassFile::Struct::_Types qw/U1 Path/;
use Types::Standard qw/ArrayRef/;

has path_length  => ( is => 'ro', required => 1, isa => U1 );
has path         => ( is => 'ro', required => 1, isa => ArrayRef[Path] );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Java::ClassFile::Struct::TypePath - type_path

=head1 VERSION

version 0.008

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
