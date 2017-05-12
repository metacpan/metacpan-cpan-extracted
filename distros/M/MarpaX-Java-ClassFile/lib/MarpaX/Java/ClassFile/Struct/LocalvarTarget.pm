use strict;
use warnings FATAL => 'all';

package MarpaX::Java::ClassFile::Struct::LocalvarTarget;
use MarpaX::Java::ClassFile::Util::ArrayStringification qw/arrayStringificator/;
use MarpaX::Java::ClassFile::Struct::_Base
  -tiny => [qw/table_length table/],
  '""' => [
           [ sub { 'Table count' } => sub { $_[0]->table_length } ],
           [ sub { 'Table'       } => sub { $_[0]->arrayStringificator($_[0]->table) } ]
          ];

# ABSTRACT: localvar_target

our $VERSION = '0.008'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

use MarpaX::Java::ClassFile::Struct::_Types qw/U2 Table/;
use Types::Standard qw/ArrayRef/;

has table_length => ( is => 'ro', required => 1, isa => U2 );
has table        => ( is => 'ro', required => 1, isa => ArrayRef[Table] );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Java::ClassFile::Struct::LocalvarTarget - localvar_target

=head1 VERSION

version 0.008

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
