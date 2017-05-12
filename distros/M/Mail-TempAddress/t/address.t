#!/usr/bin/perl -w

BEGIN
{
    chdir 't' if -d 't';
	use lib '../lib', '../blib/lib';
}

use strict;
use Test::More tests => 39;

my $module = 'Mail::TempAddress::Address';
use_ok( $module ) or exit;
can_ok( $module, 'new' );

my $add = $module->new();
isa_ok( $add, $module );

$add = $module->new( foo => 'bar', baz => 'quux' );
is_deeply( $add,   { foo => 'bar', baz => 'quux', expires => 0 },
	'new() should turn passed-in arguments into object attributes' );

can_ok( $module, 'name' );
$add = $module->new( name => 'my name' );
is( $add->name(), 'my name', 'name() should return name set in constructor' );
$add->name( 'foo# bar!' );
is( $add->name(), 'foobar',  '... or should set and return cleand new name' );

can_ok( $module, 'owner' );
$add = $module->new( owner => 'i own it' );
is( $add->owner(), 'i own it', 'owner() should return value from constructor' );

can_ok( $module, 'add_sender' );

my $result = $add->add_sender( 'foo' );
is( keys %{ $add->{senders} }, 1, 'add_sender() should add one sender' );

my ($key, $value) = each %{ $add->{senders} };
is( $value,   'foo',              '... containing the sender' );
is( $result,   $key,              '... returning key' );

is( $key =~ tr/a-f0-9//c, 0,      '... only hex digits in key' );

$result    = $add->add_sender( 'foo' );
is( $result,   $key,              '... always same key for same sender' );

$result    = $add->add_sender( 'bar' );
isnt( $result, $key,              '... never same key for different sender' );

can_ok( $module, 'get_key' );

can_ok( $module, 'get_sender' );

$result = $add->get_sender( $key );
is( $result, 'foo',                 'get_sender() should return sender by key');

$result = $add->get_sender( 'not a key' );
is( $result, undef,                 '... but only if key exists' );

can_ok( $add, 'process_time' );
is( $add->process_time( 100 ), 100,
	                      'process_time() should return raw seconds directly' );
is( $add->process_time( '1d' ), 24 * 60 * 60,
	                      '... processing days correctly' );
is( $add->process_time( '2w' ), 2 * 7 * 24 * 60 * 60,
	                      '... processing weeks correctly' );
is( $add->process_time( '4h' ), 4 * 60 * 60,
	                      '... processing hours correctly' );
is( $add->process_time( '8m' ), 8 * 60,
	                      '... processing minutes correctly' );
is( $add->process_time( '16M' ), 16 * 30 * 24 * 60 * 60,
	                      '... processing months correctly' );
is( $add->process_time( '1M2w3d4h5m' ),
	   30 * 24 * 60 * 60 +
	2 * 7 * 24 * 60 * 60 +
	3     * 24 * 60 * 60 +
	4     * 60 * 60 +
	5          * 60,     '... even in a nice list' );

can_ok( $add, 'expires' );
$add = Mail::TempAddress::Address->new( expires => 1003 );
is( $add->expires(), 1003,
	'expires() should report expiration time from constructor' );

is( Mail::TempAddress::Address->new()->expires(), 0,
	'... with a false default' );
my $expiration = time() + 100;
$add->expires( 100 );
ok( $add->expires() - $expiration < 10, '... and should set expiration' )
	or diag "Possible clock skew: (" . $add->expires() . ") [$expiration]\n";

my $time = time() + 7 * 24 * 60 * 60;
is( $add->expires( '7d' ), $time, '... parsing days correctly' );

can_ok( $add, 'description' );
$add = $module->new( description => 'my desc' );
is( $add->description(), 'my desc',
	'description() should return description set in constructor' );
$add = $module->new();
is( $add->description(), '',
	'... using blank description if none is provided' );

$add->description( 'foo bar' );
is( $add->description(), 'foo bar',
	'... or should set and return new description' );

can_ok( $add, 'attributes' );
is_deeply( $add->attributes(), { expires => 1, description => 1 },
	'attributes() should return hashref of allowed directives' );
