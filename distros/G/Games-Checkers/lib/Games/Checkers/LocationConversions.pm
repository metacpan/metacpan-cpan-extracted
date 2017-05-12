# Games::Checkers, Copyright (C) 1996-2012 Mikhael Goikhman, migo@cpan.org
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;

package Games::Checkers::LocationConversions;

sub location_to_arr ($) {
	my ($loc) = @_;
	return (int($loc % 4) * 2 + int(($loc / 4) % 2) + 1, int($loc / 4) + 1);
}

sub arr_to_location ($$) {
	my ($x, $y) = @_;
	return int((($x - 1) % 8) / 2) + ($y - 1) * 4;
}

sub location_to_str ($) {
	my ($loc) = @_;
	my @c = location_to_arr($loc);
	return chr(ord('a') + $c[0] - 1) . $c[1];
}

sub str_to_location ($) {
	my ($str) = @_;
	$str =~ /^(\w)(\d)$/ || die "Invalid board coordinate string ($str)\n";
	return arr_to_location(ord($1) - ord('a') + 1, $2);
}

sub location_to_num ($) {
	my ($loc) = @_;
	return 32 - $loc if $ENV{ITALIAN_BOARD_NOTATION};
	return (int($loc / 4)) * 4 + 4 - $loc % 4;
}

sub num_to_location ($) {
	my ($num) = @_;
	return 32 - $num if $ENV{ITALIAN_BOARD_NOTATION};
	return (int(($num - 1) / 4)) * 4 + 3 - ($num - 1) % 4;
}

use base 'Exporter';
use vars qw(@EXPORT);
@EXPORT = qw(
	location_to_arr arr_to_location
	location_to_str str_to_location
	location_to_num num_to_location
);

1;
