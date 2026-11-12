package Map::Tube::London::Line::Piccadilly;

use strict;
use warnings;
use version;

our $VERSION   = qv('v2.1.0');
our $AUTHORITY = 'cpan:MANWAR';

use 5.006;

=head1 NAME

Map::Tube::London::Line::Piccadilly - London Tube Map: Piccadilly Line.

=head1 VERSION

Version v2.1.0

=head1 DESCRIPTION

London Tube Map: Piccadilly Line.

    +---------------------------+-----------------------------------------------+
    | Station Name              | Connected To                                  |
    +---------------------------+-----------------------------------------------+
    | Uxbridge                  | Hillingdon                                    |
    | Hillingdon                | Uxbridge, Ickenham                            |
    | Ickenham                  | Hillingdon, Ruislip                           |
    | Ruislip                   | Ickenham, Ruislip Manor                       |
    | Ruislip Manor             | Ruislip, Eastcote                             |
    | Eastcote                  | Ruislip Manor, Rayners Lane                   |
    | Rayners Lane              | Eastcote, South Harrow                        |
    | South Harrow              | Rayners Lane, Sudbury Hill                    |
    | Sudbury Hill              | South Harrow, Sudbury Town                    |
    | Sudbury Town              | Sudbury Hill, Alperton                        |
    | Alperton                  | Sudbury Town, Park Royal                      |
    | Park Royal                | Alperton, North Ealing                        |
    | North Ealing              | Park Royal, Ealing Common                     |
    | Ealing Common             | North Ealing, Acton Town                      |
    | Acton Town                | Ealing Common, South Ealing, Turnham Green    |
    | South Ealing              | Acton Town, Northfields                       |
    | Northfields               | South Ealing, Boston Manor                    |
    | Boston Manor              | Northfields, Osterley                         |
    | Osterley                  | Boston Manor, Hounslow East                   |
    | Hounslow East             | Osterley, Hounslow Central                    |
    | Hounslow Central          | Hounslow East, Hounslow West                  |
    | Hounslow West             | Hounslow Central, Hatton Cross                |
    | Hatton Cross              | Hounslow West, Heathrow Terminal 4,           |
    | Heathrow Terminal 4       | Heathrow Terminal 5                           |
    | Heathrow Terminal 5       | Heathrow Terminal 1,2,3                       |
    | Heathrow Terminal 1,2,3   | Hatton Cross                                  |
    | Turnham Green             | Acton Town, Hammersmith                       |
    | Hammersmith               | Turnham Green, Barons Court                   |
    | Barons Court              | Hammersmith, Earl's Court                     |
    | Earl's Court              | Barons Court, Gloucester Road                 |
    | Gloucester Road           | Earl's Court, South Kensington                |
    | South Kensington          | Gloucester Road, Knightsbridge                |
    | Knightsbridge             | South Kensington, Hyde Park Corner            |
    | Hyde Park Corner          | Knightsbridge, Green Park                     |
    | Green Park                | Hyde Park Corner, Piccadilly Circus           |
    | Piccadilly Circus         | Green Park, Leicester Square                  |
    | Leicester Square          | Piccadilly Circus, Covent Garden              |
    | Covent Garden             | Leicester Square, Holborn                     |
    | Holborn                   | Covent Garden, Russell Square                 |
    | Russell Square            | Holborn, King's Square St Pancras            |
    | King's Square St Pancras  | Russell Square, Caledonian Road               |
    | Caledonian Road           | King's Square St Pancras, Holloway Road      |
    | Holloway Road             | Caledonian Road, Arsenal                      |
    | Arsenal                   | Holloway Road, Finsbury Park                  |
    | Finsbury Park             | Arsenal, Manor House                          |
    | Manor House               | Finsbury Park, Turnpike Lane                  |
    | Turnpike Lane             | Manor House, Wood Green                       |
    | Wood Green                | Turnpike Lane, Bounds Green                   |
    | Bounds Green              | Wood Green, Arnos Grove                       |
    | Arnos Grove               | Bounds Green, Southgate                       |
    | Southgate                 | Arnos Grove, Oakwood                          |
    | Oakwood                   | Southgate, Cockfosters                        |
    | Cockfosters               | Oakwood                                       |
    +---------------------------+-----------------------------------------------+

=head1 NOTE

=over 2

=item * The station "Acton Town" is also part of
          L<District Line|Map::Tube::London::Line::District>

=item * The station "Barons Court" is also part of
          L<District Line|Map::Tube::London::Line::District>

=item * The station "Ealing Common" is also part of
          L<District Line|Map::Tube::London::Line::District>

=item * The station "Earl's Court" is also part of
          L<District Line|Map::Tube::London::Line::District>

=item * The station "Eastcote" is also part of
          L<Metropolitan Line|Map::Tube::London::Line::Metropolitan>

=item * The station "Finsbury Park" is also part of
          L<Victoria Line|Map::Tube::London::Line::Victoria>

=item * The station "Gloucester Road" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>
        | L<District Line|Map::Tube::London::Line::District>

=item * The station "Green Park" is also part of
          L<Jubilee Line|Map::Tube::London::Line::Jubilee>
        | L<Victoria Line|Map::Tube::London::Line::Victoria>

=item * The station "Hammersmith" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>
        | L<District Line|Map::Tube::London::Line::District>
        | L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>

=item * The station "Hillingdon" is also part of
          L<Metropolitan Line|Map::Tube::London::Line::Metropolitan>

=item * The station "Holborn" is also part of
          L<Central Line|Map::Tube::London::Line::Central>

=item * The station "Ickenham" is also part of
          L<Metropolitan Line|Map::Tube::London::Line::Metropolitan>

=item * The station "King's Cross St Pancras" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>
        | L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>
        | L<Metropolitan Line|Map::Tube::London::Line::Metropolitan>
        | L<Northern Line|Map::Tube::London::Line::Northern>
        | L<Victoria Line|Map::Tube::London::Line::Victoria>

=item * The station "Leicester Square" is also part of
          L<Northern Line|Map::Tube::London::Line::Northern>

=item * The station "Piccadilly Circus" is also part of
          L<Bakerloo Line|Map::Tube::London::Line::Bakerloo>

=item * The station "Rayners Lane" is also part of
          L<Metropolitan Line|Map::Tube::London::Line::Metropolitan>

=item * The station "Ruislip" is also part of
          L<Metropolitan Line|Map::Tube::London::Line::Metropolitan>

=item * The station "Ruislip Manor" is also part of
          L<Metropolitan Line|Map::Tube::London::Line::Metropolitan>

=item * The station "South Kensington" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>
        | L<District Line|Map::Tube::London::Line::District>

=item * The station "Turnham Green" is also part of
          L<District Line|Map::Tube::London::Line::District>

=item * The station "Uxbridge" is also part of
          L<Metropolitan Line|Map::Tube::London::Line::Metropolitan>

=back

=head1 MAP

London Tube Map: L<Piccadilly Line|https://raw.githubusercontent.com/manwar/Map-Tube-London/master/maps/Piccadilly.png>
map generated by plugin L<Map::Tube::Plugin::Graph>.

=begin html

<a href = "https://raw.githubusercontent.com/manwar/Map-Tube-London/master/maps/Piccadilly.png">
<img src    = "https://raw.githubusercontent.com/manwar/Map-Tube-London/master/maps/Piccadilly.png"
     alt    = "London Tube Map: Piccadilly Line"
     width  = "400px"
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

    perldoc Map::Tube::London::Line::Piccadilly

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

1; # End of Map::Tube::London::Line::Piccadilly
