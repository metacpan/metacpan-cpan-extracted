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

package Games::Risk::Map::Lotr;
{
  $Games::Risk::Map::Lotr::VERSION = '3.113460';
}
# ABSTRACT: Lord of the Rings Map

use Moose;
extends 'Games::Risk::Map';


use Locale::Messages   qw{ :locale_h bind_textdomain_filter turn_utf_8_on };
use Locale::TextDomain "Games-Risk-Map-Lotr";
use Moose;

extends 'Games::Risk::ExtraMaps::Imaginary';

my $domain ="Games-Risk-Map-Lotr";
bindtextdomain $domain, __PACKAGE__->localedir->stringify;
bind_textdomain_codeset $domain, "utf-8";
bind_textdomain_filter  $domain, sub { turn_utf_8_on($_[0]) };


# -- map  builders

sub name   { "lotr" }
sub title  { __("Lord of the Rings") }
sub author { "???" } # FIXME


# -- raw map information

sub _raw_continents {
return (
# id, name, bonus, color
#   0, __('Europe'), 5, blue
[1, __("Gondor"), 7, "#663300"],
[2, __("Mirkwood"), 4, "#009900"],
[3, __("Rohan"), 4, "#009999"],
[4, __("Rhovanion"), 5, "#ff9900"],
[5, __("Arnor"), 7, "#ff3333"],
[6, __("Eriador"), 3, "#cccc00"],
[7, __("Rhun"), 2, "#330033"],
[8, __("Haradwaith"), 2, "#ffff33"],
[9, __("Mordor"), 2, "#333300"],
);
}

