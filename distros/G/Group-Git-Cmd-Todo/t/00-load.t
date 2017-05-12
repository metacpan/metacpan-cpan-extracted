#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;

BEGIN {
    use_ok( 'Group::Git::Cmd::Todo' );
}

diag( "Testing Group::Git::Cmd::Todo $Group::Git::Cmd::Todo::VERSION, Perl $], $^X" );
done_testing();
