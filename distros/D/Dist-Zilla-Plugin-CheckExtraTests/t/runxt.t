#!perl

use strict;
use warnings;
use lib 't/lib';

use Capture::Tiny qw/capture/;
use Test::More 0.88;
use Try::Tiny;

use Test::Requires { 'Dist::Zilla::Tester' => 4.300017 };

## XT FILE GUTS
my $xt_fail = << 'HERE';
use Test::More tests => 1;
fail("doomed to fail");
HERE

local $ENV{RELEASE_TESTING};
local $ENV{AUTHOR_TESTING};
local $ENV{AUTOMATED_TESTING};

{
    my $tzil = Dist::Zilla::Tester->from_config(
        { dist_root => 'corpus/RunXT' },
        { add_files => { 'source/xt/author/checkme.t' => $xt_fail, }, },
    );
    ok( $tzil, "created test dist" );
    $tzil->chrome->logger->set_debug(1);

    try {
        capture { $tzil->test };
    }
    catch {
        my $err = $_;
        fail( $err );
        diag 'got log messages: ', explain $tzil->log_messages;
    };

    ok(
        grep( {/all's well/i} @{ $tzil->log_messages } ),
        "xt tests aren't run without explicitly asking for them",
    );
}

{
    my $tzil = Dist::Zilla::Tester->from_config(
        { dist_root => 'corpus/RunXT' },
        { add_files => { 'source/xt/author/checkme.t' => $xt_fail, }, },
    );
    ok( $tzil, "created test dist" );
    $tzil->chrome->logger->set_debug(1);

    local $ENV{AUTHOR_TESTING} = 1;
    try {
        capture { $tzil->test };
    }
    catch {
        my $err = $_;
        like( $err, qr/Fatal errors in xt/i, "RunExtraTests caught xt test failure in author test", );
    }
}

{
    my $tzil = Dist::Zilla::Tester->from_config( { dist_root => 'corpus/RunXT' }, );
    ok( $tzil, "created test dist" );
    $tzil->chrome->logger->set_debug(1);

    local $ENV{AUTHOR_TESTING} = 1;
    try {
        capture { $tzil->test };
    }
    catch {
        my $err = $_;
        fail( $err );
        diag 'got log messages: ', explain $tzil->log_messages;
    };

    ok(
        grep( {/all's well/i} @{ $tzil->log_messages } ),
        "handles nonexistent test dirs",
    );
}

{
    my $tzil = Dist::Zilla::Tester->from_config(
        { dist_root => 'corpus/RunXT' },
        { add_files => { 'source/xt/bleh' => 'this is not a runnable test!', }, },
    );
    ok( $tzil, "created test dist" );
    $tzil->chrome->logger->set_debug(1);

    local $ENV{AUTHOR_TESTING} = 1;
    try {
        capture { $tzil->test };
    }
    catch {
        my $err = $_;
        fail( $err );
        diag 'got log messages: ', explain $tzil->log_messages;
    };

    ok(
        grep( {/all's well/i} @{ $tzil->log_messages } ),
        "handles non-perl files in xt/",
    );
}

{
    my $tzil = Dist::Zilla::Tester->from_config(
        { dist_root => 'corpus/RunXT' },
        { add_files => { 'source/xt/checkme.t' => $xt_fail, }, },
    );
    ok( $tzil, "created test dist" );
    $tzil->chrome->logger->set_debug(1);

    try {
        capture { $tzil->test };
    }
    catch {
        my $err = $_;
        like( $err, qr/Fatal errors in xt/i, "RunExtraTests caught xt test failure in root directory", );
    }
}

done_testing;
