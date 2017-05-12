#
# This file is part of Games-Risk
#
# This software is Copyright (c) 2008 by Jerome Quelin.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#
use 5.010;
use strict;
use warnings;

package Games::Risk::Map::Risk;
# ABSTRACT: Risk board map
$Games::Risk::Map::Risk::VERSION = '4.000';
use Moose;
use Games::Risk::I18n qw{ T };
extends 'Games::Risk::Map';


# -- map  builders

sub name   { "risk" }
sub title  { T("Risk") }
sub author { "Yura Mamyrin" }


# -- raw map information

sub _raw_continents {
return (
# id, name, bonus, color
#   0, T('Europe'), 5, blue
[1, T("North America"), 5, "yellow"],
[2, T("South America"), 2, "red"],
[3, T("Europe"), 5, "blue"],
[4, T("Africa"), 3, "orange"],
[5, T("Asia"), 7, "green"],
[6, T("Australia"), 2, "magenta"],
);
}

sub _raw_countries {
return (
# greyscale, name, continent id, x, y, [connections]
#   1, T('Alaska'), 1, 43, 67, [ 1,2,3,38 ]
[1, T("Alaska"), 1, 43, 67, [2, 3, 38]],
[2, T("North West Territory"), 1, 106, 69, [1, 3, 7, 6]],
[3, T("Alberta"), 1, 106, 105, [1, 2, 7, 4]],
[4, T("Western United States"), 1, 109, 149, [3, 7, 5, 9]],
[5, T("Central America"), 1, 118, 205, [4, 9, 10]],
[6, T("Greenland"), 1, 258, 35, [2, 7, 8, 14]],
[7, T("Ontario"), 1, 152, 107, [2, 3, 4, 6, 8, 9]],
[8, T("Quebec"), 1, 206, 110, [6, 7, 9]],
[9, T("Eastern United States"), 1, 160, 159, [4, 5, 7, 8]],
[10, T("Venezuela"), 2, 164, 237, [5, 11, 12]],
[11, T("Peru"), 2, 177, 301, [10, 12, 13]],
[12, T("Brazil"), 2, 216, 284, [10, 11, 13, 21]],
[13, T("Argentina"), 2, 186, 347, [11, 12]],
[14, T("Iceland"), 3, 286, 89, [6, 17, 15]],
[15, T("Scandinavia"), 3, 346, 72, [16, 18, 14, 17]],
[16, T("Ukraine"), 3, 400, 105, [15, 28, 30, 31, 18, 20]],
[17, T("Great Britain"), 3, 289, 118, [14, 18, 19, 15]],
[18, T("Northern Europe"), 3, 336, 129, [15, 16, 17, 19, 20]],
[19, T("Western Europe"), 3, 300, 163, [17, 18, 20, 21]],
[20, T("Southern Europe"), 3, 348, 165, [16, 18, 19, 21, 22, 31]],
[21, T("North Africa"), 4, 313, 246, [12, 19, 20, 22, 23, 24]],
[22, T("Egypt"), 4, 361, 216, [20, 21, 24, 31]],
[23, T("Congo"), 4, 363, 304, [21, 24, 25]],
[24, T("East Africa"), 4, 395, 274, [21, 22, 23, 25, 26]],
[25, T("South Africa"), 4, 369, 369, [23, 24, 26]],
[26, T("Madagascar"), 4, 427, 366, [24, 25]],
[27, T("Siberia"), 5, 500, 58, [28, 29, 34, 35, 36]],
[28, T("Ural"), 5, 470, 97, [16, 27, 29, 30]],
[29, T("China"), 5, 550, 182, [27, 28, 30, 32, 33, 36]],
[30, T("Afghanistan"), 5, 457, 150, [16, 28, 29, 31, 32]],
[31, T("Middle East"), 5, 410, 194, [16, 22, 30, 32, 20]],
[32, T("India"), 5, 496, 222, [29, 30, 31, 33]],
[33, T("Siam"), 5, 556, 242, [29, 32, 39]],
[34, T("Yakutsk"), 5, 565, 62, [27, 35, 38]],
[35, T("Irkutsk"), 5, 554, 107, [27, 34, 36, 38]],
[36, T("Mongolia"), 5, 563, 143, [29, 35, 37, 38, 27]],
[37, T("Japan"), 5, 632, 139, [36, 38]],
[38, T("Kamchatka"), 5, 629, 62, [1, 34 .. 37]],
[39, T("Indonesia"), 6, 585, 297, [33, 41, 40]],
[40, T("New Guinea"), 6, 651, 294, [39, 41, 42]],
[41, T("Western Australia"), 6, 595, 375, [39, 40, 42]],
[42, T("Eastern Australia"), 6, 637, 353, [40, 41]],
);
}


