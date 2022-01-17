use strict;
use warnings FATAL => 'all';

package MarpaX::ESLIF::JSON;
use MarpaX::ESLIF::JSON::Encoder;
use MarpaX::ESLIF::JSON::Decoder;

# ABSTRACT: ESLIF's JSON interface

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

our $VERSION = '6.0.12'; # VERSION



sub new {
    my $class = shift;

    return bless { encoder => MarpaX::ESLIF::JSON::Encoder->new(@_), decoder => MarpaX::ESLIF::JSON::Decoder->new(@_) }, $class
}


sub encode {
    my ($self, $value) = @_;

    return $self->{encoder}->encode($value)
}


sub decode {
    my ($self, $string, %options) = @_;

    return $self->{decoder}->decode($string, %options)
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::ESLIF::JSON - ESLIF's JSON interface

=head1 VERSION

version 6.0.12

=head1 DESCRIPTION

This is JSON's strict and relax encoder/decoder writen directly in L<MarpaX::ESLIF> library.

There are two JSON modes:

=over

=item Strict

Encoder and decoder are strict, as per L<ECMA-404 The JSON Data Interchange Standard|https://www.json.org>.

=item Relax

This is strict grammar extended with:

=over

=item Unlimited commas

=item Trailing separator

=item Perl style comment

=item C++ style comment

=item Infinity

=item NaN

=item Unicode's control characters (range C<[\x00-\x1F]>).

=item Number with non significant zeroes on the left.

=item Number with a leading C<+> sign.

=back

=back

=head1 METHODS

=head2 MarpaX::ESLIF::JSON->new($eslif[, $strict])

   my $eslifJSON = MarpaX::ESLIF::JSON->new($eslif);

Just a convenient wrapper over L<MarpaX::ESLIF::JSON::Encoder> and L<MarpaX::ESLIF::JSON::Decoder>. Parameters are:

=over

=item C<$eslif>

MarpaX::ESLIF object instance. Required.

=item C<$strict>

A true value means strict JSON, else relax JSON. Default is a true value.

=back

=head2 $eslifJSON->encode($value)

   my $string = $eslifJSON->encode($value);

=head2 $eslifJSON->decode($string, %options)

   my $value = $eslifJSON->decode($string);

Please refer to L<MarpaX::ESLIF::JSON::Decoder> for the options.

=head1 NOTES

=over

=item Floating point special values

C<+/-Infinity> and C<+/-NaN> are always mapped to L<Math::BigInt>'s C<binf()>, C<binf('-')>, C<bnan()>, C<bnan('-')>, respectively.

=item other numbers

They are always mapped to L<Math::BigFloat>.

=back

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
