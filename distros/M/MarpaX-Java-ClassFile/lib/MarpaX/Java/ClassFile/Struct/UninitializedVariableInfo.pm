use strict;
use warnings FATAL => 'all';

package MarpaX::Java::ClassFile::Struct::UninitializedVariableInfo;
use MarpaX::Java::ClassFile::Struct::_Base
  -tiny => [qw/tag offset/],
  '""' => [
           [ sub { 'tag'    } => sub { 'ITEM_Uninitialized' } ],
           [ sub { 'offset' } => sub { $_[0]->offset } ]
          ];

# ABSTRACT: Uninitialized_variable_info

our $VERSION = '0.009'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

use MarpaX::Java::ClassFile::Struct::_Types qw/U1 U2/;

has tag    => ( is => 'ro', required => 1, isa => U1 );
has offset => ( is => 'ro', required => 1, isa => U2 );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Java::ClassFile::Struct::UninitializedVariableInfo - Uninitialized_variable_info

=head1 VERSION

version 0.009

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
