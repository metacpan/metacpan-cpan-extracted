use strict;
use warnings;
use Test::More;
use Try::Tiny;

use Message::Passing::Output::Test;
use Message::Passing::Filter::Decoder::JSON;

my $unpacked;
my $test = Message::Passing::Output::Test->new(cb => sub { $unpacked = shift });
my $decoder = Message::Passing::Filter::Decoder::JSON->new(output_to => $test);

my $h = {};
$decoder->consume($h);;
is_deeply $unpacked, $h;

$decoder->consume('{"baz":"bar"}');
is_deeply $unpacked, {"baz" => "bar"};

done_testing;

