#!perl -T

BEGIN { require './t/test.pl' }

use Test::More tests => 5;
use strict;
use utf8;

# Test 1: See if the module loads
BEGIN { use_ok('JE') };


my $j = new JE;

$j->prop({
	name => 'only_read',
	value  => $j->upgrade('anything will do'),
	readonly => 1,
});
$j->prop({
	name => 'delete_me_if_you_can',
	value  => $j->upgrade('anything will do'),
	dontdel => 1,
});
$j->prop({
	name => 'unlisted',
	value  => $j->upgrade('anything will do'),
	dontenum => 1,
});


# Test 2: Bind the ok function
isa_ok( $j->new_function( ok => \&ok ), 'JE::Object::Function' );


# Run JS tests

defined $j->eval( <<'--end--' ) or die;

//test 3
only_read = 'Well?'
ok(only_read === 'anything will do', 'can\'t change readonly properties')

//test 4
for(var p in this) p == 'unlisted' && (found_unlisted = true)
ok(!this.found_unlisted,
	'unenumerable properties are unenumerated by for-in')

//test 5
ok(!delete delete_me_if_you_can && 'delete_me_if_you_can' in this,
	'can\'t delete undeleteables')

--end--
