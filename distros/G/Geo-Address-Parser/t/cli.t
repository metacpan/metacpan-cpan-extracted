use strict;
use warnings;

use IPC::Open3;
use Symbol 'gensym';
use Test::Most;

my $script = -e 'bin/geo-parse' ? 'bin/geo-parse' : 'blib/bin/geo-parse';

# I guess everything is executable on Windows
ok(-x $script, "$script is executable") if($^O ne 'MSWin32');

my $address = 'Auckland Museum, 1 Museum Circuit, Parnell, Auckland 1010';

my ($out, $err);
my $pid = open3(gensym, \*CHLD_OUT, \*CHLD_ERR, $^X, $script, '--json', '--country', 'NZ', $address);

$out = do { local $/; <CHLD_OUT> };
$err = do { local $/; <CHLD_ERR> };
waitpid($pid, 0);

diag("STDOUT:\n$out") if $ENV{TEST_VERBOSE};
diag("STDERR:\n$err") if $err;

like($out, qr/"city"\s*:\s*"Auckland"/, 'Output includes city');
like($out, qr/"postcode"\s*:\s*"1010"/, 'Output includes postcode');
like($out, qr/"street"\s*:\s*"1 Museum Circuit"/, 'Output includes street');
like($out, qr/"suburb"\s*:\s*"Parnell"/, 'Output includes suburb');
like($out, qr/"name"\s*:\s*"Auckland Museum"/, 'Output includes name');

done_testing();