sub _raw_countries {
return (
# greyscale, name, continent id, x, y, [connections]
#   1, __('Alaska'), 1, 43, 67, [ 1,2,3,38 ]
[1, __("Forodwaith"), 5, 13, 150, [49, 50, 2, 4, 3, 44, 46]],
[2, __("Eastern Angmar"), 5, 56, 154, [12, 1]],
[3, __("Borderlands"), 5, 78, 251, [1, 4, 43, 48, 5, 6, 10]],
[4, __("Angmar"), 5, 79, 210, [1, 3]],
[5, __("North Downs"), 5, 117, 251, [3, 6]],
[6, __("Fornost"), 5, 150, 258, [3, 10, 5, 8, 7]],
[7, __("Buckland"), 5, 188, 275, [6, 47, 8, 9]],
[8, __("Old Forest"), 5, 187, 249, [10, 6, 7, 9]],
[9, __("South Downs"), 5, 222, 249, [18, 10, 7, 8]],
[10, __("Weather Hills"), 5, 161, 225, [3, 11, 9, 8, 6]],
[11, __("Rhudaur"), 5, 148, 180, [17, 12, 10]],
[12, __("Carrock"), 2, 115, 140, [15, 11, 2, 13]],
[13, __("North Mirkwood"), 2, 112, 105, [14, 12, 51]],
[14, __("Eastern Mirkwood"), 2, 194, 90, [25, 16, 15, 13]],
[15, __("Anduin Valley"), 2, 227, 116, [26, 29, 16, 14, 12]],
[16, __("South Mirkwood"), 2, 260, 90, [25, 26, 15, 14]],
[17, __("Eregion"), 3, 220, 204, [19, 30, 11]],
[18, __("Minhiriath"), 3, 276, 295, [20, 19, 9, 44, 46, 37, 54]],
[19, __("Dunland"), 3, 282, 235, [20, 18, 17]],
[20, __("Enedwaith"), 3, 352, 251, [23, 19, 18]],
[21, __("West Rohan"), 3, 413, 266, [32, 23]],
[22, __("Fangorn"), 3, 356, 186, [23, 28, 27]],
[23, __("Gap of Rohan"), 3, 416, 190, [39, 21, 22, 27, 20]],
[24, __("Rhun Hills"), 4, 334, 15, [25]],
[25, __("Brown Lands"), 4, 354, 59, [31, 26, 24, 16, 14, 52]],
[26, __("Emyn Muil"), 4, 330, 102, [31, 27, 25, 16, 15]],
[27, __("The Wold"), 4, 347, 141, [23, 22, 28, 26]],
[28, __("Lorien"), 4, 287, 164, [22, 27, 29]],
[29, __("Gladden Fields"), 4, 220, 147, [30, 28, 15]],
[30, __("Moria"), 4, 232, 178, [17, 29]],
[31, __("Dead Marshes"), 4, 422, 111, [40, 59, 26, 25]],
[32, __("Druwaith Iaur"), 1, 478, 307, [34, 21]],
[33, __("Andras"), 1, 530, 322, [34]],
[34, __("Anfalas"), 1, 521, 284, [35, 32, 33]],
[35, __("Vale of Erech"), 1, 488, 252, [36, 34]],
[36, __("Lamedon"), 1, 497, 218, [38, 37, 35]],
[37, __("Belfalas"), 1, 548, 213, [38, 54, 36, 18]],
[38, __("Lebennin"), 1, 521, 177, [39, 37, 36]],
[39, __("Minis Tirith"), 1, 485, 167, [40, 23, 38]],
[40, __("Ithilien"), 1, 496, 133, [41, 39, 31, 62]],
[41, __("South Ithilien"), 1, 557, 134, [53, 40]],
[42, __("Forlindon"), 6, 120, 392, [44]],
[43, __("Lune Valley"), 6, 84, 316, [3, 44, 48]],
[44, __("Mithlond"), 6, 148, 359, [46, 42, 43, 1, 18]],
[45, __("Harlindon"), 6, 236, 368, [46]],
[46, __("Tower Hills"), 6, 162, 318, [47, 44, 45, 48, 1, 18]],
[47, __("The Shire"), 6, 202, 302, [7, 46]],
[48, __("Evendim Hills"), 6, 100, 291, [3, 43, 46]],
[49, __("North Rhun"), 7, 22, 16, [52, 50, 1]],
[50, __("Withered Heath"), 7, 54, 57, [49, 1, 51]],
[51, __("Esgaroth"), 7, 130, 63, [13, 50]],
[52, __("South Rhun"), 7, 173, 15, [25, 49]],
[53, __("Harandor"), 8, 589, 146, [56, 41]],
[54, __("Umbar"), 8, 627, 182, [55, 37, 18]],
[55, __("Deep Harad"), 8, 663, 173, [56, 54]],
[56, __("Harad"), 8, 646, 114, [57, 53, 55]],
[57, __("Near Harad"), 8, 644, 63, [58, 56]],
[58, __("Khand"), 8, 614, 17, [57]],
[59, __("Udun Value"), 9, 467, 88, [60, 31]],
[60, __("Mount Doom"), 9, 493, 68, [63, 61, 59]],
[61, __("Barad Dur"), 9, 478, 32, [63, 60]],
[62, __("Minas Morgul"), 9, 522, 95, [63, 40]],
[63, __("Gorgoroth"), 9, 521, 19, [64, 62, 61, 60]],
[64, __("Nurn"), 9, 564, 73, [63]],
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
["infantry", 43],
["artillery", 44],
["cavalry", 45],
["infantry", 46],
["artillery", 47],
["cavalry", 48],
["infantry", 49],
["artillery", 50],
["cavalry", 51],
["infantry", 52],
["artillery", 53],
["cavalry", 54],
["infantry", 55],
["artillery", 56],
["cavalry", 57],
["infantry", 58],
["artillery", 59],
["cavalry", 60],
["infantry", 61],
["artillery", 62],
["cavalry", 63],
["infantry", 64],
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

);
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;


=pod

=head1 NAME

Games::Risk::Map::Lotr - Lord of the Rings Map

=head1 VERSION

version 3.113460

=head1 DESCRIPTION

LOTR Map by ???

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Jerome Quelin.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut


__END__

