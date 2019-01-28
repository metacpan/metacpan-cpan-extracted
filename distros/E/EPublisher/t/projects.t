#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use File::Basename;
use EPublisher;


my $publisher = EPublisher->new;

$publisher->_config( 1, 'test' );
is_deeply [$publisher->projects], [];

$publisher->_config( 1, [1] );
is_deeply [$publisher->projects], [];

$publisher->config( dirname(__FILE__) . '/config/test.yml' );

is_deeply [ $publisher->projects ], ['Testproject'];

done_testing();

