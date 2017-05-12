#
# This file is part of Games-Risk-ExtraMaps-Imaginary
#
# This software is Copyright (c) 2011 by Jerome Quelin.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#
use 5.010;
use strict;
use warnings;

package Games::Risk::Map::Risk2210;
{
  $Games::Risk::Map::Risk2210::VERSION = '3.113460';
}
# ABSTRACT: Risk 2210 Map

use Moose;
extends 'Games::Risk::Map';


use Locale::Messages   qw{ :locale_h bind_textdomain_filter turn_utf_8_on };
use Locale::TextDomain "Games-Risk-Map-Risk2210";
use Moose;

extends 'Games::Risk::ExtraMaps::Imaginary';

my $domain ="Games-Risk-Map-Risk2210";
bindtextdomain $domain, __PACKAGE__->localedir->stringify;
bind_textdomain_codeset $domain, "utf-8";
bind_textdomain_filter  $domain, sub { turn_utf_8_on($_[0]) };


# -- map  builders

sub name   { "risk2210" }
sub title  { __("Risk 2210 Map") }
sub author { "Matthias Kuehl" }


# -- raw map information

sub _raw_continents {
return (
# id, name, bonus, color
#   0, __('Europe'), 5, blue
[1, __("North America"), 5, "yellow"],
[2, __("South America"), 2, "red"],
[3, __("Europe"), 5, "blue"],
[4, __("Africa"), 3, "orange"],
[5, __("Asia"), 7, "green"],
[6, __("Australia"), 2, "magenta"],
[7, __("Asia Pacific"), 1, "yellow"],
[8, __("US Pacific"), 2, "blue"],
[9, __("North Atlantic"), 2, "red"],
[10, __("South Atlantic"), 1, "green"],
[11, __("Indian"), 2, "orange"],
);
}

sub _raw_countries {
return (
# greyscale, name, continent id, x, y, [connections]
#   1, __('Alaska'), 1, 43, 67, [ 1,2,3,38 ]
[1, __("Northwestern Oil Emirate"), 1, 47, 19, [2, 4, 38]],
[2, __("Nunavut"), 1, 105, 23, [1, 4, 5, 3]],
[3, __("Exiled States of America"), 1, 222, 23, [2, 6, 14]],
[4, __("Alberta"), 1, 85, 57, [1, 2, 5, 7]],
[5, __("Canada"), 1, 125, 67, [2, 4, 6, 7, 8]],
[6, __("Republique du Quebec"), 1, 175, 75, [3, 5, 8]],
[7, __("Continental Biospheres"), 1, 80, 100, [4, 5, 8, 9, 45]],
[8, __("American Republic"), 1, 117, 121, [5, 6, 7, 9, 49]],
[9, __("Mexico"), 1, 81, 161, [7, 8, 10]],
[10, __("Nuevo Timoto"), 2, 115, 216, [9, 11, 12, 47]],
[11, __("Andean Nations"), 2, 94, 257, [10, 12, 13]],
[12, __("Amazon Desert"), 2, 145, 265, [10, 11, 13, 21, 50, 51]],
[13, __("Argentina"), 2, 90, 325, [11, 12]],
[14, __("Iceland GRC"), 3, 268, 47, [3, 17, 15]],
[15, __("Jotenheim"), 3, 328, 28, [16, 18, 14, 17]],
[16, __("Ukrayina"), 3, 412, 70, [15, 28, 30, 31, 18, 20]],
[17, __("New Avalon"), 3, 272, 84, [14, 18, 19, 15, 48]],
[18, __("Warsaw Republic"), 3, 333, 89, [15, 16, 17, 19, 20]],
[19, __("Andorra"), 3, 270, 132, [17, 18, 20, 21]],
[  20,  __("Imperial Balkania"),  3,  340,  116,  [16, 18, 19, 21, 22, 31],],
[  21,  __("Saharan Empire"),  4,  280,  211,  [12, 19, 20, 22, 23, 24, 52],],
[22, __("Egypt"), 4, 350, 180, [20, 21, 24, 31]],
[23, __("Zaire Military Zone"), 4, 349, 274, [21, 24, 25]],
[24, __("Ministry of Djibouti"), 4, 395, 245, [21, 22, 23, 25, 26]],
[25, __("Lesotho"), 4, 357, 347, [23, 24, 26]],
[26, __("Madagascar"), 4, 417, 332, [24, 25, 54]],
[27, __("Siberia"), 5, 520, 32, [28, 29, 34, 35, 36]],
[28, __("Enclave of the Bear"), 5, 475, 65, [16, 27, 29, 30]],
[29, __("Hong Kong"), 5, 555, 145, [27, 28, 30, 32, 33, 36, 44]],
[30, __("Afghanistan"), 5, 466, 117, [16, 28, 29, 31, 32]],
[31, __("Middle East"), 5, 427, 179, [16, 22, 30, 32, 20]],
[32, __("United Indiastan"), 5, 511, 189, [29, 30, 31, 33, 53]],
[33, __("Angkhor Wat"), 5, 577, 207, [29, 32, 39]],
[34, __("Sakha"), 5, 580, 23, [27, 35, 38]],
[35, __("Alden"), 5, 570, 70, [27, 34, 36, 38]],
[  36,  __("Khan Industrial State"),  5,  577,  107,  [29, 35, 37, 38, 27],],
[37, __("Japan"), 5, 650, 114, [36, 38, 44]],
[38, __("Pevek"), 5, 630, 26, [1, 34 .. 37]],
[39, __("Java Cartel"), 6, 605, 270, [33, 41, 40, 43]],
[40, __("New Guinea"), 6, 660, 284, [39, 41, 42]],
[41, __("Aboriginal League"), 6, 595, 365, [39, 40, 42, 55]],
[42, __("Australian Testing Ground"), 6, 650, 352, [40, 41]],
[43, __("Sung Tzu"), 7, 652, 228, [39, 44]],
[44, __("Neo Tokyo"), 7, 648, 172, [29, 37, 43, 47]],
[45, __("Poseidon"), 8, 31, 88, [7, 46]],
[46, __("Hawaiian Preserve"), 8, 33, 145, [45, 47]],
[47, __("New Atlantis"), 8, 49, 198, [10, 44, 46]],
[48, __("Western Ireland"), 9, 217, 133, [17, 49]],
[49, __("New York"), 9, 163, 159, [8, 48, 50]],
[50, __("Nova Brasilia"), 9, 187, 212, [12, 49]],
[51, __("Neo Paulo"), 10, 206, 307, [12, 52]],
[52, __("The Ivory Reef"), 10, 269, 293, [21, 51]],
[53, __("South Ceylon"), 11, 483, 268, [32, 54]],
[54, __("Microcorp"), 11, 473, 327, [26, 53, 55]],
[55, __("Akara"), 11, 527, 359, [41, 54]],
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
["artillery", 43],
["artillery", 44],
["infantry", 45],
["artillery", 46],
["cavalry", 47],
["cavalry", 48],
["infantry", 49],
["artillery", 50],
["infantry", 51],
["artillery", 52],
["cavalry", 53],
["infantry", 54],
["infantry", 55],
["joker", undef],
["joker", undef],
);
}

