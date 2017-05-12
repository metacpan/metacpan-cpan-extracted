#!/usr/bin/perl

BEGIN { require './t/test.pl' }

use Test::More;
use Encode 'decode_utf8';
use JE;

$je = new JE;
$je->new_function(peval => sub { local *ARGV = \@_; eval "".shift })
	->{forTesting}++;
$je->new_function($_ => \&$_)->{forTesting}++
	for grep /^\w/, @Test::More::EXPORT;
$je->eval(<<'end');
// Every call to this runs 10 tests
function method_boilerplate_tests(proto,meth,length)
{
	is(typeof proto[meth], 'function', 'typeof ' + meth);
	is(Object.prototype.toString.apply(proto[meth]),
		'[object Function]',
		'class of ' + meth)
	ok(proto[meth].constructor === Function, meth + '\'s prototype')
	var $catched = false;
	try{ new proto[meth] } catch(e) { $catched = e }
	ok($catched, 'new ' + meth + ' fails')
	ok(!('prototype' in proto[meth]), meth +
		' has no prototype property')
	ok(proto[meth].length === length, meth + '.length')
	ok(! proto[meth].propertyIsEnumerable('length'),
		meth + '.length is not enumerable')
	ok(!delete proto[meth].length, meth + '.length cannot be deleted')
	is((proto[meth].length++, proto[meth].length), length,
		meth + '.length is read-only')
	ok(!Object.prototype.propertyIsEnumerable(meth),
		meth + ' is not enumerable')
}
function is_nan(n){ // checks to see whether the number is *really* NaN
                    // & not something which converts to NaN when numified
	return n!=n
}
end
$je->{$_}->{forTesting}++
	for qw 'method_boilerplate_tests is_nan';

{
	local $/;
	$code = <DATA>;
}

my $tests;
while($code =~ /^\/\/ (\d+) tests?\b/gm) {
	$tests += $1;
}
plan tests => $tests if $tests;

$code = $je->compile(decode_utf8($code), $0, 3);
$@ and die __FILE__ . ": Couldn't compile $0: $@";
execute $code;
$@ and die __FILE__ . ": $0: $@";

1;