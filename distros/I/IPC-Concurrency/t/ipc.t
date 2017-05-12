#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'tests' => 13;
use Test::Exception;

use FindBin;
use lib "$FindBin::Bin/../lib";
use IPC::Concurrency;

{
    dies_ok( sub { IPC::Concurrency->new() }, 'new() name missing' );
    dies_ok( sub { IPC::Concurrency->new('1a$!') }, 'new() name out of range' );

    my $c;
    lives_ok( sub { $c = IPC::Concurrency->new('TESA') },
        'new() name correct' );

    dies_ok( sub { $c->get_slot() },      'get_slot() count missing' );
    dies_ok( sub { $c->get_slot('abc') }, 'get_slot() count not numeric' );
    dies_ok( sub { $c->get_slot(0) },     'get_slot() count out of range' );
    dies_ok( sub { $c->get_slot(-1) },    'get_slot() count out of range' );
    dies_ok( sub { $c->get_slot(1025) },  'get_slot() count out of range' );
    lives_ok( sub { $c->get_slot(32) }, 'get_slot() count correct' );
}

{
    my $c;
    lives_ok( sub { $c = IPC::Concurrency->new('TESB') },
        'new() name correct' );

    if ( my $pid = fork() ) {
        sleep 1;    #wait for child to spawn
        ok( $c->get_slot(2), 'get_slot() approved' );
        kill 'KILL', $pid;    # kill child
    }
    else {
        $c->get_slot(2);
        sleep 1024;
    }
}

{
    my $c;
    lives_ok( sub { $c = IPC::Concurrency->new('TESC') },
        'new() name correct' );

    if ( my $pid = fork() ) {
        sleep 1;    #wait for child to spawn
        ok( !$c->get_slot(1), 'get_slot() rejected' );
        kill 'KILL', $pid;    # kill child
    }
    else {
        $c->get_slot(1);
        sleep 1024;
    }
}
