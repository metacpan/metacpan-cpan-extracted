# Copyright (C) 2023  Alex Schroeder <alex@gnu.org>

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
# with this program. If not, see <https://www.gnu.org/licenses/>.

use Modern::Perl;
use Test::More;
use Test::Mojo;
use utf8;

# No networking.
$ENV{HEX_DESCRIBE_OFFLINE} = 1;
my $t = Test::Mojo->new('Game::HexDescribe');

$t->post_ok('/describe' => form => {map => "0101 water\n", markdown => "on", load => "schroeder"})
    ->status_is(200)
    ->content_like(qr/^\*\*Procedures\*\*: /) # first line
    ->content_like(qr/^\*\*0101\*\*: /m);

done_testing;
