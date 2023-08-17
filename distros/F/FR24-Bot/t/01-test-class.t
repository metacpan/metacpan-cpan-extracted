use v5.12;
use warnings;
use Test::More;
use FindBin qw($RealBin);

use_ok('FR24::Bot');

my $bot = FR24::Bot->new( -config => "$RealBin/config.ini", -name => "FR24 Bot" );
isa_ok($bot, 'FR24::Bot');
ok($bot->{name} eq "FR24 Bot", "Bot name is FR24 Bot");
ok($bot->{config}->{"telegram"}->{"apikey"}, "API key is set");
done_testing();