# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use diagnostics;

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..10\n"; }
END {print "not ok 1\n" unless $loaded;}

use Geo::CountryFlags;
$loaded = 1;
print "ok 1\n";
######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$test = 2;

umask 027;
if (-d 'tmp') {         # clean up previous test runs
  opendir(T,'tmp');
  @_ = grep(!/^\./, readdir(T));
  closedir T;
  foreach(@_) {
    unlink "tmp/$_";
  }
  rmdir 'tmp' or die "COULD NOT REMOVE tmp DIRECTORY\n";
}

sub ok {
  print "ok $test\n";
  ++$test;
}

my @tests = (
#	code	expect
	US	=> 'us',	# known entry
	xx	=> undef,	# no lower case keys
	AS	=> 'aq',	# known entry
);

sub mkflag {
  my ($cc,$fd) = @_;
  return undef unless $cc;
  $fd = './flags' unless $fd;
  return "${fd}/${cc}-flag.gif";
}

my $gf = new Geo::CountryFlags;

## test 2-4

for (my $i=0; $i <= $#tests; $i+=2 ) {
  my $rv = $gf->cc2cia($tests[$i]) || 'undef';
  $_ = $tests[$i+1] || 'undef';
  print "$tests[$i] => $_ ne $rv\nnot "
	unless $rv eq $_;
  &ok;
}

## test 5-6
# should return local flag file
my $cc = 'AS';
my $tflag = mkflag($cc);
my $rv = $gf->get_flag($cc);
print "could not find $tflag\nnot "
	if ! $rv || $rv ne $tflag;
&ok;

print "get_flag eval failed with: $@\nnot "
  if $@;
&ok;

## test 7-8
$cc = 'AP';
$tflag = mkflag($cc);
$rv = $gf->get_flag($cc);
print "found non-existent $tflag\nnot "
	if $rv;
&ok;

print "get_flag eval failed with: $@\nnot "
  if $@;
&ok;

## test 9-10
# check if cia site is available
$cc = 'US';		# known to exist
$tflag = mkflag($cc,'./tmp');
$rv = $gf->get_flag($cc,'./tmp');

if ( $@ ) {
  print 'ok ', $test++,
	"  # Skipped, US flag not found or CIA web site does not respond\n";
  print 'ok ', $test++, " # skip\n";
} else {
  &ok;

  ## test 10
  
  print "did not retrieve $tflag\nnot "
	unless -e $tflag;
  &ok;
}
