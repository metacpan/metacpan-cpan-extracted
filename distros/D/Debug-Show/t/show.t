use warnings;
use strict;

use Test::More tests => 12;

BEGIN { $SIG{__WARN__} = sub { die "WARNING: $_[0]" }; }

BEGIN { use_ok "Debug::Show", qw(debug=show); }

sub warning_from(&) {
	my @w;
	local $SIG{__WARN__} = sub { push @w, $_[0] };
	$_[0]->();
	return @w == 0 ? "??? no warning\n" : @w == 1 ? $w[0] :
		"??? @{[scalar(@w)]} warnings\n";
}

is warning_from { debug; }, "###\n";

sub quux { [$_[0],"a"] }

for(my $i = 0; $i != 2; $i++) {
	is warning_from { debug $i; }, "### \$i = $i;\n";
	is warning_from { debug $i, 1; }, "### \$i = $i; 1 = 1;\n";
	is warning_from { debug $i+1; }, "### (\$i + 1) = @{[$i+1]};\n";
	is warning_from { debug quux($i); }, "### quux(\$i) = [$i,\"a\"];\n";
}

my @a = qw(a b c);
my @b = qw(x y);
is warning_from { debug @a, @b; }, "### \@a = 3; \@b = 2;\n";
is warning_from { debug \@a, \@b; },
	"### (\\\@a) = [\"a\",\"b\",\"c\"]; (\\\@b) = [\"x\",\"y\"];\n";

1;
