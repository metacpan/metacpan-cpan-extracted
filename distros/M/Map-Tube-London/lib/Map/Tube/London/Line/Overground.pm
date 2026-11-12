package Map::Tube::London::Line::Overground;

use strict;
use warnings;
use version;

our $VERSION   = qv('v2.1.0');
our $AUTHORITY = 'cpan:MANWAR';

use 5.006;

=head1 NAME

Map::Tube::London::Line::Overground - London Tube Map: London Overground Line.

=head1 VERSION

Version v2.1.0

=encoding utf8

=head1 DESCRIPTION

London Tube Map: London Overground Line.

    +-----------------------------+---------------------------------------------+
    | Station Name                | Linked To                                   |
    +-----------------------------+---------------------------------------------+
    | Watford Junction            | Watford High Street                         |
    | Watford High Street         | Watford Junction, Bushey                    |
    | Bushey                      | Watford High Street, Carpenders Park        |
    | Carpenders Park             | Bushey, Hatch End                           |
    | Hatch End                   | Carpenders Park, Headstone Lane             |
    | Headstone Lane              | Hatch End, Harrow & Wealdstone              |
    | Harrow & Wealdstone         | Headstone Lane, Kenton                      |
    | Kenton                      | Harrow & Wealdstone,  South Kenton          |
    | South Kenton                | Kenton, North Wembley                       |
    | North Wembley               | South Kenton, Wembley Central               |
    | Wembley Central             | North Wembley, Stonebridge Park             |
    | Stonebridge Park            | Wembley Central, Harlesden                  |
    | Harlesden                   | Stonebridge Park, Willesden Junction        |
    | Willesden Junction          | Harlesden, Kensal Green, Kensal Rise,       |
    |                             | Acton Central, Shepherd's Bush              |
    | Kensal Green                | Willesden Junction, Queen’s Park            |
    | Queen’s Park                | Kensal Green, Kilburn High Road             |
    | Kilburn High Road           | Queen’s Park, South Hampstead               |
    | South Hampstead             | Kilburn High Road, Euston                   |
    | Euston                      | South Hampstead                             |
    | Acton Central               | Willesden Junction, South Acton             |
    | South Acton                 | Acton Central, Gunnersbury                  |
    | Gunnersbury                 | South Acton, Kews Garden                    |
    | Kews Garden                 | Gunnersbury, Richmond                       |
    | Richmond                    | Kews Garden                                 |
    | Shepherd's Bush             | Willesden Junction, Kensington (Olympia)    |
    | Kensington (Olympia)        | Shepherd's Bush, West Brompton              |
    | West Brompton               | Kensington (Olympia), Imperial Wharf        |
    | Imperial Wharf              | West Brompton, Clapham Junction             |
    | Clapham Junction            | Imperial Wharf, Wandsworth Road             |
    | Wandsworth Road             | Clapham Junction, Clapham High Street       |
    | Clapham High Street         | Wandsworth Road, Denmark Hill               |
    | Denmark Hill                | Clapham High Street, Peckham Rye            |
    | Peckham Rye                 | Denmark Hill, Queens Road Peckham           |
    | Queens Road Peckham         | Peckham Rye, Surrey Quays                   |
    | Surrey Quays                | Queens Road Peckham, New Cross, Canada Water|
    | New Cross                   | Surrey Quays                                |
    | New Cross Gate              | Surrey Quays, Brockley                      |
    | Brockley                    | New Cross Gate, Honor Oak Park              |
    | Honor Oak Park              | Brockley, Forest Hill                       |
    | Forest Hill                 | Honor Oak Park, Sydenham                    |
    | Sydenham                    | Forest Hill, Crystal Palace, Penge West     |
    | Crystal Palace              | Sydenham                                    |
    | Penge West                  | Sydenham, Anerley                           |
    | Anerley                     | Penge West, Norwood Junction                |
    | Norwood Junction            | Anerley, West Croydon                       |
    | West Croydon                | Norwood Junction                            |
    | Canada Water                | Surrey Quays, Rotherhithe                   |
    | Rotherhithe                 | Canada Water, Wapping                       |
    | Wapping                     | Rotherhithe, Shadwell                       |
    | Shadwell                    | Wapping, Whitechapel                        |
    | Whitechapel                 | Shadwell, Shoreditch High Street            |
    | Shoreditch High Street      | Whitechapel, Hoxton                         |
    | Hoxton                      | Shoreditch High Street, Haggerston          |
    | Haggerston                  | Hoxton, Dalston Junction                    |
    | Dalston Junction            | Haggerston, Canonbury                       |
    | Canonbury                   | Dalston Junction, Highbury & Islington,     |
    |                             | Dalston Kingsland                           |
    | Highbury & Islington        | Canonbury, Caledonian Road & Barnsbury,     |
    | Caledonian Road & Barnsbury | Highbury & Islington, Camden Road           |
    | Camden Road                 | Caledonian Road & Barnsbury,                |
    |                             | Kentish Town West                           |
    | Kentish Town West           | Camden Road, Gospel Oak                     |
    | Gospel Oak                  | Kentish Town West, Hampstead Heath,         |
    |                             | Upper Holloway                              |
    | Hampstead Heath             | Gospel Oak, Finchley Road & Frognal         |
    | Finchley Road & Frognal     | Hampstead Heath, West Hampstead             |
    | West Hampstead              | Finchley Road & Frognal, Brondesbury        |
    | Brondesbury                 | West Hampstead, Brondesbury Park            |
    | Brondesbury Park            | Brondesbury, Kensal Rise                    |
    | Kensal Rise                 | Brondesbury Park, Willesden Junction        |
    | Upper Holloway              | Gospel Oak, Crouch Hill                     |
    | Crouch Hill                 | Upper Holloway, Harringay Green Lanes       |
    | Harringay Green Lanes       | Crouch Hill, South Tottenham                |
    | South Tottenham             | Harringay Green Lanes, Blackhorse Road      |
    | Blackhorse Road             | South Tottenham, Walthamstow Queen’s Road   |
    | Walthamstow Queen's Road    | Blackhorse Road, Leyton Midland Road        |
    | Leyton Midland Road         | Walthamstow Queen’s Road,                   |
    |                             | Leytonstone High Road                       |
    | Leytonstone High Road       | Leyton Midland Road, Wanstead Park          |
    | Wanstead Park               | Leytonstone High Road. Woodgrange Park      |
    | Woodgrange Park             | Wanstead Park, Barking                      |
    | Barking                     | Woodgrange Park                             |
    | Dalston Kingsland           | Canonbury, Hackney Central                  |
    | Hackney Central             | Dalston Kingsland, Homerton                 |
    | Homerton                    | Hackney Central, Hackney Wick               |
    | Hackney Wick                | Homerton, Stratford                         |
    | Stratford                   | Hackney Wick                                |
    +-----------------------------+---------------------------------------------+

