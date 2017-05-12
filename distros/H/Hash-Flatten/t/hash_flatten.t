#!/usr/local/bin/perl -w

###############################################################################
# Purpose : Unit test for Hash::Flatten
# Author  : John Alden
# Created : Feb 2002
# CVS     : $Header: /home/cvs/software/cvsroot/hash_flatten/t/hash_flatten.t,v 1.21 2009/05/09 12:42:02 jamiel Exp $
###############################################################################
# -t : trace
# -T : deep trace into modules
###############################################################################

use strict;
use Test::Assertions qw(test);
use Getopt::Std;
use Log::Trace;

use vars qw($opt_t $opt_T);
getopts("tT");

plan tests;

#Compile the code
chdir($1) if($0 =~ /(.*)(\/|\\)(.*)/);
unshift @INC, "./lib", "../lib";

#Override warn() first, then compile
my $buf;
{
	BEGIN {$^W = 0}
	*CORE::GLOBAL::warn = sub {$buf = shift()};
	require Hash::Flatten;
}
ASSERT($INC{'Hash/Flatten.pm'}, 'loaded');

import Log::Trace qw(print) if ($opt_t);
deep_import Log::Trace qw(print) if ($opt_T);

#############################################################
#
# Nested hashes
#
#############################################################

my $data =
{
	'x' => 1,
	'y' => {
		'a' => 2,
		'b' => {
			'p' => 3,
			'q' => 4
		},
	}
};

my $flat_data = {
	'x' => 1,
	'y.a' => 2,
	'y.b.p' => 3,
	'y.b.q' => 4
};

my $flat = Hash::Flatten::flatten($data);
DUMP($flat);
ASSERT EQUAL($flat, $flat_data), 'nested hashes';

my $unflat = Hash::Flatten::unflatten($flat);
DUMP($unflat);
ASSERT EQUAL($unflat, $data), 'nested hashes unflattened';

#############################################################
#
# Nested hashes with weird values
#
#############################################################

my $data =
{
	'x' => 1,
	'0' => {
		'1' => 2,
		'' => {
			'' => 3,
			'q' => 4
		},
	},
	'a' => [1,2,3],
	'' => [4,5,6],
};

my $flat_data = {
	'x' => 1,
	'0.1' => 2,
	'0..' => 3,
	'0..q' => 4,
	'a:0' => 1,
	'a:1' => 2,
	'a:2' => 3,
	':0' => 4,
	':1' => 5,
	':2' => 6,
};

my $flat = Hash::Flatten::flatten($data);
DUMP($flat);
ASSERT EQUAL($flat, $flat_data), 'nested hashes with weird values';

my $unflat = Hash::Flatten::unflatten($flat);
DUMP($unflat);
ASSERT EQUAL($unflat, $data), 'nested hashes with weird values unflattened';

#############################################################
#
# Mixed hashes/arrays
#
#############################################################

my $foo = 'hello';
$data =
{
	'x' => 1,
	'ay' => {
		'a' => 2,
		'b' => {
			'p' => 3,
			'q' => 4
		},
	},
	's' => \\\$foo,
	'y' => [
		'a', 2,
		{
			'baz' => 'bum',
		},
	]
};

$flat_data = {
	'ay*b*p' => 3,
	'ay*b*q' => 4,
	's' => 'hello',
	'ay*a' => 2,
	'y%2*baz' => 'bum',
	'x' => 1,
	'y%0' => 'a',
	'y%1' => 2
};

$flat = Hash::Flatten::flatten($data, {'HashDelimiter' => '*', 'ArrayDelimiter' => '%'});
DUMP($flat);
ASSERT EQUAL($flat, $flat_data), 'heterogeneous structure';

$unflat = Hash::Flatten::unflatten($flat, {'HashDelimiter' => '*', 'ArrayDelimiter' => '%'});
DUMP($unflat);
ASSERT EQUAL($unflat,
	{ ### NB we can't compare to $data here because we flatten out scalar refs
		'x' => 1,
		'y' => [
			'a',
			2,
			{
				'baz' => 'bum'
			}
		],
		'ay' => {
			'a' => 2,
			'b' => {
				 'p' => 3,
				 'q' => 4
			}
		},
		's' => 'hello'
	}
), 'heterogeneous structure unflattened';

#############################################################
#
# Deeply nested arrays
#
#############################################################

$data =
{
	'x' => 1,
	'y' => [
		[
			'a', 'fool', 'is',
		],
		[
			'easily', [ 'parted', 'from' ], 'his'
		],
		'money',
	]
};

$flat_data = {
	'y:1:2' => 'his',
	'x' => 1,
	'y:1:1:0' => 'parted',
	'y:1:1:1' => 'from',
	'y:2' => 'money',
	'y:0:0' => 'a',
	'y:1:0' => 'easily',
	'y:0:1' => 'fool',
	'y:0:2' => 'is'
};

