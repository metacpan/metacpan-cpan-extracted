use strict;
use warnings;
use blib;

use Test::More tests => 3;

BEGIN { use_ok('Mail::SRS::Daemon'); }

my $srs = new Mail::SRS::Daemon(
				Secret	=> "foo",
					);
ok(defined $srs, 'Created an object');
isa_ok($srs, 'Mail::SRS::Daemon');
