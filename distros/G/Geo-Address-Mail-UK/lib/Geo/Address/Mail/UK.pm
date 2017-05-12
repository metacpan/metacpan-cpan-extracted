package Geo::Address::Mail::UK;
use warnings;
use strict;
use Moose;
use MooseX::Storage;
with qw(MooseX::Storage::Deferred);

use Moose::Util::TypeConstraints;

extends 'Geo::Address::Mail';

our $VERSION = '0.02';

subtype 'Geo::Address::Mail::UKPostalCode',
    => as 'Str',
    => where {
        $_ =~ /^([A-PR-UWYZ]([0-9]{1,2}|([A-HK-Y][0-9]|[A-HK-Y][0-9]([0-9]|[ABEHMNPRV-Y]))|[0-9][A-HJKS-UW])\ [0-9][ABD-HJLNP-UW-Z]{2}|(GIR\ 0AA)|(SAN\ TA1)|(BFPO\ (C\/O\ )?[0-9]{1,4})|((ASCN|BBND|[BFS]IQQ|PCRN|STHL|TDCU|TKCA)\ 1ZZ))$/;
    };

has '+postal_code' => (
    isa => 'Geo::Address::Mail::UKPostalCode'
);

has 'building' => (
    is => 'rw',
    isa => 'Str'
);

has 'locality' => (
    is => 'rw',
    isa => 'Str'
);

__PACKAGE__->meta->make_immutable;
no Moose;
1;

=head1 NAME

Geo::Address::Mail::UK - A Mailing Address in the United Kingdom

=head1 SYNOPSIS

Geo::Address::Mail::UK is a subclass of L<Geo::Address::Mail> that provides
specific validation and attributes for mailing addresses located in the United
Kingdom.

    use Geo::Address::Mail::UK;

    my $add = Geo::Address::Mail::UK->new(
        name => 'Sherlock Holmes',
        street => '221b Baker St',
        city => 'London',
        postal_code => 'NW1 6XE'
    );

=head1 ATTRIBUTES

Geo::Address::Mail::UK has all the attributes of L<Geo::Address::Mail>.  The
following attributes are either modified or new.

=head2 postal_code

Postal codes are validated to conform to the Royal Mail standard.

=head2 building

Addresses can have a building name between the name and the street address.

=head2 locality

Addresses have an optional locality added between the street address and the 
city name.

=head1 AUTHOR

Andrew Nelson, C<< <anelson at cpan.org> >>

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

This software is copyright (c) 2011 by Infinity Interactive, Inc..

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut
