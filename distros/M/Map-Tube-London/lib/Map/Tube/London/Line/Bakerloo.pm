package Map::Tube::London::Line::Bakerloo;

use strict;
use warnings;
use version;

our $VERSION   = qv('v2.1.0');
our $AUTHORITY = 'cpan:MANWAR';

use 5.006;

=head1 NAME

Map::Tube::London::Line::Bakerloo - London Tube Map: Bakerloo Line.

=head1 VERSION

Version v2.1.0

=head1 DESCRIPTION

London Tube Map: Bakerloo Line.

    +-----------------------+---------------------------------------------------+
    | Station Name          | Linked To                                         |
    +-----------------------+---------------------------------------------------+
    | Harrow & Wealdstone   | Kenton                                            |
    | Kenton                | Harrow & Wealdstone, South Kenton                 |
    | South Kenton          | Kenton, North Wembley                             |
    | North Wembley         | South Kenton, Wembley Central                     |
    | Wembley Central       | North Wembley, Stonebridge Park                   |
    | Stonebridge Park      | Wembley Central, Harlesden                        |
    | Harlesden             | Stonebridge Park, Willesden Junction              |
    | Willesden Junction    | Harlesden, Kensal Green                           |
    | Kensal Green          | Willesden Junction, Queen's Park                  |
    | Queen's Park          | Kensal Green, Kilburn Park                        |
    | Kilburn Park          | Queen's Park, Maida Vale                          |
    | Maida Vale            | Kilburn Park, Warwick Avenue                      |
    | Warwick Avenue        | Maida Vale, Paddington                            |
    | Paddington            | Warwick Avenue, Edgware Road                      |
    | Edgware Road          | Paddington, Marylebone                            |
    | Marylebone            | Edgware Road, Baker Street                        |
    | Baker Street          | Marylebone, Regent's Park                         |
    | Regent's Park         | Baker Street, Oxford Circus                       |
    | Oxford Circus         | Regent's Park, Picadilly Circus                   |
    | Piccadilly Circus     | Oxford Circus, Charing Cross                      |
    | Charing Cross         | Picadilly Circus, Embankment                      |
    | Embankment            | Charing Cross, Waterloo                           |
    | Waterloo              | Embankment, Lambeth North                         |
    | Lambeth North         | Waterloo, Elephant & Castle                       |
    | Elephant & Castle     | Lambeth North                                     |
    +-----------------------+---------------------------------------------------+

=head1 NOTE

=over 2

=item * The station "Baker Street" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>
        | L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>
        | L<Jubilee Line|Map::Tube::London::Line::Jubilee>
        | L<Metropolitan Line|Map::Tube::London::Line::Metropolitan>

=item * The station "Charing Cross" is also part of
          L<Northern Line|Map::Tube::London::Line::Northern>

=item * The station "Edgware Road" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>
        | L<District Line|Map::Tube::London::Line::District>
        | L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>

=item * The station "Embankment" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>
        | L<District Line|Map::Tube::London::Line::District>
        | L<Northern Line|Map::Tube::London::Line::Northern>

=item * The station "Harlesden" is also part of
          L<Overground Line|Map::Tube::London::Line::Overground>

=item * The station "Harrow & Wealdstone" is also part of
          L<Overground Line|Map::Tube::London::Line::Overground>

=item * The station "Kensal Green" is also part of
          L<Overground Line|Map::Tube::London::Line::Overground>

=item * The station "Kenton" is also part of
          L<Overground Line|Map::Tube::London::Line::Overground>

=item * The station "North Wembley" is also part of
          L<Overground Line|Map::Tube::London::Line::Overground>

=item * The station "Oxford Circus" is also part of
          L<Central Line|Map::Tube::London::Line::Central>
        | L<Victoria Line|Map::Tube::London::Line::Victoria>

=item * The station "Paddington" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>
        | L<District Line|Map::Tube::London::Line::District>
        | L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>

=item * The station "Piccadilly Circus" is also part of
          L<Piccadilly Line|Map::Tube::London::Line::Piccadilly>

=item * The station "South Kenton" is also part of
          L<Overground Line|Map::Tube::London::Line::Overground>

=item * The station "Stonebridge Park" is also part of
          L<Overground Line|Map::Tube::London::Line::Overground>

=item * The station "Waterloo" is also part of
          L<Jubilee Line|Map::Tube::London::Line::Jubilee>
        | L<Northern Line|Map::Tube::London::Line::Northern>
        | L<Waterloo & City Line|Map::Tube::London::Line::WaterlooCity>

=item * The station "Wembley Central" is also part of
          L<Overground Line|Map::Tube::London::Line::Overground>

=item * The station "Willesden Junction" is also part of
          L<Overground Line|Map::Tube::London::Line::Overground>

=back

=head1 MAP

London Tube Map: L<Bakerloo Line|https://raw.githubusercontent.com/manwar/Map-Tube-London/master/maps/Bakerloo.png>
map generated by plugin L<Map::Tube::Plugin::Graph>.

=begin html

<a href = "https://raw.githubusercontent.com/manwar/Map-Tube-London/master/maps/Bakerloo.png">
<img src    = "https://raw.githubusercontent.com/manwar/Map-Tube-London/master/maps/Bakerloo.png"
     alt    = "London Tube Map: Bakerloo Line"
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

    perldoc Map::Tube::London::Line::Bakerloo

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

1; # End of Map::Tube::London::Line::Bakerloo
