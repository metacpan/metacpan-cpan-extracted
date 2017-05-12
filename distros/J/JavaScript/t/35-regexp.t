#!perl

use strict;
use warnings;
use Data::Dumper;
use Test::More 'no_plan';

use_ok('JavaScript');
ok( my $rt = JavaScript::Runtime->new );
ok( my $cx = $rt->create_context );

ok( my $res = $cx->eval(q!/foo/!) );
diag(Dumper( $res ));
isa_ok($res, 'Regexp');
