use strict;
BEGIN { use Test::More; };
my @mods = qw(
	Exception::ThrowUnless
);
plan tests => 0+@mods;
for ( @mods ) {
	use_ok($_);
};
#########################