sub _raw_missions {
return (
# id player to destroy, nb coutnry to occupy + min armies, 3 x id of continents to occupy, description
#   0, 0,0,5,2,0,__("Conquer the continents of ASIA and SOUTH AMERICA.")
#   0, 0,0,3,6,*,__("Conquer the continents of EUROPE and AUSTRALIA and a third continent of your choice.")
#   0,18,2,0,0,0,__("Occupy 18 countries of your choice and occupy each with at least 2 armies.")
#   0,24,1,0,0,0,__("Occupy 24 countries of your choice and occupy each with at least 1 army.")
#   1,24,1,0,0,0,__("Destroy all of PLAYER1's TROOPS. If they are yours or they have already been destroyed by another player then your mission is: Occupy 24 countries.")
[  0,  0,  0,  5,  2,  0,  __("Conquer the continents of Asia and South America."),],
[  0,  0,  0,  3,  6,  "*",  __("Conquer the continents of Europe and Australia and a third continent of your choice."),],
[0, 0, 0, 5, 4, 0, __("Conquer the continents of Asia and Africa.")],
[  0,  0,  0,  3,  2,  "*",  __("Conquer the continents of Europe and South America and a third continent of your choice."),],
[  0,  0,  0,  1,  6,  0,  __("Conquer the continents of North America and Australia."),],
[  0,  0,  0,  1,  4,  0,  __("Conquer the continents of North America and Africa."),],
[  0,  18,  2,  0,  0,  0,  __("Occupy 18 countries of your choice and occupy each with at least 2 armies."),],
[  0,  24,  1,  0,  0,  0,  __("Occupy 24 countries of your choice and occupy each with at least 1 army."),],
[  1,  24,  1,  0,  0,  0,  __("Destroy all of Player1's Troops. If they are yours or they have already been destroyed by another player then your mission is: Occupy 24 countries."),],
[  2,  24,  1,  0,  0,  0,  __("Destroy all of Player2's Troops. If they are yours or they have already been destroyed by another player then your mission is: Occupy 24 countries."),],
[  3,  24,  1,  0,  0,  0,  __("Destroy all of Player3's Troops. If they are yours or they have already been destroyed by another player then your mission is: Occupy 24 countries."),],
[  4,  24,  1,  0,  0,  0,  __("Destroy all of Player4's Troops. If they are yours or they have already been destroyed by another player then your mission is: Occupy 24 countries."),],
[  5,  24,  1,  0,  0,  0,  __("Destroy all of Player5's Troops. If they are yours or they have already been destroyed by another player then your mission is: Occupy 24 countries."),],
[  6,  24,  1,  0,  0,  0,  __("Destroy all of Player6's Troops. If they are yours or they have already been destroyed by another player then your mission is: Occupy 24 countries."),],
);
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;


=pod

=head1 NAME

Games::Risk::Map::Risk2210 - Risk 2210 Map

=head1 VERSION

version 3.113460

=head1 DESCRIPTION

Risk 2210 Map by Matthias Kuehl.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Jerome Quelin.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut


__END__

