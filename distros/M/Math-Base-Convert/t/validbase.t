# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..40\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Math::Base::Convert;

$loaded = 1;
print "ok 1\n";
######################### End of black magic.

$test = 2;

*validbase = \&Math::Base::Convert::validbase;

sub ok {
  print "ok $test\n";
  ++$test;
}

sub skipit {
  my($skipcount,$reason) = @_;
  $skipcount = 1 unless $skipcount;
  $reason = $reason ? ":\t$reason" : '';
  foreach (1..$skipcount) {
    print "ok $test     # skipped$reason\n";
    ++$test;
  }
}

# test for each valid internal base

# test 2	check fail on invalid numeric base
my $rv = eval {
	validbase(11);
};

print "accepted bad base '11'\nnot "
	unless $@ =~ /not a valid base\: 11/;
&ok;

# test 3	check fail for invalid string base
$rv = eval {
	validbase('xxx');
};

print "accepted bad base 'xxx'\nnot "
	unless $@ =~ /not a valid base\: xxx/;
&ok;

# test 4 - 8	check validity of each numeric base

my %num2sub = (
        2       => 'bin',
        8       => 'oct',
        10      => 'dec',
        16      => 'HEX',
        64      => 'm64'
);

foreach (sort keys %num2sub) {
  $rv = eval {
	validbase($_);
  };
  print "failed to find base '$_'\nnot "
	if $@ || ref $rv !~ /_bs\:\:$num2sub{$_}$/;
  &ok;
}

# test 9 - 25	check validity of each text value
foreach (qw( bin oct dec heX HEX b62 b64 m64 iru url rex id0 id1 xnt xid b85 )) {	# removed ebcdic
  $rv = eval {
	validbase($_);
  };
  print "failed to find base '$_'\nnot "
	if $@ || ref $rv !~ /_bs\:\:$_$/;
  &ok;
}

#skipit(1,'removed');									# removed ebcdic
&ok;

# test 26	check invalid reference
$rv = eval {
	validbase({});		# invalid hash reference
};
print "accepted bad hash reference as base\nnot "
	unless $@ =~ /not a valid base\: reference/;
&ok;

# test 27	check valid user array
my $ua = [0..11];
$rv = eval {
	validbase($ua);
};
print "failed to accept user base\nnot "
	if $@ || ref $rv !~ /_bs\:\:user$/;
&ok;

# test 28	check array's the same length
print "in/out not the same length\nnot "
	unless scalar(@$ua) == scalar(@$rv);
&ok;

# test 29 - 40	check array's contain same values
foreach(0..$#$ua) {
  my $exp = $$ua[$_];
  my $got = $$rv[$_];
  print "got: $got, exp: $exp\nnot "
	unless $got == $exp;
  &ok;
}
