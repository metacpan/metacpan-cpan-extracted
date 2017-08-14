use warnings;
use strict;

use Test::More tests => 4;

BEGIN { require_ok "Hash::SharedMem"; }
my $main_ver = $Hash::SharedMem::VERSION;
ok defined($main_ver), "have main version number";

foreach my $submod (qw(Handle)) {
	my $mod = "Hash::SharedMem::$submod";
	require_ok $mod;
	no strict "refs";
	is ${"${mod}::VERSION"}, $main_ver, "$mod version number matches";
}

1;
