#!/usr/bin/perl
# this test will actually core for version < 2.4.8.2 :-))
use Test::More tests => 1;

use strict;
use Mcrypt qw(:ALGORITHMS :MODES :FUNCS);

my($input) = "0123456701234567";

my $td = Mcrypt->new( algorithm => Mcrypt::BLOWFISH,
                            mode => Mcrypt::CFB,
                         verbose => 0 );
my($key) = "k" x $td->{KEY_SIZE};
my($iv) = "i" x $td->{IV_SIZE};
$td->init($key, $iv);
$td->decrypt($input);
$td->end();

ok(1, "survived");
