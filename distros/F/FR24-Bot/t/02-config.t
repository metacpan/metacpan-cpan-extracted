use v5.12;
use warnings;
use Test::More;
use FindBin qw($RealBin);
use File::Temp qw/ :POSIX /;

use_ok('FR24::Utils');
my $conf_api = '7908487915:AEEQFftvQtEbavBGcB81iF1cF2koliWFxJE';
my $conf_ip = 'localhost';

my $conf = FR24::Utils::loadconfig("$RealBin/config.ini");
ok($conf->{"telegram"}->{"apikey"}, "API key is set");
ok($conf->{"telegram"}->{"apikey"} eq $conf_api, "API key is correct: $conf_api");

ok($conf->{"server"}->{"ip"}, "IP is set");
ok($conf->{"server"}->{"ip"} eq $conf_ip, "IP is correct: $conf_ip");

my $valid_sections = ["telegram", "server", "users"];
my $valid_keys = {
    "telegram" => ["apikey"],
    "server" => ["ip", "port"],
    "users" => ["everyone"]
};
for my $key (sort keys %{$conf}) {
    my $test = grep {$_ eq $key} @{$valid_sections};
    ok($test, "Section '$key' is valid");
    for my $subkey (sort keys %{$conf->{$key}}) {
        my $test = grep {$_ eq $subkey} @{$valid_keys->{$key}};
        ok($test, "  Key '$subkey' is valid under '$key'");
    }
}
#my $system_temp = $ENV{"TEMP"} || $ENV{"TMP"} || "/tmp";
#my $temp_file = "$system_temp/fr24-bot-test.ini";
my $temp_file = tmpnam();

eval {
    FR24::Utils::saveconfig($temp_file, $conf);
};

my $error = $@;
ok(!$error, "No error saving configuration: $error");
my $conf2 = FR24::Utils::loadconfig($temp_file);
ok($conf2->{"telegram"}->{"apikey"}, "API key is set in the new file $temp_file");

ok($conf2->{"telegram"}->{"apikey"} eq $conf->{"telegram"}->{"apikey"}, "API key is correct as in the loaded configuration: $conf_api");
ok($conf2->{"telegram"}->{"apikey"} eq $conf_api, "API key is correct as defined in test: $conf_api");

done_testing();