#!/usr/bin/env perl
use Test::More;
use lib 'lib';

use Git::Release;
use Git::Release::Config;

my $re = Git::Release->new;
my $config = $re->config;

ok( $config->ready_prefix , $config->ready_prefix );
ok( $config->release_prefix , $config->release_prefix );
ok( $config->develop_branch , $config->develop_branch );

done_testing;
