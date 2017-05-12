#!/usr/bin/perl -w
use strict;

use Lingua::EN::NameCase qw( NameCase nc );
use Test::More  tests => 7;

eval { NameCase() };
like($@,qr/NameCase only accepts/,'.. missing parameters, no error');
eval { NameCase( { 'trent' => 'reznor' } ) };
like($@,qr/Usage/,'.. hash not scalar(ref) or array(ref)');

my $res = 'test';

eval { $res = nc() };
is($@,'','.. missing parameters, no error');
is($res,undef,'.. missing parameters, no result');
eval { nc( { 'trent' => 'reznor' } ) };
like($@,qr/Usage/,'.. hash not scalar(ref)');
eval { nc( [ 'trent', 'reznor' ] ) };
like($@,qr/Usage/,'.. array not scalar(ref)');

eval { nc( 'trent', 'reznor' ) };
like($@,qr/Usage/,'.. mulitple strings not supported');
