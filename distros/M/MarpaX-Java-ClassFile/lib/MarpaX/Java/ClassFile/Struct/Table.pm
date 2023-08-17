use strict;
use warnings FATAL => 'all';

package MarpaX::Java::ClassFile::Struct::Table;
use MarpaX::Java::ClassFile::Struct::_Base
  -tiny => [qw/start_pc length index/],
  '""' => [
           [ sub { '{#Start pc, #Length, #Index}' } => sub { '{#' . join(', ', $_[0]->start_pc, $_[0]->length, $_[0]->index) . '}' } ]
          ];

# ABSTRACT: table

our $VERSION = '0.009'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

use MarpaX::Java::ClassFile::Struct::_Types qw/U2/;

has start_pc => ( is => 'ro', required => 1, isa => U2 );
has length   => ( is => 'ro', required => 1, isa => U2 );
has index    => ( is => 'ro', required => 1, isa => U2 );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Java::ClassFile::Struct::Table - table

=head1 VERSION

version 0.009

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