sub _raw_cards {
return (
# type, id_country
#   artillery, 2
#   wildcard
["infantry", 1],
["artillery", 2],
["infantry", 3],
["infantry", 4],
["cavalry", 5],
["cavalry", 6],
["cavalry", 7],
["artillery", 8],
["artillery", 9],
["artillery", 10],
["cavalry", 11],
["artillery", 12],
["infantry", 13],
["infantry", 14],
["artillery", 15],
["artillery", 16],
["cavalry", 17],
["cavalry", 18],
["infantry", 19],
["cavalry", 20],
["infantry", 21],
["infantry", 22],
["cavalry", 23],
["artillery", 24],
["artillery", 25],
["infantry", 26],
["artillery", 27],
["cavalry", 28],
["cavalry", 29],
["infantry", 30],
["artillery", 31],
["infantry", 32],
["artillery", 33],
["cavalry", 34],
["infantry", 35],
["artillery", 36],
["infantry", 37],
["cavalry", 38],
["cavalry", 39],
["cavalry", 40],
["artillery", 41],
["infantry", 42],
["joker", undef],
["joker", undef],
);
}

sub _raw_missions {
return (
# id player to destroy, nb coutnry to occupy + min armies, 3 x id of continents to occupy, description
#   0, 0,0,5,2,0,T("Conquer the continents of ASIA and SOUTH AMERICA.")
#   0, 0,0,3,6,*,T("Conquer the continents of EUROPE and AUSTRALIA and a third continent of your choice.")
#   0,18,2,0,0,0,T("Occupy 18 countries of your choice and occupy each with at least 2 armies.")
#   0,24,1,0,0,0,T("Occupy 24 countries of your choice and occupy each with at least 1 army.")
#   1,24,1,0,0,0,T("Destroy all of PLAYER1's TROOPS. If they are yours or they have already been destroyed by another player then your mission is: Occupy 24 countries.")
[  0,  0,  0,  5,  2,  0,  T("Conquer the continents of Asia and South America."),],
[  0,  0,  0,  3,  6,  "*",  T("Conquer the continents of Europe and Australia and a third continent of your choice."),],
[0, 0, 0, 5, 4, 0, T("Conquer the continents of Asia and Africa.")],
[  0,  0,  0,  3,  2,  "*",  T("Conquer the continents of Europe and South America and a third continent of your choice."),],
[  0,  0,  0,  1,  6,  0,  T("Conquer the continents of North America and Australia."),],
[  0,  0,  0,  1,  4,  0,  T("Conquer the continents of North America and Africa."),],
[  0,  18,  2,  0,  0,  0,  T("Occupy 18 countries of your choice and occupy each with at least 2 armies."),],
[  0,  24,  1,  0,  0,  0,  T("Occupy 24 countries of your choice and occupy each with at least 1 army."),],
[  1,  24,  1,  0,  0,  0,  T("Destroy all of Player1's Troops. If they are yours or they have already been destroyed by another player then your mission is: Occupy 24 countries."),],
[  2,  24,  1,  0,  0,  0,  T("Destroy all of Player2's Troops. If they are yours or they have already been destroyed by another player then your mission is: Occupy 24 countries."),],
[  3,  24,  1,  0,  0,  0,  T("Destroy all of Player3's Troops. If they are yours or they have already been destroyed by another player then your mission is: Occupy 24 countries."),],
[  4,  24,  1,  0,  0,  0,  T("Destroy all of Player4's Troops. If they are yours or they have already been destroyed by another player then your mission is: Occupy 24 countries."),],
[  5,  24,  1,  0,  0,  0,  T("Destroy all of Player5's Troops. If they are yours or they have already been destroyed by another player then your mission is: Occupy 24 countries."),],
[  6,  24,  1,  0,  0,  0,  T("Destroy all of Player6's Troops. If they are yours or they have already been destroyed by another player then your mission is: Occupy 24 countries."),],
);
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Games::Risk::Map::Risk - Risk board map

=head1 VERSION

version 4.000

=head1 DESCRIPTION

Risk Board Map by Yura Mamyrin.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2008 by Jerome Quelin.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
