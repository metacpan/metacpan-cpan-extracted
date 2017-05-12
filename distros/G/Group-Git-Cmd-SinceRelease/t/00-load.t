#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;

BEGIN {
    use_ok( 'Group::Git::Cmd::SinceRelease' );
}

diag( "Testing Group::Git::Cmd::SinceRelease $Group::Git::Cmd::SinceRelease::VERSION, Perl $], $^X" );
done_testing();
