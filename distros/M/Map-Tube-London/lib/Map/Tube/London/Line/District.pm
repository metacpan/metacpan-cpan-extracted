package Map::Tube::London::Line::District;

use strict;
use warnings;
use version;

our $VERSION   = qv('v2.1.0');
our $AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Map::Tube::London::Line::District - London Tube Map: District Line.

=head1 VERSION

Version v2.1.0

=head1 DESCRIPTION

London Tube Map: District Line.

    +-------------------------+-------------------------------------------------+
    | Station Name            | Connected To                                    |
    +-------------------------+-------------------------------------------------+
    | Richmond                | Kew Gardens                                     |
    | Kew Gardens             | Richmond, Gunnersbury                           |
    | Gunnersbury             | Kew Gardens, Ealing Broadway                    |
    | Ealing Broadway         | Gunnerbury, Ealing Common                       |
    | Ealing Common           | Ealing Broadway, Acton Towm                     |
    | Acton Town              | Ealing Common, Chiswick Park                    |
    | Chiswick Park           | Acton Town, Turnham Green                       |
    | Turnham Green           | Chiswick Park, Stamford Brook                   |
    | Stamford Brook          | Turnham Green, Havenscourt Park                 |
    | Ravenscourt Park        | Stamford Brook, Hammersmith                     |
    | Hammersmith             | Ravenscourt Park, Barons Court                  |
    | Barons Court            | Hammersmith, West Kensington                    |
    | West Kensington         | Barons Court, Wimbledon                         |
    | Wimbledon               | West Kensington, Wimbledon Park                 |
    | Wimbledon Park          | Wimbledon, Southfields                          |
    | Southfields             | Wimbledon Park, East Putney                     |
    | East Putney             | Southfields, Putney Bridge                      |
    | Putney Bridge           | East Putney, Parsons Green                      |
    | Parsons Green           | Putney Bridge, Fulham Broadway                  |
    | Fulham Broadway         | Parsons Green, West Brompton                    |
    | West Brompton           | Fulham Broadway, Kensington (Olympia)           |
    | Kensington (Olympia)    | West Brompton, Earl's Court                     |
    | Earl's Court            | Kensington (Olympia), High Street Kensington    |
    | High Street Kensington  | Earl's Court, Notting Hill Gate                 |
    | Notting Hill Gate       | High Street Kensington, Bayswater               |
    | Bayswater               | Notting Hill Gate, Paddington                   |
    | Paddington              | Bayswater, Edgware Road                         |
    | Edgware Road            | Paddington, Gloucester Road                     |
    | Gloucester Road         | Edgware Road, South Kensington                  |
    | South Kensington        | Gloucester Road, Sloane Square                  |
    | Sloane Square           | South Kensington, Victoria                      |
    | Victoria                | Sloane Square, St Jame's Park                   |
    | St James's Park         | Victoria, Westminster                           |
    | Westminster             | St Jame's Park, Embankment                      |
    | Embankment              | Westminster, Temple                             |
    | Temple                  | Embankment, Blackfriars                         |
    | Blackfriars             | Temple, Mansion House                           |
    | Mansion House           | Blackfriars, Cannon Street                      |
    | Cannon Street           | Mansion House, Monument                         |
    | Monument                | Cannon Street, Bank, Tower Hill                 |
    | Tower Hill              | Monument, Aldgate East                          |
    | Aldgate East            | Tower Hill, Whitechapel                         |
    | Whitechapel             | Aldgate East, Stepney Green                     |
    | Stepney Green           | Whitechapel, Mile End                           |
    | Mile End                | Stepney Green, Bow Road                         |
    | Bow Road                | Mile End, Bromley-by-Bow                        |
    | Bromley-by-Bow          | Row Road, West Ham                              |
    | West Ham                | Bromley-by-Bow, Plaistow                        |
    | Plaistow                | West Ham, Upton Park                            |
    | Upton Park              | Plaistow, East Ham                              |
    | East Ham                | Upton Park, Barking                             |
    | Barking                 | East Ham, Becontree                             |
    | Becontree               | Barking, Dagenham Heathway                      |
    | Dagenham Heathway       | Becontree, Dagenham East                        |
    | Dagenham East           | Dagenham Heathway, Elm Park                     |
    | Elm Park                | Dagenham East, Hornchurch                       |
    | Hornchurch              | Elm Park, Upminster Bridge                      |
    | Upminster Bridge        | Hornchurch, Upminster                           |
    | Upminster               | Upminster Bridge                                |
    +-------------------------+-------------------------------------------------+

=head1 NOTE

=over 2

