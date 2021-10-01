# Copyright (C) 2021  Alex Schroeder <alex@gnu.org>

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
use Mojo::File;

my $script = Mojo::File->new('script', 'face-generator');

# random

# https://en.wikipedia.org/wiki/List_of_file_signatures → PNG
my $re = join('', map { chr(hex($_)) } qw(89 50 4E 47 0D 0A 1A 0A));
like(qx($^X $script random alex man), qr/^$re/, "random alex man is PNG");

done_testing;
