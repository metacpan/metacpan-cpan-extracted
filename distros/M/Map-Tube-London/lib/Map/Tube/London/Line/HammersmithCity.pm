package Map::Tube::London::Line::HammersmithCity;

use strict;
use warnings;
use version;

our $VERSION   = qv('v2.1.0');
our $AUTHORITY = 'cpan:MANWAR';

use 5.006;

=head1 NAME

Map::Tube::London::Line::HammersmithCity - London Tube Map: Hammersmith & City Line.

=head1 VERSION

Version v2.1.0

=head1 DESCRIPTION

London Tube Map: Hammersmith & City Line.

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
    | Liverpool Street         | Moorgate, Aldgate East                          |
    | Aldgate East             | Liverpool Street, Whitechapel                   |
    | Whitechapel              | Aldgate East, Stepney Green                     |
    | Stepney Green            | Whitechapel, Mile End                           |
    | Mile End                 | Stepney Green, Bow Road                         |
    | Bow Road                 | Mile End, Bromley-by-Bow                        |
    | Bromley-by-Bow           | Bow Road, West Ham                              |
    | West Ham                 | Bromley-by-Bow, Plaistow                        |
    | Plaistow                 | West Ham, Upton Park                            |
    | Upton Park               | Plaistow, East Ham                              |
    | East Ham                 | Upton Park, Barking                             |
    | Barking                  | East Ham                                        |
    +--------------------------+-------------------------------------------------+

=head1 NOTE

=over 2

=item * The station "Aldgate East" is also part of
          L<District Line|Map::Tube::London::Line::District>

=item * The station "Baker Street" is also part of
          L<Bakerloo Line|Map::Tube::London::Line::Bakerloo>
        | L<Circle Line|Map::Tube::London::Line::Circle>
        | L<Jubilee Line|Map::Tube::London::Line::Jubilee>
        | L<Metropolitan Line|Map::Tube::London::Line::Metropolitan>

=item * The station "Barbican" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>
        | L<Metropolitan Line|Map::Tube::London::Line::Metropolitan>

=item * The station "Barking" is also part of
          L<District Line|Map::Tube::London::Line::District>
        | L<Overground Line|Map::Tube::London::Line::Overground>

=item * The station "Bow Road" is also part of
          L<District Line|Map::Tube::London::Line::District>

=item * The station "Bromley-by-Bow" is also part of
          L<District Line|Map::Tube::London::Line::District>

=item * The station "East Ham" is also part of
          L<District Line|Map::Tube::London::Line::District>

=item * The station "Edgware Road" is also part of
          L<Bakerloo Line|Map::Tube::London::Line::Bakerloo>
        | L<Circle Line|Map::Tube::London::Line::Circle>
        | L<District Line|Map::Tube::London::Line::District>

=item * The station "Euston Square" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>
        | L<Metropolitan Line|Map::Tube::London::Line::Metropolitan>

=item * The station "Farringdon" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>
        | L<Metropolitan Line|Map::Tube::London::Line::Metropolitan>

=item * The station "Goldhawk Road" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>

=item * The station "Great Portland Street" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>
        | L<Metropolitan Line|Map::Tube::London::Line::Metropolitan>

=item * The station "Hammersmith" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>
        | L<District Line|Map::Tube::London::Line::District>
        | L<Piccadilly Line|Map::Tube::London::Line::Piccadilly>

=item * The station "King's Cross St Pancras" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>
        | L<Metropolitan Line|Map::Tube::London::Line::Metropolitan>
        | L<Northern Line|Map::Tube::London::Line::Northern>
        | L<Piccadilly Line|Map::Tube::London::Line::Piccadilly>
        | L<Victoria Line|Map::Tube::London::Line::Victoria>

=item * The station "Ladbroke Grove" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>

=item * The station "Latimer Road" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>

=item * The station "Liverpool Street" is also part of
          L<Central Line|Map::Tube::London::Line::Central>
        | L<Circle Line|Map::Tube::London::Line::Circle>
        | L<Metropolitan Line|Map::Tube::London::Line::Metropolitan>

=item * The station "Mile End" is also part of
          L<Central Line|Map::Tube::London::Line::Central>
        | L<District Line|Map::Tube::London::Line::District>

=item * The station "Moorgate" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>
        | L<Metropolitan Line|Map::Tube::London::Line::Metropolitan>
        | L<Northern Line|Map::Tube::London::Line::Northern>

=item * The station "Paddington" is also part of
          L<Bakerloo Line|Map::Tube::London::Line::Bakerloo>
        | L<Circle Line|Map::Tube::London::Line::Circle>
        | L<District Line|Map::Tube::London::Line::District>

=item * The station "Plaistow" is also part of
          L<District Line|Map::Tube::London::Line::District>

=item * The station "Royal Oak" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>

=item * The station "Shepherd's Bush Market" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>

=item * The station "Stepney Green" is also part of
          L<District Line|Map::Tube::London::Line::District>

=item * The station "Upton Park" is also part of
          L<District Line|Map::Tube::London::Line::District>

=item * The station "West Ham" is also part of
          L<DLR Line|Map::Tube::London::Line::Dlr>
        | L<District Line|Map::Tube::London::Line::District>
        | L<Jubilee Line|Map::Tube::London::Line::Jubilee>

=item * The station "Westbourne Park" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>

=item * The station "Whitechapel" is also part of
          L<District Line|Map::Tube::London::Line::District>
        | L<Overground Line|Map::Tube::London::Line::Overground>

=item * The station "Wood Lane" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>

=back

=head1 MAP

London Tube Map: L<Hammersmith & City Line|https://raw.githubusercontent.com/manwar/Map-Tube-London/master/maps/HammersmithCity.png>
map generated by plugin L<Map::Tube::Plugin::Graph>.

=begin html

<a href = "https://raw.githubusercontent.com/manwar/Map-Tube-London/master/maps/HammersmithCity.png">
<img src    = "https://raw.githubusercontent.com/manwar/Map-Tube-London/master/maps/HammersmithCity.png"
     alt    = "London Tube Map: Hammersmith & City Line"
     width  = "500px"
     height = "500px"/>
</a>

=end html

=head1 AUTHOR

Mohammad Sajid Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Map-Tube-London>

=head1 BUGS

Please report any bugs or feature requests through the web interface at L<https://github.com/manwar/Map-Tube-London/issues>.
I will  be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Map::Tube::London::Line::HammersmithCity

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

1; # End of Map::Tube::London::Line::HammersmithCity
