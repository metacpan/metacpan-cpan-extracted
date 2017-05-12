#!/usr/bin/perl -Tw

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 2.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

#use Test::More tests => 4;
use Test::More 'no_plan';
#BEGIN { use_ok('Lingua::SA') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use Lingua::SA qw(transliterate);
my %transliterated_of = (
	'a'		=> '&#2309; ', 
	'aa'	=> '&#2310; ',
	'A'		=> '&#2310; ',
	'i'		=> '&#2311; ',
	'ii'	=> '&#2312; ',
	'I'		=> '&#2312; ',
	'u'		=> '&#2313; ',
	'uu'	=> '&#2314; ',
	'U'		=> '&#2314; ',
	'e'		=> '&#2319; ',
	'k'		=> '&#2325;&#2381; ',
	'ka'	=> '&#2325; ',
	'kA'	=> '&#2325;&#2366; ',
	'kaa'	=> '&#2325;&#2366; ',
	'ki'	=> '&#2325;&#2367; ',
	'kI'	=> '&#2325;&#2368; ',
	'kii'	=> '&#2325;&#2368; ',
	'ku'	=> '&#2325;&#2369; ',
	'kU'	=> '&#2325;&#2370; ',
	'kuu'	=> '&#2325;&#2370; ',
	'klR'	=> '&#2325;&#2402; ',
	'CBa'	=> '&#2305; ',
	'L'		=> '&#2355;&#2381; ',
	);

for my $word (keys  %transliterated_of){
	my $expected = $transliterated_of{$word};
	my $computed = transliterate($word);
#	my $computed = transliterate(sandhi($word));

	# Test expected and computed transliteration for word equality
#	is( $computed, $expected, "$word -> $expected" );
	is( $computed, $expected, $expected );
	}
#########################
