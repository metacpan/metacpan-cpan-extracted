# Copyright (C) 2009-2021  Alex Schroeder <alex@gnu.org>
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option) any
# later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

=encoding utf8

=head1 NAME

Game::TextMapper::Constants - width and height for map tiles

=head1 SYNOPSIS

    use Game::TextMapper::Constants qw($dx $dy);

=head1 DESCRIPTION

This class defines C<$dx> (100) and C<$dy> (100×√3), the two important lengths
for hex tiles (used in the SVG output).

=cut

package Game::TextMapper::Constants;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw($dx $dy);

our $dx = 100;
our $dy = 100*sqrt(3);

1;
