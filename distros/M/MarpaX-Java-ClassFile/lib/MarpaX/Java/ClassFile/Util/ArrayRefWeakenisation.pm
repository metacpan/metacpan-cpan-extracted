use strict;
use warnings FATAL => 'all';

package MarpaX::Java::ClassFile::Util::ArrayRefWeakenisation;
use Carp qw/croak/;
use Exporter 'import'; # gives you Exporter's import() method directly
use Scalar::Util qw/weaken/;
our @EXPORT_OK = qw/arrayRefWeakenisator/;

# ABSTRACT: Weakens the content of an array reference

our $VERSION = '0.008'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

sub arrayRefWeakenisator {
  # my ($self, $arrayRef) = @_;

  map { weaken($_[1]->[$_]) } (0..$#{$_[1]})
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Java::ClassFile::Util::ArrayRefWeakenisation - Weakens the content of an array reference

=head1 VERSION

version 0.008

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
