use strict;
use warnings FATAL => 'all';

package MarpaX::ESLIF::JSON::Decoder;
use parent qw/MarpaX::ESLIF::Grammar/;
use MarpaX::ESLIF::JSON::Decoder::RecognizerInterface;

#
# Base required class methods
#
sub _ALLOCATE { return \&MarpaX::ESLIF::JSON::Decoder::allocate }
sub _EQ {
    return sub {
        my ($class, $args_ref, $eslif, $strict) = @_;

        my $definedStrict = defined($strict);
        my $_definedStrict = defined($args_ref->[1]);

        return
            ($eslif == $args_ref->[0])
            &&
            ($definedStrict && $_definedStrict && ($strict == $args_ref->[1]))
    }
}

# ABSTRACT: ESLIF's JSON decoder interface

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

our $VERSION = '6.0.27'; # VERSION



sub decode {
    my ($self, $string, %options) = @_;

    my $recognizerInterface = MarpaX::ESLIF::JSON::Decoder::RecognizerInterface->new($string, $options{encoding});
    return $self->_decode($recognizerInterface, $options{disallowDupkeys}, $options{maxDepth}, $options{noReplacementCharacter})
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::ESLIF::JSON::Decoder - ESLIF's JSON decoder interface

=head1 VERSION

version 6.0.27

=head1 DESCRIPTION

This is JSON's strict and relax decoder writen directly in L<MarpaX::ESLIF> library.

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

=back

=back

=head1 METHODS

=head2 MarpaX::ESLIF::JSON::Decoder->new($eslif[, $strict])

   my $eslifJSONDecoder = MarpaX::ESLIF::JSON::Decoder->new($eslif);

Returns a JSON grammar instance, noted C<$eslifJSONDecoder> later. Parameters are:

=over

=item C<$eslif>

MarpaX::ESLIF object instance. Required.

=item C<$strict>

A true value means strict JSON, else relax JSON. Default is a true value.

=back

=head2 $eslifJSONDecoder->decode($string, %options)

   my $value = $eslifJSONDecoder->decode($string);

Returns a value containing decoded C<$string>. In relax mode, special floating point are supported:

=over

=item C<+Infinity>

Positive infinity, either as a native floating point number if the underlying system supports that, or as a C<Math::BigInt->binf()> instance.

=item C<-Infinity>

Negative infinity, either as a native floating point number if the underlying system supports that, or as a C<Math::BigInt->binf('-')> instance.

=item C<NaN>

Not-a-Number, either as a native floating point number if the underlying system supports that, or as a C<Math::BigInt->bnan()> instance.

=back

Supported options are:

=over

=item encoding

Input encoding. Can be C<undef>.

=item disallowDupkeys

A true value will disallow duplicate keys. Default is a false value.

=item maxDepth

Maximum depth. Default is 0, meaning no limit.

=item noReplacementCharacter

A true value will disallow UTF-8 replacement character for invalid UTF-16 surrogates. Default is a false value.

=back

=head1 NOTES

Formally, the JSON implementation is only a grammar coded directly in the ESLIF library, therefore this module inherits from L<MarpaX::ESLIF::Grammar>.

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
