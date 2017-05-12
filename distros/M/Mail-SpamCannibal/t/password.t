# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..25\n"; }
END {print "not ok 1\n" unless $loaded;}
use Mail::SpamCannibal::Password qw(
        pw_gen
        pw_valid
        pw_obscure
        pw_clean
);

$loaded = 1;

######################### End of black magic.

$test = 1;
sub ok {print 'ok ',$test++,"\n";}

&ok;


# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

###### check little used pw_clean function

my $clrtxt ="once upon a time there were three LITTLE pigs in the f#%..ing
woods walking through the garden With goldilocks, not/that/it/matters much
for the purposes of this Exercise. The quick brown fox jumped over the lazy
dog without any effort.";

my $answer = 'onceuponatimetherewerethreeLITTLEpigsinthef..ingwoodswalkingthroughthegardenWithgoldilocksnot/that/it/mattersmuchforthepurposeso';
my $rv = pw_clean($clrtxt);

print $rv, '
ne
', $answer, "\nnot " unless $rv eq $answer;
&ok;

$_ = length $rv;

print "bad length, $_ \nnot " if $_ != 128;
&ok;

#### check pw_valid

$clrtxt		= 'Irene';
my $passwd	= 'UNmIBfykyjwnw';

print "invalid password $passwd for $clrtxt\nnot "
	unless pw_valid($clrtxt,$passwd);
&ok;

#### check pw_gen

foreach $clrtxt ('password one','Irene','double%talk','Some#of**hassles') {
  $passwd = pw_gen($clrtxt);
  print "password $passwd did not validate for $clrtxt\nnot "
	unless pw_valid($clrtxt,$passwd);
  &ok;
}

#### check pw_obscure

# first test should always return even if not obscure

print "failed on empty old password\nnot "
	if (pw_obscure('x'))[0];
&ok;

# fail if no new password

print "did not fail missing new password\nnot "
	unless (pw_obscure())[0] == 9;
&ok;

my @words = (	# Check for these simple failures
	'four',		# short password, < $MIN_LEN
	'Old%Password',	# password the same
	'OneissienO',	# palindrome
	'oLD%PaSsWord', # case change only
	'Old%pas',	# similar
	'simple',	# simple
	'wordOld%Pass',	# rotated
	'drowssaP%dlO',	# flipped
);
# the response code should be the array index + 1
foreach(0..$#words) {
  my($code,$err) = pw_obscure($words[$_],'Old%Password');
  print "failed code $code, ",$words[$_]," is not $err\nnot "
	if $code != $_ + 1;
  &ok;
}

#### test some more simple permutations

foreach $clrtxt (qw(
	SIMPLE
	SIMple
	SIM123
	sim123
	sim%pl
	123ABC
	)) {
  my($code,$err) = pw_obscure($clrtxt,'Old%Password');
  print "failed extra simple for $clrtxt\nnot "
	unless (pw_obscure($clrtxt,'Old%Password'))[0] == 6;
  &ok;
}

#### this is obscure

print "failed obscure\nnot "
	if (pw_obscure('A,01x','anything'))[0];
&ok;