$flat = Hash::Flatten::flatten($data);
DUMP($flat);
ASSERT EQUAL($flat, $flat_data), 'nested arrays';

$unflat = Hash::Flatten::unflatten($flat);
DUMP($unflat);
ASSERT EQUAL($unflat, $data), 'nested arrays unflattened';

#############################################################
#
# Trivial cases
#
#############################################################

$data = {
};

$flat_data = {
};

$flat = Hash::Flatten::flatten($data);
DUMP($flat);
ASSERT EQUAL($flat, $flat_data), 'empty hash';

$unflat = Hash::Flatten::unflatten($flat);
DUMP($unflat);
ASSERT EQUAL($unflat, $data), 'empty hash unflattened';

$data = {
	'x' => 1,
};

$flat_data = {
	'x' => 1,
};

$flat = Hash::Flatten::flatten($data);
DUMP($flat);
ASSERT EQUAL($flat, $flat_data), '1 key';

$unflat = Hash::Flatten::unflatten($flat);
DUMP($unflat);
ASSERT EQUAL($unflat, $data), '1 key unflattened';

#############################################################
#
# Very long delimiters
#
###########################################################

$data =
{
	'x' => 1,
	'ay' => {
		'a' => 2,
		'b' => {
			'p' => 3,
			'q' => 4
		},
	},
	's' => 'hey',
	'y' => [
		'a', 2,	{
			'baz' => 'bum',
		},
	]
};

$flat_data = {
	'x' => 1,
	's' => 'hey',
	'ay*Issa Hash*a' => 2,
	'y%This Is an Array!!%%2*Issa Hash*baz' => 'bum',
	'ay*Issa Hash*b*Issa Hash*p' => 3,
	'y%This Is an Array!!%%0' => 'a',
	'ay*Issa Hash*b*Issa Hash*q' => 4,
	'y%This Is an Array!!%%1' => 2
};

$flat = Hash::Flatten::flatten($data, {'HashDelimiter' => '*Issa Hash*', 'ArrayDelimiter' => '%This Is an Array!!%%'});
DUMP($flat);
ASSERT EQUAL($flat, $flat_data), 'long delimiters';

$unflat = Hash::Flatten::unflatten($flat, {'HashDelimiter' => '*Issa Hash*', 'ArrayDelimiter' => '%This Is an Array!!%%'});
DUMP($unflat);
ASSERT EQUAL($unflat, $data), 'long delimiters unflattened';

###########################################################
#
# Scalar refs, blessed refs etc
#
###########################################################

my $scal = 'scalar';
my $again = 'again!';
$data = bless({
	'x' => bless({'foo'=>'bar'}, 'Foo::Hash'),
	'y' => bless(['f', 'g'], 'Bar::Array'),
	'z' => bless(\$scal, 'Qux:Scalar'),
	'r' => bless(\\\\\$again, 'Qux Ref'),
	'rina' => [\$scal, \\$again],
	'gref' => \*FH,
}, 'Template');

DUMP($data);
$flat_data = {
	'z' => 'scalar',
	'r' => 'again!',
	'x.foo' => 'bar',
	'y:0' => 'f',
	'y:1' => 'g',
	'rina:0' => 'scalar',
	'rina:1' => 'again!',
	'gref' => \*FH,
};

$flat = Hash::Flatten::flatten($data);
DUMP($flat);
ASSERT EQUAL($flat, $flat_data), 'blessed references';

$unflat = Hash::Flatten::unflatten($flat);
DUMP($unflat);
ASSERT EQUAL($unflat, {
	'x' => {
		'foo' => 'bar'
	},
	'y' => [
		'f',
		'g'
	],
	'r' => 'again!',
	'z' => 'scalar',
	'rina' => ['scalar', 'again!'],
	'gref' => \*FH,
}), 'objects and blessed refs unflattened';

###########################################################
#
# OO Interface and callbacks
#
###########################################################

my $counter = 0;
my $o = new Hash::Flatten({
	'OnRefRef' => sub {
		my $v = shift;
		$counter++;
		return $$v; #follow	
	},
	'OnRefScalar' => sub {
		my $v = shift;
		$counter--;
		return $$v; #follow	
	},
	'OnRefGlob' => sub {
		my $v = shift;
		$counter--;
		return "A-GLOB";
	}
});

# Test coderef for handling refs
$flat = $o->flatten({a => \\\\\"x"});
DUMP($flat);
ASSERT($counter == 3, "coderef called $counter times");
$flat = $o->flatten({a => \*FH});
DUMP($flat);
ASSERT($counter == 2 && $flat->{a} eq 'A-GLOB', "globref callback");

###########################################################
#
# Escaping
#
###########################################################

