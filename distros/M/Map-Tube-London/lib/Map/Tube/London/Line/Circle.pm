package Map::Tube::London::Line::Circle;

use strict;
use warnings;
use version;

our $VERSION   = qv('v2.1.0');
our $AUTHORITY = 'cpan:MANWAR';

use 5.006;

=head1 NAME

Map::Tube::London::Line::Circle - London Tube Map: Circle Line.

=head1 VERSION

Version v2.1.0

=head1 DESCRIPTION

London Tube Map: Circle Line.

    +--------------------------+-------------------------------------------------+
    | Station Name             | Connected To                                    |
    +--------------------------+-------------------------------------------------+
    | Hammersmith              | Goldhawk Road                                   |
    | Goldhawk Road            | Hammersmith, Shepherd's Bush Market             |
    | Shepherd's Bush Market   | Goldhawk Road, Wood Lane                        |
    | Wood Lane                | Shepherd's Bush Market, Latimer Road            |
    | Latimer Road             | Wood Lane, Ladbroke Grove                       |
    | Ladbroke Grove           | Latimer Road, Westbourne Park                   |
    | Westbourne Park          | Ladbroke Grove, Royal Oak                       |
    | Royal Oak                | Westbourne Park, Paddington                     |
    | Paddington               | Royal Oak, Edgware Road                         |
    | Edgware Road             | Paddington, Baker Street                        |
    | Baker Street             | Edgware Road, Great Portland Street             |
    | Great Portland Street    | Baker Street, Euston Square                     |
    | Euston Square            | Great Portland Street, King's Cross St Pancras |
    | King's Cross St Pancras  | Euston Square, Farringdon                       |
    | Farringdon               | King's Cross St Pancras, Barbican              |
    | Barbican                 | Farringdon, Moorgate                            |
    | Moorgate                 | Barbican, Liverpool Street                      |
    | Liverpool Street         | Moorgate, Aldgate                               |
    | Aldgate                  | Liverpool Street, Tower Hill                    |
    | Tower Hill               | Aldgate, Monument                               |
    | Monument                 | Tower Hill, Bank, Cannon Street                 |
    | Cannon Street            | Monument, Mansion House                         |
    | Mansion House            | Cannon Street, Blackfriars                      |
    | Blackfriars              | Mansion House, Temple                           |
    | Temple                   | Blackfriars, Embankment                         |
    | Embankment               | Temple, Westminster                             |
    | Westminster              | Embankment, St Jame's Park                      |
    | St James's Park          | Westminster, Victoria                           |
    | Victoria                 | St James's Park, Sloane Square                   |
    | Sloane Square            | Victoria, South Kensington                      |
    | South Kensington         | Sloane Square, Gloucester Road                  |
    | Gloucester Road          | South Kensington, High Street Kensington        |
    | High Street Kensington   | Gloucester Road, Notting Hill Gate              |
    | Notting Hill Gate        | High Street Kensington, Bayswater               |
    | Bayswater                | Notting Hill Gate                               |
    +--------------------------+-------------------------------------------------+

=head1 NOTE

=over 2

=item * The station "Aldgate" is also part of
          L<Metropolitan Line|Map::Tube::London::Line::Metropolitan>

=item * The station "Baker Street" is also part of
          L<Bakerloo Line|Map::Tube::London::Line::Bakerloo>
        | L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>
        | L<Jubilee Line|Map::Tube::London::Line::Jubilee>
        | L<Metropolitan Line|Map::Tube::London::Line::Metropolitan>

=item * The station "Barbican" is also part of
          L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>
        | L<Metropolitan Line|Map::Tube::London::Line::Metropolitan>

=item * The station "Bayswater" is also part of
          L<District Line|Map::Tube::London::Line::District>

=item * The station "Blackfriars" is also part of
          L<District Line|Map::Tube::London::Line::District>

=item * The station "Cannon Street" is also part of
          L<District Line|Map::Tube::London::Line::District>

=item * The station "Edgware Road" is also part of
          L<Bakerloo Line|Map::Tube::London::Line::Bakerloo>
        | L<District Line|Map::Tube::London::Line::District>
        | L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>

=item * The station "Embankment" is also part of
          L<Bakerloo Line|Map::Tube::London::Line::Bakerloo>
        | L<District Line|Map::Tube::London::Line::District>
        | L<Northern Line|Map::Tube::London::Line::Northern>

=item * The station "Euston Square" is also part of
          L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>
        | L<Metropolitan Line|Map::Tube::London::Line::Metropolitan>

=item * The station "Farringdon" is also part of
          L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>
        | L<Metropolitan Line|Map::Tube::London::Line::Metropolitan>

