use v5.12;
use warnings;
use Test::More;
use FindBin qw($RealBin);
# Skip under windows
if ($^O =~ /Win32/) {
    plan skip_all => "Test not supported under Windows";
    exit;
}
my $perl = $^X;
# Read config

my $cmd = "$perl -Ilib bin/config-fr24-bot -c $RealBin/config.ini --no-write --quiet ";
my $out = `$cmd`;
ok(defined $?, "Command1 executed: $cmd [$?]");
ok($out =~/7908487915:AEEQFftvQtEbavBGcB81iF1cF2koliWFxJE/, "Config Api found");
ok($out =~/localhost/, "Config IP found");
ok($out =~/8080/, "Config port found");

# Override config
my $cmd2 = "$perl -Ilib bin/config-fr24-bot -c $RealBin/config.ini -a default -i 127.0.0.1 -p 8989 --no-write --quiet ";
my $out2 = `$cmd2`;
ok(defined $?, "Command2 executed: $cmd2 [$?]");
ok($out2 =~/127\.0\.0\.1/, "IP is set to 127.0.0.1");
ok($out2 =~/8989/, "Port set to 8989");

done_testing();

# [telegram]
# apikey=7908487915:AEEQFftvQtEbavBGcB81iF1cF2koliWFxJE

# [users]
# everyone=1

# [server]
# ip=localhost
# port=8080