#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;

BEGIN {
    use_ok( 'Group::Git::Taggers::Maven' );
}

diag( "Testing Group::Git::Taggers::Maven $Group::Git::Taggers::Maven::VERSION, Perl $], $^X" );
done_testing();
