# ABSTRACT: Faker Standard Address Provider
package Faker::Provider::Address;

use Faker::Base;

extends 'Faker::Provider';

our $VERSION = '0.12'; # VERSION

method line1 () {
    return $self->process(random => 'line1', number_markers => 1,
        line_markers => 1);
}

method lines () {
    return $self->process(random => 'lines', number_markers => 1,
        line_markers => 1);
}

method number () {
    return $self->process(random => 'number', number_markers => 1);
}

method city_name () {
    return $self->process(random => 'city_name');
}

method city_suffix () {
    return $self->process(random => 'city_suffix');
}

method latitude () {
    my $string = (int(rand(90000000)), int(rand(-90000000)))[rand 2];
       $string =~ s/\d*(\d\d)(\d{6})$/$1.$2/;

    return $string;
}

method longitude () {
    my $string = (int(rand(90000000)), int(rand(-90000000)))[rand 2];
       $string =~ s/\d*(\d\d)(\d{6})$/$1.$2/;

    return $string;
}

method postal_code () {
    return $self->process(random => 'postal_code', number_markers => 1);
}

method street_name () {
    return $self->process(random => 'street_name');
}

method street_suffix () {
    return $self->process(random => 'street_suffix');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Faker::Provider::Address - Faker Standard Address Provider

=head1 VERSION

version 0.12

=head1 SYNOPSIS

    use Faker;
    use Faker::Provider::Address;

    my $faker = Faker->new;
    my $address = Faker::Provider::Address->new(factory => $faker);

    say $address->lines;

=head1 DESCRIPTION

Faker::Provider::Address is a L<Faker> provider which provides fake address
data. B<Note: This is an early release available for testing and feedback and as
such is subject to change.>

=head1 METHODS

=head2 line1

    $address->line1;

    # 5474 Blick Street
    # 5451 Sporer Circle
    # 7642 Larson Avenue

The line1 method generates a random address string containing a random
ficticious building number and street name.

=head2 lines

    $address->lines;

    # 5 Okuneva Avenue, Florineford, 46378
    # 73 Brakus Parkway, Kentonville, 34829
    # 8 Senger Street, Camylleville, 97587

The lines method generates a random address string containing a random
ficticious building number, street name, city, and postal code.

=head2 number

    $address->number;

    # 35
    # 6
    # 1

The number method generates a random ficticious 1, 2, or 4 digit building number.

=head2 city_name

    $address->city_name;

    # Orantown
    # Lilianburg
    # Rodrickford

The city_name method generates a random ficticious city name.

=head2 city_suffix

    $address->city_suffix;

    # town
    # ville
    # town

The city_suffix method generates  a random ficticious city suffix.

=head2 latitude

    $address->latitude;

    # 88.600763
    # 55.138796
    # 2554363

The latitude method generates a random ficticious latitude coordinate.

=head2 longitude

    $address->longitude;

    # -62.811525
    # -89.332889
    # -73.364117

The longitude method generates  a random ficticious longitude coordinate.

=head2 postal_code

    $address->postal_code;

    # 26022-5271
    # 12886
    # 55783-2207

The postal_code method generates a random ficticious postal code.

=head2 street_name

    $address->street_name;

    # Smitham Circle
    # Yundt Street
    # Tromp Parkway

The street_name method generates a random ficticious street name.

=head2 street_suffix

    $address->street_suffix;

    # Circle
    # Avenue
    # Circle

The street_suffix method generates a random ficticious street suffix.

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
