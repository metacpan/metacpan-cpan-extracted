use strict;
use warnings FATAL => 'all';

package MarpaX::Java::ClassFile::Struct::TypeArgumentTarget;
use MarpaX::Java::ClassFile::Struct::_Base
  -tiny => [qw/offset type_argument_index/],
  '""' => [
           [ sub { 'Offset'              } => sub { $_[0]->offset } ],
           [ sub { 'Type argument index' } => sub { $_[0]->type_argument_index } ]
          ];

# ABSTRACT: localvar_target

our $VERSION = '0.008'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

use MarpaX::Java::ClassFile::Struct::_Types qw/U1 U2/;

has offset              => ( is => 'ro', required => 1, isa => U2 );
has type_argument_index => ( is => 'ro', required => 1, isa => U1 );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Java::ClassFile::Struct::TypeArgumentTarget - localvar_target

=head1 VERSION

version 0.008

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
