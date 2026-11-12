package Map::Tube::London::Line::Jubilee;

use strict;
use warnings;
use version;

our $VERSION   = qv('v2.1.0');
our $AUTHORITY = 'cpan:MANWAR';

use 5.006;

=head1 NAME

Map::Tube::London::Line::Jubilee - London Tube Map: Jubilee Line.

=head1 VERSION

Version v2.1.0

=head1 DESCRIPTION

London Tube Map: Jubilee Line.

    +------------------+--------------------------------------------------------+
    | Station Name     | Connected To                                           |
    +------------------+--------------------------------------------------------+
    | Stanmore         | Cannons Park                                           |
    | Canons Park      | Stanmore, Queenbury                                    |
    | Queensbury       | Cannons Park, Kingsbury                                |
    | Kingsbury        | Queensbury, Wembley Park                               |
    | Wembley Park     | Kingsbury, Neasden                                     |
    | Neasden          | Wembley Park, Dollis Hill                              |
    | Dollis Hill      | Neasden, Willesden Green                               |
    | Willesden Green  | Dollis Hill, Kilburn                                   |
    | Kilburn          | Willesden Green, West Hampstead                        |
    | West Hampstead   | Kilburn, Finchley Road                                 |
    | Finchley Road    | West Hampstead, Swiss Cottage                          |
    | Swiss Cottage    | Finchley Road, St. John's Wood                         |
    | St. John's Wood  | Swiss Cottage, Baker Street                            |
    | Baker Street     | St. John's Wood, Bond Street                           |
    | Bond Street      | Baker Street, Green Park                               |
    | Green Park       | Bond Street, Westminster                               |
    | Westminster      | Green Park, Waterloo                                   |
    | Waterloo         | Westminster, Southwark                                 |
    | Southwark        | Waterloo, London Bridge                                |
    | London Bridge    | Southwark, Bermondsey                                  |
    | Bermondsey       | London Bridge, Canada Water                            |
    | Canada Water     | Bermondsey, Canary Wharf                               |
    | Canary Wharf     | Canada Water, North Greenwich                          |
    | North Greenwich  | Canary Wharf, Canning Town                             |
    | Canning Town     | North Greenwich, West Ham                              |
    | West Ham         | Canning Town, Stratford                                |
    | Stratford        | West Ham                                               |
    +------------------+--------------------------------------------------------+

=head1 NOTE

=over 2

=item * The station "Baker Street" is also part of
          L<Bakerloo Line|Map::Tube::London::Line::Bakerloo>
        | L<Circle Line|Map::Tube::London::Line::Circle>
        | L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>
        | L<Metropolitan Line|Map::Tube::London::Line::Metropolitan>

=item * The station "Bond Street" is also part of
          L<Central Line|Map::Tube::London::Line::Central>

=item * The station "Canada Water" is also part of
          L<Overground Line|Map::Tube::London::Line::Overground>

=item * The station "Canary Wharf" is also part of
          L<DLR Line|Map::Tube::London::Line::Dlr>

=item * The station "Canning Town" is also part of
          L<DLR Line|Map::Tube::London::Line::Dlr>

=item * The station "Finchley Road" is also part of
          L<Metropolitan Line|Map::Tube::London::Line::Metropolitan>

=item * The station "Green Park" is also part of
          L<Piccadilly Line|Map::Tube::London::Line::Piccadilly>
        | L<Victoria Line|Map::Tube::London::Line::Victoria>

=item * The station "London Bridge" is also part of
          L<Northern Line|Map::Tube::London::Line::Northern>

=item * The station "Stratford" is also part of
          L<Central Line|Map::Tube::London::Line::Central>
        | L<DLR Line|Map::Tube::London::Line::Dlr>
        | L<Overground Line|Map::Tube::London::Line::Overground>

=item * The station "Waterloo" is also part of
          L<Bakerloo Line|Map::Tube::London::Line::Bakerloo>
        | L<Northern Line|Map::Tube::London::Line::Northern>
        | L<Waterloo & City Line|Map::Tube::London::Line::WaterlooCity>

=item * The station "Wembley Park" is also part of
          L<Metropolitan Line|Map::Tube::London::Line::Metropolitan>

=item * The station "West Ham" is also part of
          L<DLR Line|Map::Tube::London::Line::Dlr>
        | L<District Line|Map::Tube::London::Line::District>
        | L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>

=item * The station "West Hampstead" is also part of
          L<Overground Line|Map::Tube::London::Line::Overground>

=item * The station "Westminster" is also part of
          L<Circle Line|Map::Tube::London::Line::Circle>
        | L<District Line|Map::Tube::London::Line::District>

=back

=head1 MAP

London Tube Map: L<Jubilee Line|https://raw.githubusercontent.com/manwar/Map-Tube-London/master/maps/Jubilee.png>
map generated by plugin L<Map::Tube::Plugin::Graph>.

=begin html

<a href = "https://raw.githubusercontent.com/manwar/Map-Tube-London/master/maps/Jubilee.png">
<img src    = "https://raw.githubusercontent.com/manwar/Map-Tube-London/master/maps/Jubilee.png"
     alt    = "London Tube Map: Jubilee Line"
     width  = "600px"
     height = "400px"/>
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

    perldoc Map::Tube::London::Line::Jubilee

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

1; # End of Map::Tube::London::Line::Jubilee
