BEGIN {
	our @modules = qw(
		HTML::SimpleLinkExtor
		);
	}

use Test::More tests => scalar @modules;

foreach my $module ( @modules ) {
	print "bail out! [$module] has problems\n" unless use_ok( $module );
	}
