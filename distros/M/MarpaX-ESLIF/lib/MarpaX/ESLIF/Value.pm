use strict;
use warnings FATAL => 'all';

package MarpaX::ESLIF::Value;
use parent qw/MarpaX::ESLIF::Base/;

#
# Base required class methods
#
sub _CLONABLE { return sub { 0 } }
sub _ALLOCATE { return \&MarpaX::ESLIF::Value::allocate }
sub _DISPOSE  { return \&MarpaX::ESLIF::Value::dispose }
sub _EQ       { return }

# ABSTRACT: MarpaX::ESLIF's value

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

our $VERSION = '4.0.1'; # VERSION


sub CLONE_SKIP {
    return 1
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::ESLIF::Value - MarpaX::ESLIF's value

=head1 VERSION

version 4.0.1

=head1 SYNOPSIS

  my $eslifValue = MarpaX::ESLIF::Value->new($eslifRecognizer, $valueInterface);

The value interface is used to get parse tree valuation.

=head1 DESCRIPTION

MarpaX::ESLIF::Value is a possible step after a MarpaX::ESLIF::Recognizer instance is created.

=head1 METHODS

=head2 MarpaX::ESLIF::Value->new($eslifRecognizer, $valueInterface)

  my $eslifValue = MarpaX::ESLIF::Value->new($eslifRecognizer, $valueInterface);

Returns a value instance, noted C<$eslifValue> later. Parameters are:

=over

=item C<$eslifRecognizer>

MarpaX::ESLIF:Recognizer object instance. Required.

=item C<$valueInterface>

An object implementing L<MarpaX::ESLIF::Value::Interface> methods. Required.

=back

=head2 $eslifValue->value()

Returns a boolean indicating if there a value to retrieve via the valueInterface's getResult() method.

=head1 SEE ALSO

L<MarpaX::ESLIF::Value::Interface>

=head1 NOTES

L<MarpaX::ESLIF::Value> cannot be reused across threads.

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
