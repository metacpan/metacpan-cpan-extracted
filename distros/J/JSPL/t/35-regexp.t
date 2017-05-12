#!perl

use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 3;
use Test::Exception;
use JSPL;

my $rt = JSPL::Runtime->new;
{
    my $cx = $rt->create_context;
    ok( my $res = $cx->eval(q|expfoo = /foo/i; expfoo |), "regexes travels");
    isa_ok($res, 'Regexp');
    diag(Dumper( $res ));
}
ok(1, "All done, clean");
