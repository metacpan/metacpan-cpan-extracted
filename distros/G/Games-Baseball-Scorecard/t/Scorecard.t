# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Mac-Growl.t'

use warnings;
use strict;

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN { use_ok('Games::Baseball::Scorecard') };

use File::Path;

chdir 't';

my $s = Games::Baseball::Scorecard->new('gametest');
$s->init({
	scorer	=> 'Pudge',
	date	=> '2004-10-24, 20:05-23:25',
	at	=> 'Fenway Park, Boston',
	temp	=> '48 drizzle',
	wind	=> '15 from CF',
	att	=> '35,001',
	home	=> { team => 'Boston Red Sox' },
	away	=> { team => 'St. Louis Cardinals' },
});
my $pdf = $s->generate;
ok($pdf, 'generate PDF');
diag($pdf);

__END__
