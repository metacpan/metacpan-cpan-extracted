#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;

BEGIN {
    use_ok( 'Group::Git::Taggers::Perl' );
}

diag( "Testing Group::Git::Taggers::Perl $Group::Git::Taggers::Perl::VERSION, Perl $], $^X" );
done_testing();
