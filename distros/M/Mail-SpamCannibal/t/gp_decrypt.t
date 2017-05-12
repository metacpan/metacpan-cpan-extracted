# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..11\n"; }
END {print "not ok 1\n" unless $loaded;}

use Mail::SpamCannibal::GoodPrivacy qw (decrypt);

$loaded = 1;
print "ok 1\n";
######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$test = 2;

umask 027;
foreach my $dir (qw(tmp)) {
  if (-d $dir) {         # clean up previous test runs
    opendir(T,$dir);
    @_ = grep(!/^\./, readdir(T));
    closedir T;
    foreach(@_) {
      unlink "$dir/$_";
    }
    rmdir $dir or die "COULD NOT REMOVE $dir DIRECTORY\n";
  }
  unlink $dir if -e $dir;	# remove files of this name as well
}

sub ok {
  print "ok $test\n";
  ++$test;
}

sub skip {
  my $count = shift || 1;
  while($count--) {
    print "ok $test	# Skip\n";
    ++$test;
  }
}

my ($original,$crypted,$broken);
{	# localize block
# get text and crypt strings
  local $/;		# undefined local input separator
  open(PT,'tlib/plain.text')
	or die "could not open tlib/plain.txt for testing\n";
  $original = <PT>;
  close PT;

  open(CT,'tlib/crypted.asc')
	or die "could not open tlib/crypted.asc for testing\n";
  $crypted = <CT>;
  close CT;

  open(BT,'tlib/broken.asc')
	or die "could not open tlib/broken.asc for testing\n";
  $broken = <BT>;
  close BT;
}


my $plaintext;

sub checkoutput {
  print q|PLAINTEXT ne EXPECTED listed below, repectively
############## plaintext #################################
|, $plaintext, q|
############## expected  #################################
|, $original, q|
################# end ####################################\nnot |
	if !$plaintext || $plaintext ne $original;
  &ok;
}

sub dotests {
  my $pgpexe = shift;
## test 2 -- check decrypt with hash

  my %hash = (
	Data	  => $crypted,
	ExeFile	  => $pgpexe,
	KeyPath	  => './keyrings',
	Password  => 'TEST',
#	UserID	  => 'E56C91B9',
	Version	  => '2.62',
  );

  $plaintext = decrypt(%hash);
  checkoutput;

## test 3 -- repeat above with hash reference
  undef $plaintext;	# (skeptic :-)
  $plaintext = decrypt(\%hash);
  checkoutput;

## test 4 -- repeat above with named userid
  undef $plaintext;	# (skeptic :-)
  $hash{UserID} = 'test';
  $plaintext = decrypt(\%hash);
  checkoutput;

## test 5 -- repeat above with keyid
  undef $plaintext;	# (skeptic :-)
  $hash{UserID} = 'E56C91B9';
  $plaintext = decrypt(\%hash);
  checkoutput;

## test 6 -- check null return for broken decrypt
  $hash{Data} = $broken;
  my $rv = decrypt(\%hash);
  print q|instead of '', found text below
##########################################################
|, $rv, q|
##########################################################\nnot |
	if $rv;
&ok;

}

##########################################################
####### The test really begin here #######################


do './executableTestPath.conf';
my @pgpexe = &privacyexecutables;

my $pgpexe;
foreach my $try (qw(pgp gpg)) {
  $pgpexe = $try;
  foreach(@pgpexe) {
    if ($_ =~ m|/${try}[^/]*$|) {
      $pgpexe = $_;
      last;
    }
  }

  if ($pgpexe =~ m|/| && -e $pgpexe && -x $pgpexe) {
    if ($pgpexe =~ m|/gpg|) {
      local $/;
      open(VERSION,"$pgpexe --version|");
      $_ = <VERSION>;
      close VERSION;
      if ($_ =~ /IDEA/) {
        &dotests($pgpexe);
      } else {
	&skip(5);
	print STDERR qq
|	Tests for '$pgpexe' have been skipped. The
	IDEA plugin is required to run this test. See: the man
	page for Mail::SpamCannibal::GoodPrivacy about GnuPG.

|;
      }
    } else {
    &dotests($pgpexe);
    }
  } else {
    &skip(5);
    print STDERR qq
|	Tests for '$pgpexe' have been skipped. If you need to
	install '$pgpexe' on your system, do so, then edit file 
	'executableTestPath.conf' to include '/path/to/executable'

|;
  }
}
