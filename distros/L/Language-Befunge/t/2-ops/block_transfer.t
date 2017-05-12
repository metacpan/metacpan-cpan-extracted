#!perl
#
# This file is part of Language-Befunge
#
# This software is copyright (c) 2003 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

use Language::Befunge::Ops;

use strict;
use warnings;

use Language::Befunge::Interpreter;
use Language::Befunge::IP;
use Language::Befunge::Ops;
use Language::Befunge::Vector;
use Test::More tests => 15;

my ($lbi, $ip, $v);


$lbi = Language::Befunge::Interpreter->new;
$ip  = Language::Befunge::IP->new;
$v   = Language::Befunge::Vector->new(1,0);
$ip->set_delta( $v );
is($ip->scount, 0, 'toss is empty by default');
is($ip->ss_count, 0, 'no soss by default');
$ip->spush(6, 7, 8, 9, 0);
$lbi->set_curip( $ip );
$lbi->store_code('12345');
Language::Befunge::Ops::block_open( $lbi );
is($ip->scount, 0, 'new toss is empty');
is($ip->ss_count, 1, 'soss exists');
is($ip->soss_count, 6, 'new soss has 6 entries');
$ip->spush(3);
Language::Befunge::Ops::bloc_transfer( $lbi );
is($ip->scount, 3, 'toss has 3 entries');
is($ip->soss_count, 3, 'soss has 3 entries');
is($ip->get_delta(), '(1,0)', 'bloc_transfer did not bounce');
$ip->spush(-1);
Language::Befunge::Ops::bloc_transfer( $lbi );
is($ip->scount, 2, 'toss has 2 entries');
is($ip->soss_count, 4, 'soss has 4 entries');
is($ip->get_delta(), '(1,0)', 'bloc_transfer did not bounce');
Language::Befunge::Ops::block_close( $lbi );
$ip->spush(-1);
is($ip->scount, 3, 'toss has 3 entries');
is($ip->ss_count, 0, 'no soss');
Language::Befunge::Ops::bloc_transfer( $lbi );
is($ip->scount, 3, 'bloc_transfer error leaves toss untouched');
is($ip->get_delta(), '(-1,0)', 'bloc_transfer bounces when soss does not exist');
