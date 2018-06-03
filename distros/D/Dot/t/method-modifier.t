=license

	Dot - The beginning of a Perl universe
	Copyright © 2018 Yang Bo

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <https://www.gnu.org/licenses/>.

=cut
use Dot 'sane', iautoload => ['Test::More'];
my $o = sub {
	Dot::mod(my $o = shift);
	$o->{add}(method => sub { "I'm the method.\n" });
	$o;
}->({});
$o->{method} = do {
	my $p = $o->{method};
	sub { "around.\n" . $p->() . "around.\n" };
};
$o->{method} = do {
	my $p = $o->{method};
	sub { "before.\n" . $p->() };
};
$o->{method} = do {
	my $p = $o->{method};
	sub { $p->() . "after.\n" };
};
is($o->{method}(), <<EOF);
before.
around.
I'm the method.
around.
after.
EOF
done_testing();