my $orig = {
	a => ['1.1', '1.2', '2.1'],
	'b:c' => {e => '3.1'}	
};
$flat = Hash::Flatten::flatten($orig);
DUMP($flat);
$unflat = Hash::Flatten::unflatten($flat);
DUMP($unflat, $orig);
ASSERT(EQUAL($orig, $unflat), "escaping");

$orig = {'a' => {'A[ESC]B' => 'c[ESC]', 'C.D' => 'd:e'}};
$flat = Hash::Flatten::flatten($orig, {EscapeSequence => '[ESC]'});
DUMP($flat);
$unflat = Hash::Flatten::unflatten($flat, {EscapeSequence => '[ESC]'});
DUMP($unflat, $orig);
ASSERT(EQUAL($orig, $unflat), "custom escape seq");

###########################################################
#
# Error checking
#
###########################################################

ASSERT(DIED( sub{ Hash::Flatten::flatten([1,2,3]) } ) && scalar $@ =~ /1st arg must be a hashref/, "type check in flatten");
ASSERT(DIED( sub{ Hash::Flatten::unflatten([1,2,3]) } ) && scalar $@ =~ /1st arg must be a hashref/, "type check in unflatten");

ASSERT(
	DIED( sub{ Hash::Flatten::flatten({}, {EscapeSequence => '.'}) })
	&& scalar $@ =~ /Hash delimiter cannot contain escape sequence/
, "check hash delim for esc seq");

ASSERT(
	DIED( sub{ Hash::Flatten::flatten({}, {EscapeSequence => ':'}) })
	&& scalar $@ =~ /Array delimiter cannot contain escape sequence/
, "check array delim for esc seq");

$data = {
		'y' => {
			'a' => 2,
			'b' => 3
		},
};
$data->{'y'}->{'c'} = $data;
DUMP($data);
ASSERT( DIED( sub { Hash::Flatten::flatten( $data ) } ), 'recursive data structure detected in hashref');

$data = {
		'y' => {
			'a' => 2,
			'b' => 3
		},
};
$data->{y}->{c} = \$data;
DUMP($data);
ASSERT( DIED( sub { Hash::Flatten::flatten( $data ) } ), "recursive data structure detected in ref-ref");

$data = {
		'y' => {
			'a' => 2,
			'b' => 3
		},
};
$data->{'y'}->{'c'} = [1];
push @{$data->{'y'}->{'c'}}, $data->{'y'}->{'c'};
DUMP($data);
ASSERT( DIED( sub { Hash::Flatten::flatten( $data ) } ), "recursive data structure detected in arrayref");

ASSERT(
	DIED( sub{ Hash::Flatten::flatten({a => \[1,2]}, {OnRefRef => "die"}) })
	&& scalar $@ =~ /is a REF/
, "check ref to ref raises exception");

ASSERT(
	DIED( sub{ Hash::Flatten::flatten({a => \"x"}, {OnRefScalar => "die"}) })
	&& scalar $@ =~ /is a SCALAR/
, "check ref to scalar raises exception");

ASSERT(
	DIED( sub{ Hash::Flatten::flatten({a => \*FH}, {OnRefGlob => "die"}) })
	&& scalar $@ =~ /is a GLOB/
, "check ref to glob raises exception");

my $rv = Hash::Flatten::flatten({a => \[1,2]}, {OnRefRef => "warn"});
DUMP($rv);
TRACE($buf);
ASSERT(scalar $buf =~ /is a REF and will be followed/ && EQUAL($rv, {
	'a:0' => 1,
	'a:1' => 2
}), "warn mode works as expected");

$rv = Hash::Flatten::flatten({a=>"m:o.o", "o:i.n:k" => {a=>1}},{EscapeSequence => "#", DisableEscapes => 0});
DUMP($rv);
ASSERT(
	EQUAL($rv,{a => 'm:o.o','o#:i#.n#:k.a' => 1}),
	"Escapes on, returned escaped hash"
);    
$rv = Hash::Flatten::unflatten({a => 'm:o.o','o#:i#.n#:k.a' => 1},{EscapeSequence => "#", DisableEscapes => 0});
DUMP($rv);
ASSERT(
	EQUAL($rv,{a=>"m:o.o", "o:i.n:k" => {a=>1}}),
	"Escapes on, unescaped hash correctly"
);    

$rv = Hash::Flatten::flatten({a=>"m:o.o", "o:i.n:k" => {a=>1}},{EscapeSequence => "#", DisableEscapes => 1});
DUMP($rv);
ASSERT(
	EQUAL($rv,{a => 'm:o.o','o:i.n:k.a' => 1}),
	"Escapes off, returned nonsense"
);    
$rv = Hash::Flatten::unflatten({a => 'm:o.o','o#:i#.n#:k.a' => 1},{EscapeSequence => "#", DisableEscapes => 1});
DUMP($rv);
ASSERT(
	EQUAL($rv,{a => 'm:o.o','o#' => [{'n#' => [{a => 1}]}]}),
	"Escapes off, didn't unescape hash"
);    

