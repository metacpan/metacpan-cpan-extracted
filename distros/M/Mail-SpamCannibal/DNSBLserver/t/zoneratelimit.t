# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..15\n"; }
END {print "not ok 1\n" unless $loaded;}

use CTest;

$TCTEST		= 'Mail::SpamCannibal::DNSBLserver::CTest';
$loaded = 1;
print "ok 1\n";
######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$test = 2;

umask 007;
foreach my $dir (qw(tmp tmp.dbhome tmp.bogus)) {
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

## test 2 
my $new_tv_sec	 = 1234567;
my $new_tv_usec	 = 200000;
my $then_tv_sec	 = $new_tv_sec;
my $then_tv_usec = 100001;
my $diskmax	 = 200000;
my $charsum	 = 50000;
my $partsum	 = $diskmax;

my($delta,$psumret,$partmax,$charet);

sub ratelimit {
  ($delta,$psumret,$partmax,$charet) = &{"${TCTEST}::t_ratelimit"}(
	0,
	$new_tv_sec,
	$new_tv_usec,
	$then_tv_sec,
	$then_tv_usec,
	$diskmax,
	$charsum,
	$partsum,
  );
#print "d=$delta, ps=$psumret, px=$partmax\n";
}

sub cdelt {
  my $dlt = 0;
  $dlt = 1000000 if $new_tv_sec != $then_tv_sec;
  $dlt += $new_tv_usec - $then_tv_usec;
  $dlt = 200000 if $dlt < 0 || $dlt > 500000;
  return $dlt;
}

sub psum {
 return int ((((900000 - $delta)/1000000) * $partsum) + $charsum);
}

## test 2	check $delta
ratelimit();
my $exp = &cdelt;
print "got: $delta, exp: $exp\nnot "
	unless $delta == $exp;
&ok;

## test 3	check partsum
$exp = $partsum;
print "got: $psumret, exp: $exp\nnot "
	unless $psumret == $exp;
&ok;

## test 4	check partmax
$exp = int ($diskmax/4);
print "got: $partmax, exp: $exp\nnot "
	unless $partmax == $exp;
&ok;

## test 5	delta
$then_tv_usec = 99999;
ratelimit();
$exp = &cdelt;
print "got: $delta, exp: $exp\nnot "
	unless $delta == $exp;
&ok;

## test 6	check partsum
$exp = &psum;
print "got: $psumret, exp: $exp\nnot "
	unless $psumret == $exp;
&ok;

## test 7	check partmax
$exp = int ($diskmax/4);
print "got: $partmax, exp: $exp\nnot "
	unless $partmax == $exp;
&ok;

## test 8	check with overflowed now,then
$new_tv_sec++;
$new_tv_usec	= 50000;
$then_tv_usec	= 950001;
ratelimit();
$exp = &cdelt;
print "got: $delta, exp: $exp\nnot "
	unless $delta == $exp;
&ok;

## test 9	check partsum
$exp = $partsum;
print "got: $psumret, exp: $exp\nnot "
	unless $psumret == $exp;
&ok;

## test 10	check partmax
$exp = int ($diskmax/4);
print "got: $partmax, exp: $exp\nnot "
	unless $partmax == $exp;
&ok;

## test 11	delta
$then_tv_usec = 949999;
ratelimit();
$exp = &cdelt;
print "got: $delta, exp: $exp\nnot "
	unless $delta == $exp;
&ok;

## test 12	check partsum
$exp = &psum;
print "got: $psumret, exp: $exp\nnot "
	unless $psumret == $exp;
&ok;

## test 13	check partmax
$exp = int ($diskmax/4);
print "got: $partmax, exp: $exp\nnot "
	unless $partmax == $exp;
&ok;

## test 14	check variations on partsum
$then_tv_sec++;
$new_tv_usec	= 200000;
$then_tv_usec	= 0;
ratelimit();
$exp = &psum;
print "got: $psumret, exp: $exp\nnot "
	unless $psumret == $exp;
&ok;

## test 15	variations on partsum
$charsum	= 10000;
ratelimit();
$exp = &psum;
print "got: $psumret, exp: $exp\nnot "
	unless $psumret == $exp;
&ok;
