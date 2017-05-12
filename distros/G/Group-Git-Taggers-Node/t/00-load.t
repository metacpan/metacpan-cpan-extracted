#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;

BEGIN {
    use_ok( 'Group::Git::Taggers::Node' );
}

diag( "Testing Group::Git::Taggers::Node $Group::Git::Taggers::Node::VERSION, Perl $], $^X" );
done_testing();
