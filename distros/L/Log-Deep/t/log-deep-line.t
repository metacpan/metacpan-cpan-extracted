#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Warnings;
use Data::Dumper qw/Dumper/;

use Log::Deep::Line;

my $deep = Log::Deep::Line->new();
isa_ok( $deep, 'Log::Deep::Line', 'Can create a log object');

# TESTING the parse line method
$deep->parse( 'date,session,level,message,$DATA={};', { name => 'test' } );
is( $deep->{date}       , 'date', 'The data structure is as expected' );
is( $deep->{session}    , 'session', 'The data structure is as expected' );
is( $deep->{level}      , 'level', 'The data structure is as expected' );
is( $deep->{message}    , 'message', 'The data structure is as expected' );
is_deeply( $deep->{DATA}, {}, 'The data structure is as expected' );

$deep->parse( 'date,session,level,message \, test\n,$DATA={};', { name => 'test' } );
is( $deep->{date}       , 'date', 'The data structure is as expected' );
is( $deep->{session}    , 'session', 'The data structure is as expected' );
is( $deep->{level}      , 'level', 'The data structure is as expected' );
is( $deep->{message}    , "message , test\n", 'The data structure is as expected' );
is_deeply( $deep->{DATA}, {}, 'The data structure is as expected' );

# Testing show_line method
$deep->parse( 'date,session,level,message \, test\n,$DATA={};', { name => 'test' } );
ok( $deep->show(), 'Ordinarly the line is displayed');
$deep->parse( ',session,level,message \, test\n,$DATA={};', { name => 'test' } );
ok( !$deep->show(), 'no data the line is not displayed');
done_testing();
