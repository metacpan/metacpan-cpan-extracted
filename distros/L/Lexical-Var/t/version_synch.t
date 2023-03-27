use warnings;
use strict;

use Test::More tests => 4;

BEGIN { require_ok "Lexical::Var"; }
my $main_ver = $Lexical::Var::VERSION;
ok defined($main_ver), "have main version number";

foreach my $submod (qw(Sub)) {
	my $mod = "Lexical::$submod";
	require_ok $mod;
	no strict "refs";
	is ${"${mod}::VERSION"}, $main_ver, "$mod version number matches";
}

1;