=item * The station "Acton Town" is also part of
          L<Piccadilly Line|Map::Tube::London::Line::Piccadilly>

=item * The station "Aldgate East" is also part of
          L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>

=item * The station "Barking" is also part of
          L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>
        | L<Overground Line|Map::Tube::London::Line::Overground>

=item * The station "Barons Court" is also part of
          L<Piccadilly Line|Map::Tube::London::Line::Piccadilly>

=item * The station "Bayswater" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>

=item * The station "Blackfriars" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>

=item * The station "Bow Road" is also part of
          L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>

=item * The station "Bromley-by-Bow" is also part of
          L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>

=item * The station "Cannon Street" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>

=item * The station "Ealing Broadway" is also part of
          L<Central Line|Map::Tube::London::Line::Central>

=item * The station "Ealing Common" is also part of
          L<Piccadilly Line|Map::Tube::London::Line::Piccadilly>

=item * The station "Earl's Court" is also part of
          L<Piccadilly Line|Map::Tube::London::Line::Piccadilly>

=item * The station "East Ham" is also part of
          L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>

=item * The station "Edgware Road" is also part of
          L<Bakerloo Line|Map::Tube::London::Line::Bakerloo>
        | L<Circle Line|Map::Tube::London::Line::Circle>
        | L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>

=item * The station "Embankment" is also part of
          L<Bakerloo Line|Map::Tube::London::Line::Bakerloo>
        | L<Circle Line|Map::Tube::London::Line::Circle>
        | L<Northern Line|Map::Tube::London::Line::Northern>

=item * The station "Gloucester Road" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>
        | L<Piccadilly Line|Map::Tube::London::Line::Piccadilly>

=item * The station "Gunnersbury" is also part of
          L<Overground Line|Map::Tube::London::Line::Overground>

=item * The station "Hammersmith" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>
        | L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>
        | L<Piccadilly Line|Map::Tube::London::Line::Piccadilly>

=item * The station "High Street Kensington" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>

=item * The station "Kensington (Olympia)" is also part of
          L<Overground Line|Map::Tube::London::Line::Overground>

=item * The station "Mansion House" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>

=item * The station "Mile End" is also part of
          L<Central Line|Map::Tube::London::Line::Central>
        | L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>

=item * The station "Monument" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>

=item * The station "Notting Hill Gate" is also part of
          L<Central Line|Map::Tube::London::Line::Central>
        | L<Circle Line|Map::Tube::London::Line::Circle>

=item * The station "Paddington" is also part of
          L<Bakerloo Line|Map::Tube::London::Line::Bakerloo>
        | L<Circle Line|Map::Tube::London::Line::Circle>
        | L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>

=item * The station "Plaistow" is also part of
          L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>

=item * The station "Richmond" is also part of
          L<Overground Line|Map::Tube::London::Line::Overground>

=item * The station "Sloane Square" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>

=item * The station "South Kensington" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>
        | L<Piccadilly Line|Map::Tube::London::Line::Piccadilly>

=item * The station "St James's Park" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>

=item * The station "Stepney Green" is also part of
          L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>

=item * The station "Temple" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>

=item * The station "Tower Hill" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>

=item * The station "Turnham Green" is also part of
          L<Piccadilly Line|Map::Tube::London::Line::Piccadilly>

=item * The station "Upton Park" is also part of
          L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>

=item * The station "Victoria" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>
        | L<Victoria Line|Map::Tube::London::Line::Victoria>

=item * The station "West Brompton" is also part of
          L<Overground Line|Map::Tube::London::Line::Overground>

=item * The station "West Ham" is also part of
          L<DLR Line|Map::Tube::London::Line::DLR>
        | L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>
        | L<Jubilee Line|Map::Tube::London::Line::Jubilee>

=item * The station "Westminster" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>
        | L<Jubilee Line|Map::Tube::London::Line::Jubilee>

=item * The station "Whitechapel" is also part of
          L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>
        | L<Overground Line|Map::Tube::London::Line::Overground>

=back

=head1 MAP

London Tube Map: L<District Line|https://raw.githubusercontent.com/manwar/Map-Tube-London/master/maps/District.png>
map generated by plugin L<Map::Tube::Plugin::Graph>.

=begin html

<a href = "https://raw.githubusercontent.com/manwar/Map-Tube-London/master/maps/District.png">
<img src    = "https://raw.githubusercontent.com/manwar/Map-Tube-London/master/maps/District.png"
     alt    = "London Tube Map: District Line"
     width  = "400px"
     height = "600px"/>
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

    perldoc Map::Tube::London::Line::District

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

1; # End of Map::Tube::London::Line::District
