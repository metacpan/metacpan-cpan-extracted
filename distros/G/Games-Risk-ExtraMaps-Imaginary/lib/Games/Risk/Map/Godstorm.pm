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

package Games::Risk::Map::Godstorm;
{
  $Games::Risk::Map::Godstorm::VERSION = '3.113460';
}
# ABSTRACT: Risk GodStorm

use Moose;
extends 'Games::Risk::Map';


use Locale::Messages   qw{ :locale_h bind_textdomain_filter turn_utf_8_on };
use Locale::TextDomain "Games-Risk-Map-Godstorm";
use Moose;

extends 'Games::Risk::ExtraMaps::Imaginary';

my $domain ="Games-Risk-Map-Godstorm";
bindtextdomain $domain, __PACKAGE__->localedir->stringify;
bind_textdomain_codeset $domain, "utf-8";
bind_textdomain_filter  $domain, sub { turn_utf_8_on($_[0]) };


# -- map  builders

sub name   { "godstorm" }
sub title  { __("Risk GodStorm") }
sub author { "Yura Mamyrin" }


# -- raw map information

sub _raw_continents {
return (
# id, name, bonus, color
#   0, __('Europe'), 5, blue
[1, __("Germania"), 5, "green"],
[2, __("Atlantis"), 3, "magenta"],
[3, __("Asia Minor"), 3, "cyan"],
[4, __("Africa"), 5, "yellow"],
[5, __("Europa"), 7, "red"],
[6, __("Hyrkania"), 2, "orange"],
);
}

sub _raw_countries {
return (
# greyscale, name, continent id, x, y, [connections]
#   1, __('Alaska'), 1, 43, 67, [ 1,2,3,38 ]
[1, __("Dacia"), 5, 355, 175, [40, 2, 3]],
[2, __("Thracia"), 5, 403, 196, [1, 3, 9]],
[3, __("Dalmatia"), 5, 316, 214, [1, 4, 2, 9, 6]],
[4, __("Liguria"), 5, 265, 229, [3, 20, 5]],
[5, __("Roma"), 5, 294, 287, [4, 7, 6]],
[6, __("Apulia"), 5, 327, 300, [5, 8, 9, 3]],
[7, __("Corsica"), 5, 259, 310, [5]],
[8, __("Sicilia"), 5, 343, 347, [23, 6]],
[9, __("Graecia"), 5, 401, 263, [3, 6, 10, 11, 2]],
[10, __("Minoa"), 5, 445, 290, [9, 27, 11]],
[11, __("Ionia"), 5, 476, 218, [9, 12, 10]],
[12, __("Anatolia"), 5, 540, 177, [11, 32]],
[13, __("Hibernia"), 1, 86, 169, [15, 14, 35]],
[14, __("Caledonia"), 1, 142, 135, [13, 16, 15]],
[15, __("Anglia"), 1, 142, 184, [19, 20, 13, 14]],
[16, __("Thule"), 1, 210, 78, [17, 19, 14]],
[17, __("Varangia"), 1, 314, 16, [18, 16, 39]],
[18, __("Galicia"), 1, 330, 90, [19, 17]],
[19, __("Alemannia"), 1, 231, 189, [20, 18, 16, 15]],
[20, __("Gaul"), 1, 188, 258, [21, 19, 15, 4]],
[21, __("Iberia"), 1, 148, 343, [20, 38, 22]],
[22, __("Atlas"), 4, 173, 404, [38, 21, 24, 23]],
[23, __("Carthage"), 4, 290, 361, [22, 24, 25, 8]],
[24, __("Gaitulia"), 4, 257, 409, [22, 23, 25, 26]],
[25, __("Cyrenaica"), 4, 386, 375, [23, 24, 26, 27]],
[26, __("Nubia"), 4, 447, 410, [25, 27, 24, 28]],
[27, __("Egypt"), 4, 517, 365, [25, 26, 28, 32, 10]],
[28, __("Kush"), 4, 583, 398, [27, 34, 26]],
[29, __("Parthia"), 3, 648, 154, [31, 30, 42]],
[30, __("Sumer"), 3, 667, 234, [33, 29, 31]],
[31, __("Assyria"), 3, 611, 231, [33, 32, 29, 30]],
[32, __("Phoenicia"), 3, 545, 267, [27, 34, 33, 31, 12]],
[33, __("Babylon"), 3, 614, 283, [34, 32, 31, 30]],
[34, __("Sheba"), 3, 631, 359, [28, 32, 33]],
[35, __("Hesperide"), 2, 37, 245, [13, 36]],
[36, __("Tritonis"), 2, 35, 306, [35, 37]],
[37, __("Poseidonis"), 2, 18, 371, [36, 38]],
[38, __("Oricalcos"), 2, 55, 412, [37, 22, 21]],
[39, __("Rus"), 6, 475, 39, [42, 41, 40, 17]],
[40, __("Scythia"), 6, 422, 103, [41, 39, 1]],
[41, __("Cimmeria"), 6, 512, 91, [42, 39, 40]],
[42, __("Sarmathia"), 6, 621, 67, [29, 39, 41]],
);
}


