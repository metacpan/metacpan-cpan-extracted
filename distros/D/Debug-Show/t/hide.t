use warnings;
use strict;

use Test::More tests => 2;

BEGIN { $SIG{__WARN__} = sub { die "WARNING: $_[0]" }; }

BEGIN { use_ok "Debug::Show", qw(debug=hide); }

debug;

sub quux { [$_[0],"a"] }

for(my $i = 0; $i != 2; $i++) {
	debug $i;
	debug $i, 1;
	debug $i+1;
	debug quux($i);
}

my @a = qw(a b c);
my @b = qw(x y);
debug @a, @b;
debug \@a, \@b;

debug ok(0);

ok 1;

1;
