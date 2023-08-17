use strict;
use warnings FATAL => 'all';

package MarpaX::Java::ClassFile::Struct::TypeParameterBoundTarget;
use MarpaX::Java::ClassFile::Struct::_Base
  -tiny => [qw/type_parameter_index bound_index/],
  '""' => [
           [ sub { 'Type parameter index' } => sub { $_[0]->type_parameter_index } ],
           [ sub { 'Bound index'          } => sub { $_[0]->bound_index } ],
          ];

# ABSTRACT: type_parameter_bound_target

our $VERSION = '0.009'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

use MarpaX::Java::ClassFile::Struct::_Types qw/U1/;

has type_parameter_index => ( is => 'ro', required => 1, isa => U1 );
has bound_index          => ( is => 'ro', required => 1, isa => U1 );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Java::ClassFile::Struct::TypeParameterBoundTarget - type_parameter_bound_target

=head1 VERSION

version 0.009

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
