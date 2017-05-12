use strict;
use warnings;
use Test::Simple tests=> 1;

BEGIN {
	(-d 'tmp') || mkdir('tmp') || die;
}

use IPC::Lite;

my %fruit;

tie %fruit, 'IPC::Lite', Path=>'tmp/test.db', Table=>'fruit';

$fruit{apple} = 4;
$fruit{banana} = 5;

ok($fruit{banana} eq 5, "bannana: $fruit{banana}");

