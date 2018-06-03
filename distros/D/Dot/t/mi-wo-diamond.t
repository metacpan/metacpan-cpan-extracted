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
use Dot 'sane', iautoload => [[qw'Test::More ok']];
my @class;
for my $i (0..2) {
	push @class, sub {
		Dot::mod(my $o = shift);
		for my $j (0..2) {
			$o->{add}("method$j" => sub { "method $j of class $i." });
		}
	};
}
# require method 0 from class 2, method 1 from class 1, and method 2 from class 0.
my %map = (0 => 2,
	   1 => 1,
	   2 => 0);
my $class = sub {
	my ($o, @bak) = shift;
	for my $i (0..2) {
		$class[$i]($o);
		$bak[$i] = {%$o};
	}
	$o->{"method$_"} = $bak[$map{$_}]{"method$_"} for 0..2;
	$o;
};
my $o = $class->({});
is($o->{"method$_"}(), "method $_ of class $map{$_}.") for 0..2;
done_testing();