sub _raw_cards {
return (
# type, id_country
#   artillery, 2
#   wildcard
["cavalry", 1],
["infantry", 2],
["artillery", 3],
["cavalry", 4],
["infantry", 5],
["artillery", 6],
["cavalry", 7],
["infantry", 8],
["artillery", 9],
["cavalry", 10],
["infantry", 11],
["artillery", 12],
["cavalry", 13],
["infantry", 14],
["artillery", 15],
["cavalry", 16],
["infantry", 17],
["artillery", 18],
["cavalry", 19],
["infantry", 20],
["artillery", 21],
["cavalry", 22],
["infantry", 23],
["artillery", 24],
["cavalry", 25],
["infantry", 26],
["artillery", 27],
["cavalry", 28],
["infantry", 29],
["artillery", 30],
["cavalry", 31],
["infantry", 32],
["artillery", 33],
["cavalry", 34],
["infantry", 35],
["artillery", 36],
["cavalry", 37],
["infantry", 38],
["artillery", 39],
["cavalry", 40],
["infantry", 41],
["artillery", 42],
["joker", undef],
["joker", undef],
["joker", undef],
["joker", undef],
["joker", undef],
["joker", undef],
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
[  0,  0,  0,  5,  2,  0,  __("Conquer the continents of Europa and Atlantis."),],
[  0,  0,  0,  3,  6,  "*",  __("Conquer the continents of Asia Minor and Hyrkania and a third continent of your choice."),],
[  0,  0,  0,  5,  4,  0,  __("Conquer the continents of Europa and Africa."),],
[  0,  0,  0,  3,  2,  "*",  __("Conquer the continents of Asia Minor and Atlantis and a third continent of your choice."),],
[  0,  0,  0,  1,  6,  0,  __("Conquer the continents of Germania and Hyrkania."),],
[  0,  0,  0,  1,  4,  0,  __("Conquer the continents of Germania and Africa."),],
[  0,  18,  2,  0,  0,  0,  __("Occupy 18 countries of your choice and occupy each with at least 2 armies."),],
[  0,  24,  1,  0,  0,  0,  __("Occupy 24 countries of your choice and occupy each with at least 1 army."),],
[  1,  24,  1,  0,  0,  0,  __("Destroy all of Player1's troops. If they are yours or they have already been destroyed by another player then your mission is: Occupy 24 countries."),],
[  2,  24,  1,  0,  0,  0,  __("Destroy all of Player2's troops. If they are yours or they have already been destroyed by another player then your mission is: Occupy 24 countries."),],
[  3,  24,  1,  0,  0,  0,  __("Destroy all of Player3's troops. If they are yours or they have already been destroyed by another player then your mission is: Occupy 24 countries."),],
[  4,  24,  1,  0,  0,  0,  __("Destroy all of Player4's troops. If they are yours or they have already been destroyed by another player then your mission is: Occupy 24 countries."),],
[  5,  24,  1,  0,  0,  0,  __("Destroy all of Player5's troops. If they are yours or they have already been destroyed by another player then your mission is: Occupy 24 countries."),],
[  6,  24,  1,  0,  0,  0,  __("Destroy all of Player6's troops. If they are yours or they have already been destroyed by another player then your mission is: Occupy 24 countries."),],
);
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;


=pod

=head1 NAME

Games::Risk::Map::Godstorm - Risk GodStorm

=head1 VERSION

version 3.113460

=head1 DESCRIPTION

Risk GodStorm by Yura Mamyrin.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Jerome Quelin.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut


__END__

