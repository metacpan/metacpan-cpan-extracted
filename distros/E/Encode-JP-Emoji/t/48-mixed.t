use strict;
use warnings;
use lib 't';
require 'test-util.pl';
use Test::More;
use Encode;
use Encode::JP::Emoji;

plan tests => 12;

my $encoding = 'x-utf8-e4u-mixed-pp';

my $sunset1 = "\x{E44A}";
my $sunset2 = "\x{FE00C}";
is(shex(decode($encoding=>encode(utf8=>$sunset1))), shex($sunset2), 'sunset 1');
is(shex(decode(utf8=>encode($encoding=>$sunset2))), shex($sunset1), 'sunset 2');

my $wind1 = "\x{E447}";
my $wind2 = "\x{FE043}";
is(shex(decode($encoding=>encode(utf8=>$wind1))), shex($wind2), 'wind 1');
is(shex(decode(utf8=>encode($encoding=>$wind2))), shex($wind1), 'wind 2');

my $yummy1 = "\x{E752}";
my $yummy2 = "\x{FE32B}";
is(shex(decode($encoding=>encode(utf8=>$yummy1))), shex($yummy2), 'yummy 1');
is(shex(decode(utf8=>encode($encoding=>$yummy2))), shex($yummy1), 'yummy 2');

my $sports1 = "\x{E652}";
my $sports2 = "\x{FE7D0}";
is(shex(decode($encoding=>encode(utf8=>$sports1))), shex($sports2), 'sports 1');
is(shex(decode(utf8=>encode($encoding=>$sports2))), shex($sports1), 'sports 2');

my $search1 = "\x{E6DC}";
my $search2 = "\x{FEB85}";
is(shex(decode($encoding=>encode(utf8=>$search1))), shex($search2), 'search 1');
is(shex(decode(utf8=>encode($encoding=>$search2))), shex($search1), 'search 2');

my $victory1 = "\x{E694}";
my $victory2 = "\x{FEB94}";
is(shex(decode($encoding=>encode(utf8=>$victory1))), shex($victory2), 'victory 1');
is(shex(decode(utf8=>encode($encoding=>$victory2))), shex($victory1), 'victory 2');
