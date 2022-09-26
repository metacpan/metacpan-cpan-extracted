use strict;
use warnings FATAL => 'all';

package MarpaX::ESLIF::JSON::Encoder;
use parent qw/MarpaX::ESLIF::Grammar/;

#
# Base required class methods
#
sub _ALLOCATE { return \&MarpaX::ESLIF::JSON::Encoder::allocate }
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

# ABSTRACT: ESLIF's JSON encoder interface

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

our $VERSION = '6.0.27'; # VERSION



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::ESLIF::JSON::Encoder - ESLIF's JSON encoder interface

=head1 VERSION

version 6.0.27

=head1 DESCRIPTION

This is JSON's strict and relax encoder writen directly in L<MarpaX::ESLIF> library.

There are two JSON modes:

=over

=item Strict

Encoder is strict, as per L<ECMA-404 The JSON Data Interchange Standard|https://www.json.org>.

=item Relax

Encoder is relax, i.e.:

=over

=item Infinity

C<+Infinity> and C<-Infinity> can appear in the output.

=item NaN

C<NaN> can appear in the output.

=back

=back

=head1 METHODS

=head2 MarpaX::ESLIF::JSON::Encoder->new($eslif[, $strict])

   my $eslifJSONEncoder = MarpaX::ESLIF::JSON::Encoder->new($eslif);

Returns a JSON grammar instance, noted C<$eslifJSONEncoder> later. Parameters are:

=over

=item C<$eslif>

MarpaX::ESLIF object instance. Required.

=item C<$strict>

A true value means strict JSON, else relax JSON. Default is a true value.

=back

=head2 $eslifJSONEncoder->encode($value)

   my $string = $eslifJSONEncoder->encode($value);

Returns a string containing encoded JSON data.

=head1 NOTES

Formally, the JSON implementation is only a grammar coded directly in the ESLIF library, therefore this module inherits from L<MarpaX::ESLIF::Grammar>.

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
