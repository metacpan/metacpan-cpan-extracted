# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Encode-Korean.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 8;
BEGIN { 
	use_ok('Encode::Korean::TransliteratorGenerator');
	};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

ok $coder = Encode::Korean::TransliteratorGenerator->new(), 'object created';

@CONSONANTS = qw(g kk n d tt r m b pp s ss ng j jj ch k t p h);
@VOWELS = qw(a ae ya yae eo e yeo ye o wa wae oe yo u wo we wi yu eu ui i);
$SEP = "-";

ok $coder->consonants(@CONSONANTS), 'set consonants';
ok $coder->vowels(@VOWELS), 'set vowels';
ok $coder->sep($SEP), 'set sep';
ok $coder->make(), 'make';
ok $coder->enmode('greedy'), 'enmode';
ok $coder->enmode('greedy'), 'demode';