=item * The station "Gloucester Road" is also part of
          L<District Line|Map::Tube::London::Line::District>
        | L<Piccadilly Line|Map::Tube::London::Line::Piccadilly>

=item * The station "Goldhawk Road" is also part of
          L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>

=item * The station "Great Portland Street" is also part of
          L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>
        | L<Metropolitan Line|Map::Tube::London::Line::Metropolitan>

=item * The station "Hammersmith" is also part of
          L<District Line|Map::Tube::London::Line::District>
        | L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>
        | L<Piccadilly Line|Map::Tube::London::Line::Piccadilly>

=item * The station "High Street Kensington" is also part of
          L<District Line|Map::Tube::London::Line::District>

=item * The station "King's Cross St Pancras" is also part of
          L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>
        | L<Metropolitan Line|Map::Tube::London::Line::Metropolitan>
        | L<Northern Line|Map::Tube::London::Line::Northern>
        | L<Piccadilly Line|Map::Tube::London::Line::Piccadilly>
        | L<Victoria Line|Map::Tube::London::Line::Victoria>

=item * The station "Ladbroke Grove" is also part of
          L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>

=item * The station "Latimer Road" is also part of
          L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>

=item * The station "Liverpool Street" is also part of
          L<Central Line|Map::Tube::London::Line::Central>
        | L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>
        | L<Metropolitan Line|Map::Tube::London::Line::Metropolitan>

=item * The station "Mansion House" is also part of
          L<District Line|Map::Tube::London::Line::District>

=item * The station "Monument" is also part of
          L<District Line|Map::Tube::London::Line::District>

=item * The station "Moorgate" is also part of
          L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>
        | L<Metropolitan Line|Map::Tube::London::Line::Metropolitan>
        | L<Northern Line|Map::Tube::London::Line::Northern>

=item * The station "Notting Hill Gate" is also part of
          L<Central Line|Map::Tube::London::Line::Central>
        | L<District Line|Map::Tube::London::Line::District>

=item * The station "Paddington" is also part of
          L<Bakerloo Line|Map::Tube::London::Line::Bakerloo>
        | L<District Line|Map::Tube::London::Line::District>
        | L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>

=item * The station "Royal Oak" is also part of
          L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>

=item * The station "Shepherd's Bush Market" is also part of
          L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>

=item * The station "Sloane Square" is also part of
          L<District Line|Map::Tube::London::Line::District>

=item * The station "South Kensington" is also part of
          L<District Line|Map::Tube::London::Line::District>
        | L<Piccadilly Line|Map::Tube::London::Line::Piccadilly>

=item * The station "St James's Park" is also part of
          L<District Line|Map::Tube::London::Line::District>

=item * The station "Temple" is also part of
          L<District Line|Map::Tube::London::Line::District>

=item * The station "Tower Hill" is also part of
          L<District Line|Map::Tube::London::Line::District>

=item * The station "Victoria" is also part of
          L<District Line|Map::Tube::London::Line::District>
        | L<Victoria Line|Map::Tube::London::Line::Victoria>

=item * The station "Westbourne Park" is also part of
          L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>

=item * The station "Westminster" is also part of
          L<District Line|Map::Tube::London::Line::District>
        | L<Jubilee Line|Map::Tube::London::Line::Jubilee>

=item * The station "Wood Lane" is also part of
          L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>

=back

=head1 MAP

London Tube Map: L<Circle Line|https://raw.githubusercontent.com/manwar/Map-Tube-London/master/maps/Circle.png>
map generated by plugin L<Map::Tube::Plugin::Graph>.

=begin html

<a href = "https://raw.githubusercontent.com/manwar/Map-Tube-London/master/maps/Circle.png">
<img src    = "https://raw.githubusercontent.com/manwar/Map-Tube-London/master/maps/Circle.png"
     alt    = "London Tube Map: Circle Line"
     width  = "300px"
     height = "600px"/>
</a>

=end html

=head1 AUTHOR

Mohammad Sajid Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/Manwar/Map-Tube-London>

=head1 BUGS

Please report any bugs or feature requests through the web interface at L<https://github.com/manwar/Map-Tube-London/issues>.
I will  be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Map::Tube::London::Line::Circle

You can also look for information at:

=over 4

=item * BUG Report

L<https://github.com/manwar/Map-Tube-London/issues>

=item * Search MetaCPAN

L<https://metacpan.org/dist/Map-Tube-London>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 - 2026 Mohammad Sajid Anwar.

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License (2.0).

=cut

1; # End of Map::Tube::London::Line::Circle
