use strict;
use warnings;
use Test::More;
use File::Raw::Separated;
use File::Raw qw(slurp);

# Unknown plugin name croaks.
my $rc = eval { File::Raw::slurp('t/data/simple.csv', plugin => 'nope'); 1 };
ok(!$rc, 'slurp with unknown plugin croaks');
like($@, qr/unknown plugin/i, 'error mentions unknown plugin');
like($@, qr/'nope'/, 'error includes the bad plugin name');

# Plugin names are case-sensitive: 'CSV' is not 'csv'.
$rc = eval { File::Raw::slurp('t/data/simple.csv', plugin => 'CSV'); 1 };
ok(!$rc, "slurp with plugin => 'CSV' (uppercase) croaks - names are case-sensitive");
like($@, qr/unknown plugin/i, 'uppercase variant treated as unknown');

# Strict mode propagates: malformed quoted field croaks via the plugin.
require File::Temp;
my ($fh, $bad) = File::Temp::tempfile(SUFFIX => '.csv', UNLINK => 1);
print $fh qq("a"x,b\n);   # stray byte after closing quote
close $fh;

$rc = eval { File::Raw::slurp($bad, plugin => 'csv', strict => 1); 1 };
ok(!$rc, "strict => 1 croaks on malformed input");
like($@, qr/quot/i, 'error mentions quoting');

# Same input WITHOUT strict mode parses leniently and returns AoA.
my $lenient = File::Raw::slurp($bad, plugin => 'csv');
is(ref($lenient), 'ARRAY', 'lenient mode produces AoA');

done_testing;
