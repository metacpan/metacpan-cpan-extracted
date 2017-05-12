#! perl -T

use strict;
use warnings;

use Test::More tests => 60;

use_ok( 'Mail::SimpleList::Alias' ) or exit;
can_ok( 'Mail::SimpleList::Alias', 'new' );

my $alias = Mail::SimpleList::Alias->new();
isa_ok( $alias, 'Mail::SimpleList::Alias' );

can_ok( $alias, 'members' );
is( @{ $alias->members() }, 0,
	'new() should create alias with no default members' );

$alias = Mail::SimpleList::Alias->new( members => [qw( foo bar baz )] );
is( @{ $alias->members() }, 3,
	                              '... populating them from constructor args' );
is_deeply( $alias->members(),
	[qw( foo bar baz )],          '... saving literal values');

can_ok( $alias, 'add' );
$alias->add( 'quux' );
my %members = map { $_ => 1 } @{ $alias->members() };

is( keys %members, 4,            'add() should add a member to the group' );
ok( exists $members{quux},       '... with the given name' );

$alias->add( 'foo' );
is( @{ $alias->members() }, 4,   '... but not a duplicate' );

my @result = $alias->add( 'xyzzy', 'plugh' );
is( @{ $alias->members() }, 6,   '... adding multiple addresses at once' );
is( @result, 2,                  '... returning the number added' );
is_deeply( \@result,
	[ 'xyzzy', 'plugh' ],        '... or the added members, in list context' );

$alias->add( 'plugh <xyzzy>' );
is( @{ $alias->members() }, 6,   '... but not duplicates with different names');

can_ok( $alias, 'remove_address' );
my $result = $alias->remove_address( 'bar' );
is( @{$alias->members()}, 5,
	                 'remove_address() should remove a member from the group' );
is_deeply( $alias->members(), [qw( foo baz quux xyzzy plugh )],
	                 '... preserving other members in order' );

ok( $result,                           '... returning true on success' );
ok( ! $alias->remove_address( 'bar' ), '... and false on failure' );
$alias->remove_address( 'you' );
is( $alias->owner(), '',               '... blankening owner, if needed' );

can_ok( $alias, 'owner' );
$alias = Mail::SimpleList::Alias->new( owner => 'me' );
is( $alias->owner(), 'me',        'owner() should be settable in constructor' );

is( Mail::SimpleList::Alias->new()->owner(), '',
	                                     '... with a blank default' );

$alias->owner( 'you' );

is( $alias->owner(), 'you',              '... and should set owner' );
ok( grep('you', @{ $alias->members() }), '... adding owner to list if needed' );

can_ok( $alias, 'closed' );
$alias = Mail::SimpleList::Alias->new( closed => 1 );
is( $alias->closed(), 1,          'closed() should report constructor status' );
is( Mail::SimpleList::Alias->new()->closed(),
	0,                            '... with a false default' );
$alias->closed( 0 );
is( $alias->closed(), 0,          '... and should be able to set alias' );
$alias->closed( 'true' );
is( $alias->closed(), 1,          '... only to true or false values' );

can_ok( $alias, 'process_time' );
is( $alias->process_time( 100 ), 100,
	                      'process_time() should return raw seconds directly' );
is( $alias->process_time( '1d' ), 24 * 60 * 60,
	                      '... processing days correctly' );
is( $alias->process_time( '2w' ), 2 * 7 * 24 * 60 * 60,
	                      '... processing weeks correctly' );
is( $alias->process_time( '4h' ), 4 * 60 * 60,
	                      '... processing hours correctly' );
is( $alias->process_time( '8m' ), 8 * 60,
	                      '... processing minutes correctly' );
is( $alias->process_time( '16M' ), 16 * 30 * 24 * 60 * 60,
	                      '... processing months correctly' );
is( $alias->process_time( '1M2w3d4h5m' ),
	   30 * 24 * 60 * 60 +
	2 * 7 * 24 * 60 * 60 +
	3     * 24 * 60 * 60 +
	4     * 60 * 60 +
	5          * 60,     '... even in a nice list' );

can_ok( $alias, 'expires' );
$alias = Mail::SimpleList::Alias->new( expires => 1003 );
is( $alias->expires(), 1003,
	'expires() should report expiration time from constructor' );
is( Mail::SimpleList::Alias->new()->expires(), 0, '... with a false default' );
my $expiration = time() + 100;
$alias->expires( 100 );
ok( $alias->expires() - $expiration < 10, '... and should set expiration' )
	or diag "Possible clock skew: (" . $alias->expires() . ") [$expiration]\n";

my $time = time() + 7 * 24 * 60 * 60;
is( $alias->expires( '7d' ), $time, '... parsing days correctly' );

can_ok( $alias, 'attributes' );
isa_ok( $alias->attributes(),
	'HASH',                     'attributes() should return a reference to a' );
is_deeply( $alias->attributes(),
	{ owner => 1, closed => 1, expires => 1, auto_add => 1,
		description => 1, name => 1 },
	                            '... with the correct keys' );

can_ok( $alias, 'auto_add' );
$alias = Mail::SimpleList::Alias->new();
ok( $alias->auto_add(), 'auto_add() should be true by default' );
$alias->auto_add( 'no' );
ok( ! $alias->auto_add(), '... disableable by the mutator call with "no"' );
$alias = Mail::SimpleList::Alias->new( auto_add => 0 );
ok( ! $alias->auto_add(), '... and in constructor' );

for my $accessor (qw( description name ))
{
	can_ok( $alias, $accessor );
	$alias->$accessor( 'foo' );
	is( $alias->$accessor(), 'foo', "$accessor() should be mutator" );
	$alias = Mail::SimpleList::Alias->new( $accessor => 'bar' );
	is( $alias->$accessor(), 'bar', '... with value settable in constructor' );
}

$alias = Mail::SimpleList::Alias->new();
is( $alias->description(), '',    'description() should be blank by default' );
is( $alias->name(), undef,        'name() should be unset by default' );
$alias->name( 'abc_123-)(*&$%(*&!|' );
is( $alias->name(), 'abc_123-',   '... stripping out non-word characters' );
