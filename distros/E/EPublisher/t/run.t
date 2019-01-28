#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use File::Basename;
use EPublisher;

my $debug = '';

my $publisher = EPublisher->new;
$publisher->config( dirname(__FILE__) . '/config/run_test.yml' );
$publisher->_debug( sub { $debug = $_[1] } );

is $publisher->run( ['Hallo'] ), 1;
is $publisher->run( ['NoSource'] ), 1;
is $publisher->run( ['SourceString'] ), 1;
is $publisher->run( ['SourceArray'] ), 1;
is $publisher->run( ['NoPod'] ), 1;

{
    my $error = '';
    eval {
        $publisher->run( ['NoSourceType'] );
        1;
    } or $error = $@;
    
    like $error, qr/No type in source./;
}

is $publisher->run( ['NoTargetType'] ), 1;
is $publisher->run( ['NoTarget'] ), 1;

done_testing();

