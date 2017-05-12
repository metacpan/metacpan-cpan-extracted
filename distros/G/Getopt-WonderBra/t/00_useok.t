my @mods = qw( 
	Getopt::WonderBra
);
BEGIN { use Test::More; };
plan tests => 0+@mods;
for ( @mods ) {
	use_ok($_);
};