=head1 NOTE

=over 2

=item * The station "Barking" is also part of
          L<District Line|Map::Tube::London::Line::District>
        | L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>

=item * The station "Blackhorse Road" is also part of
          L<Victoria Line|Map::Tube::London::Line::Victoria>

=item * The station "Canada Water" is also part of
          L<Jubilee Line|Map::Tube::London::Line::Jubilee>

=item * The station "Euston" is also part of
          L<Northern Line|Map::Tube::London::Line::Northern>
        | L<Victoria Line|Map::Tube::London::Line::Victoria>

=item * The station "Gunnersbury" is also part of
          L<District Line|Map::Tube::London::Line::District>

=item * The station "Harlesden" is also part of
          L<Bakerloo Line|Map::Tube::London::Line::Bakerloo>

=item * The station "Harrow & Wealdstone" is also part of
          L<Bakerloo Line|Map::Tube::London::Line::Bakerloo>

=item * The station "Highbury & Islington" is also part of
          L<Victoria Line|Map::Tube::London::Line::Victoria>

=item * The station "Kensal Green" is also part of
          L<Bakerloo Line|Map::Tube::London::Line::Bakerloo>

=item * The station "Kensington (Olympia)" is also part of
          L<District Line|Map::Tube::London::Line::District>

=item * The station "Kenton" is also part of
          L<Bakerloo Line|Map::Tube::London::Line::Bakerloo>

=item * The station "North Wembley" is also part of
          L<Bakerloo Line|Map::Tube::London::Line::Bakerloo>

=item * The station "Richmond" is also part of
          L<District Line|Map::Tube::London::Line::District>

=item * The station "Shadwell" is also part of
          L<DLR Line|Map::Tube::London::Line::DLR>

=item * The station "Shepherd's Bush" is also part of
          L<Central Line|Map::Tube::London::Line::Central>

=item * The station "South Kenton" is also part of
          L<Bakerloo Line|Map::Tube::London::Line::Bakerloo>

=item * The station "Stonebridge Park" is also part of
          L<Bakerloo Line|Map::Tube::London::Line::Bakerloo>

=item * The station "Stratford" is also part of
          L<Central Line|Map::Tube::London::Line::Central>
        | L<DLR Line|Map::Tube::London::Line::DLR>
        | L<Jubilee Line|Map::Tube::London::Line::Jubilee>

=item * The station "Wembley Central" is also part of
          L<Bakerloo Line|Map::Tube::London::Line::Bakerloo>

=item * The station "West Brompton" is also part of
          L<District Line|Map::Tube::London::Line::District>

=item * The station "West Hampstead" is also part of
          L<Jubilee Line|Map::Tube::London::Line::Jubilee>

=item * The station "Whitechapel" is also part of
          L<District Line|Map::Tube::London::Line::District>
        | L<Hammersmith & City Line|Map::Tube::London::Line::HammersmithCity>

=item * The station "Willesden Junction" is also part of
          L<Bakerloo Line|Map::Tube::London::Line::Bakerloo>

=back

=head1 MAP

London Tube Map: L<London Overground Line|https://raw.githubusercontent.com/manwar/Map-Tube-London/master/maps/Overground.png>
map generated by plugin L<Map::Tube::Plugin::Graph>.

=begin html

<a href = "https://raw.githubusercontent.com/manwar/Map-Tube-London/master/maps/Overground.png">
<img src    = "https://raw.githubusercontent.com/manwar/Map-Tube-London/master/maps/Overground.png"
     alt    = "London Tube Map: London Overground Line"
     width  = "500px"
     height = "700px"/>
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

    perldoc Map::Tube::London::Line::Overground

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

1; # End of Map::Tube::London::Line::Overground
