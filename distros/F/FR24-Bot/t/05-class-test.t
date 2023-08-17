use v5.12;
use warnings;
use Test::More;
use FindBin qw($RealBin);
use File::Temp qw/ :POSIX /;
use Data::Dumper;
use_ok('FR24::Bot');
my $bot = FR24::Bot->new( 
    -config => "$RealBin/config.ini", 
    -name => "FR24 Bot",
    -test => 1
);

isa_ok($bot, 'FR24::Bot');

my $is_present = "DLH000";
my $not_present = "DLH001";
ok($bot->getflight($is_present), "Flight $is_present is present");
ok(!$bot->getflight($not_present), "Flight $not_present is NOT present");
#say Dumper $bot;
done_testing();