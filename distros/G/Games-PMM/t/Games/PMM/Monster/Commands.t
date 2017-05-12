#!/usr/bin/perl -w

BEGIN
{
	chdir 't' if -d 't';
	use lib '../lib', '../blib/lib';
}

use strict;
use Test::More tests => 8;

my $module = 'Games::PMM::Monster::Commands';
use_ok( $module ) or exit;

can_ok( $module, 'new' );
my $commands = $module->new( split(/\n/, <<END_HERE) );
command_1 arg1 arg2
command_2 arg1
END_HERE

isa_ok( $commands, $module );

can_ok( $module, 'next' );
is_deeply( [ $commands->next() ], [qw( command_1 arg1 arg2 )],
	'next() should return first command and args' );
is_deeply( [ $commands->next() ], [qw( command_2 arg1 )],
	'... then second' );

is(   $commands->next(),              undef,
	'... returning nothing after reaching end' );
is( [ $commands->next() ]->[0], 'command_1',
	'... restarting after end' );
