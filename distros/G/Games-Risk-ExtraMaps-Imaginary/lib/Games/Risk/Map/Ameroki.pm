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

package Games::Risk::Map::Ameroki;
{
  $Games::Risk::Map::Ameroki::VERSION = '3.113460';
}
# ABSTRACT: Ameroki Map

use Moose;
extends 'Games::Risk::Map';


use Locale::Messages   qw{ :locale_h bind_textdomain_filter turn_utf_8_on };
use Locale::TextDomain "Games-Risk-Map-Ameroki";
use Moose;

extends 'Games::Risk::ExtraMaps::Imaginary';

my $domain ="Games-Risk-Map-Ameroki";
bindtextdomain $domain, __PACKAGE__->localedir->stringify;
bind_textdomain_codeset $domain, "utf-8";
bind_textdomain_filter  $domain, sub { turn_utf_8_on($_[0]) };


# -- map  builders

sub name   { "ameroki" }
sub title  { __("Ameroki Map") }
sub author { "map: ameroki.map" }


# -- raw map information

sub _raw_continents {
return (
# id, name, bonus, color
#   0, __('Europe'), 5, blue
[1, "azio", 5, "#9aff80"],
[2, "ameroki", 10, "yellow"],
[3, "utropa", 10, "#a980ff"],
[4, "amerpoll", 5, "red"],
[5, "afrori", 5, "#ffd780"],
[6, "ulstrailia", 5, "magenta"],
);
}

sub _raw_countries {
return (
# greyscale, name, continent id, x, y, [connections]
#   1, __('Alaska'), 1, 43, 67, [ 1,2,3,38 ]
[1, "siberia", 1, 329, 152, [20, 32, 2]],
[2, "worrick", 1, 308, 199, [1, 10, 35, 3]],
[3, "yazteck", 1, 284, 260, [2, 4, 6, 35]],
[4, "kongrolo", 1, 278, 295, [3, 35, 5, 6]],
[5, "china", 1, 311, 350, [4, 6, 42, 7, 9]],
[6, "middle east", 1, 339, 299, [3, 5, 9, 4]],
[7, "sluci", 1, 358, 376, [5, 9, 8]],
[8, "afganistan", 1, 400, 350, [9, 7]],
[9, "kancheria", 1, 388, 313, [5, 8, 7, 6, 10]],
[10, "india", 1, 405, 229, [11, 2, 9]],
[11, "japan", 1, 462, 236, [17, 10]],
[12, "new guinia", 6, 513, 314, [15, 13]],
[13, "western ulstrailia", 6, 525, 340, [15, 14, 12]],
[14, "eastern ulstarilia", 6, 567, 355, [15, 13]],
[15, "jacuncail", 6, 561, 300, [17, 12, 13, 14]],
[16, "tungu", 5, 537, 178, [18, 17, 19]],
[17, "south afrori", 5, 538, 210, [16, 15, 11]],
[18, "north afrori", 5, 486, 131, [20, 19, 16]],
[19, "east afrori", 5, 540, 144, [18, 21, 16]],
[20, "egypt", 5, 443, 100, [23, 1, 18]],
[21, "maganar", 5, 578, 110, [19, 27]],
[22, "pero", 4, 374, 25, [24, 23]],
[23, "heaurt", 4, 428, 32, [22, 24, 20]],
[24, "vagnagale", 4, 327, 40, [25, 22, 23]],
[25, "argentina", 4, 277, 36, [30, 24]],
[26, "ireland", 3, 128, 127, [27, 31]],
[27, "ihesia", 3, 130, 96, [26, 28, 21, 31]],
[28, "western utropa", 3, 181, 112, [27, 31, 29, 32, 30]],
[29, "souther utropa", 3, 235, 133, [28, 32, 30]],
[30, "northern utropa", 3, 253, 82, [28, 25, 29]],
[31, "senadlavin", 3, 177, 155, [28, 34, 32, 26, 27]],
[32, "great britain", 3, 244, 168, [28, 1, 34, 29, 31]],
[33, "teramar", 2, 103, 249, [34, 36]],
[  34,  "western united states",  2,  164,  235,  [38, 35, 33, 36, 37, 31, 32],],
[35, "czeck", 2, 222, 257, [2, 4, 38, 34, 3]],
[36, "alberta", 2, 122, 295, [34, 37, 41, 33, 39]],
[37, "central ameroki", 2, 182, 329, [40, 38, 34, 36, 39]],
[38, "albania", 2, 205, 305, [40, 35, 34, 37]],
[39, "duiestie", 2, 164, 355, [40, 37, 41, 36]],
[40, "Quebeck", 2, 203, 366, [42, 39, 37, 38]],
[41, "vinenlant", 2, 128, 373, [36, 39]],
[42, "heal", 1, 271, 397, [5, 40]],
);
}


sub _raw_cards {
return (
# type, id_country
#   artillery, 2
#   wildcard
[__("cavalry"), 1],
[__("infantry"), 2],
[__("artillery"), 3],
[__("cavalry"), 4],
[__("infantry"), 5],
[__("artillery"), 6],
[__("cavalry"), 7],
[__("infantry"), 8],
[__("artillery"), 9],
[__("cavalry"), 10],
[__("infantry"), 11],
[__("artillery"), 12],
[__("cavalry"), 13],
[__("infantry"), 14],
[__("artillery"), 15],
[__("cavalry"), 16],
[__("infantry"), 17],
[__("artillery"), 18],
[__("cavalry"), 19],
[__("infantry"), 20],
[__("artillery"), 21],
[__("cavalry"), 22],
[__("infantry"), 23],
[__("artillery"), 24],
[__("cavalry"), 25],
[__("infantry"), 26],
[__("artillery"), 27],
[__("cavalry"), 28],
[__("infantry"), 29],
[__("artillery"), 30],
[__("cavalry"), 31],
[__("infantry"), 32],
[__("artillery"), 33],
[__("cavalry"), 34],
[__("artillery"), 35],
[__("cavalry"), 36],
[__("infantry"), 37],
[__("artillery"), 38],
[__("artillery"), 39],
[__("cavalry"), 40],
[__("infantry"), 41],
[__("artillery"), 42],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
[__("joker"), undef],
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

Games::Risk::Map::Ameroki - Ameroki Map

=head1 VERSION

version 3.113460

=head1 DESCRIPTION

Ameroki Map by map: ameroki.map.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Jerome Quelin.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut


__END__

