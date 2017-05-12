#!perl

use strict;
use warnings;
use lib 't/lib';

use Capture::Tiny qw/capture/;
use Dist::Zilla::App::Tester;
use Test::DZil;
use Test::Requires { 'Dist::Zilla::Tester' => 4.300017 };
use Test::More 0.88;
use Try::Tiny;

## XT FILE GUTS
my $xt_file = << 'HERE';
use Test::More tests => 1;
use Foo;
is(Foo::foo(), 456);
HERE

## Tests start here

{
    my $tzil = Dist::Zilla::Tester->from_config(
        { dist_root => 'corpus/WithBlib' },
        { add_files => { 'source/xt/checkme.t' => $xt_file, }, },
    );
    ok( $tzil, "created test dist that depends on the 'make' step" );

    capture { $tzil->release };

    ok(
        !grep( {/Fatal errors in xt/i} @{ $tzil->log_messages } ),
        "No xt errors logged",
    );
    ok(
        grep( {/fake release happen/i} @{ $tzil->log_messages } ),
        "FakeRelease executed",
    );

}

done_testing;

