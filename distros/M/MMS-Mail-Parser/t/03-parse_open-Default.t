#!perl -T

use Test::More tests=> 4;
use MMS::Mail::Parser;

my $parser;
my $mmsparser;
my $message;
my $parsed;

$mmsparser = new MMS::Mail::Parser;
$message = $mmsparser->parse_open('t/msgs/Default');
isa_ok($message, 'MMS::Mail::Message');
is($message->is_valid,1);
$parsed = $mmsparser->provider_parse;
isa_ok($parsed, 'MMS::Mail::Message::Parsed');
is($parsed->is_valid,1);

