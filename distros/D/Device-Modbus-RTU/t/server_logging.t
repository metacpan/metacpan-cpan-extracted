use Test::More tests => 20;
use lib 't/lib';
use strict;
use warnings;

BEGIN {
    use_ok 'Device::Modbus::RTU::Server';
}

# Logging prints directly to STDOUT.
close STDOUT;
my $out = '';
open STDOUT, '>', \$out or die "Could not open LOG for writing: $!";

# Send an alarm signal in one second.
# Then, send a SIGINT to stop the server.
$SIG{ALRM} = sub { kill 2, $$ };
# alarm(1);

my $server = Device::Modbus::RTU::Server->new(
    port      => 'test',
    log_level => 3
);

# Tests log_level
is $server->log_level, 3, 'Constructor sets log_level correctly';
$server->log_level(4);
is $server->log_level, 4, 'Accessor/mutator log_level works';

foreach my $i (1..4) {
    $server->log_level($i);
    foreach my $j (1..4) {
        $server->log($j, "Level $j");
        if ($j <= $i) {
            like $out, qr/Level $j/,
                "Logging level $i prints msgs for level $j";
        }
        else {
            unlike $out, qr/Level $j/,
                "Logging level $i does not include msgs level $j";
        }
    }
}

$server->log(1, sub{ "Logging code refs works" });
like $out, qr/code refs/, 'Logging with code refs works';

done_testing();
