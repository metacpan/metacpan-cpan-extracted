# Copyright (C) 2021–2022  Alex Schroeder <alex@gnu.org>

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
use IPC::Open2;
use Mojo::DOM;
use Test::Mojo;
use Mojo::File;

my $script = Mojo::File->new('script', 'hex-describe');

# random

sub test {
  my $re = shift;
  my $pid;
  $pid = open2(my $out, my $in, $^X, $script, @_);
  # always slurp!
  undef $/;
  my $data = <$out>;
  like($data, $re);
  # reap zombie and retrieve exit status
  waitpid($pid, 0);
  my $child_exit_status = $? >> 8;
  is($child_exit_status, 0, "Exit status OK");
}

test(qr(^[1-6]$), qw(rule --table schroeder --rule 1d6 --limit 1));
test(qr(^[1-6]\n\n---\n\n[1-6]$), qw(rule --table schroeder --rule 1d6 --limit 2));
test(qr(^[1-6]-[1-6]$), qw(rule --table schroeder --rule 1d6 --limit 2 --separator -));
test(qr(^[1-6]-in-6$), qw(rule --table schroeder --text [1d6]-in-6 --limit 1));

done_testing;
