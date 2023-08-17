use strict;
use warnings FATAL => 'all';

package MarpaX::Java::ClassFile::Util::ProductionMode;

# ABSTRACT: Provide an prod_isa that, in production mode, returns nothing

our $VERSION = '0.009'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

use Exporter 'import';
our @EXPORT_OK = qw/prod_isa/;

sub prod_isa { $ENV{AUTHOR_TESTING} ? (isa => @_) : () }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Java::ClassFile::Util::ProductionMode - Provide an prod_isa that, in production mode, returns nothing

=head1 VERSION

version 0.009

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
