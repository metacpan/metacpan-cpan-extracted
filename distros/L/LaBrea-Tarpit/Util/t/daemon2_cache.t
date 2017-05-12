# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as erl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..17\n"; }
END {print "not ok 1\n" unless $loaded;}
use LaBrea::Tarpit::Util qw(
	close_file
	share_open
	daemon2_cache
);
$loaded = 1;
print "ok 1\n";

$test = 2;

umask 027;
if (-d 'tmp') {         # clean up previous test runs
  opendir(T,'tmp');
  @_ = grep(!/^\./, readdir(T));
  closedir T;
  foreach(@_) {
    unlink "tmp/$_";
  }
} else {
  mkdir 'tmp', 0750 unless (-e 'tmp' && -d 'tmp');
}

sub ok {
  print "ok $test\n";
  ++$test;
}
sub next_sec {
  my ($then) = @_;
  my $now;
# wait for epoch
  do { select(undef,undef,undef,0.1); $now = time }
	while ( $then >= $now );
  $now;
}

local(*TLOCK,*TF,*TEST);
my $src = 'tmp/test.src';
my $cache = 'tmp/test.cache';

## test 2
## check for detection of missing src
print "failed to notice missing $src\nnot "
  if (daemon2_cache($cache,$src));
&ok;

## test 3
## should have created cache
print "did not create $cache.tmp\nnot "
  unless -e $cache.'.tmp';
&ok;


## test4
## put some stuff in test file
my $startime = &next_sec(time);
print "failed to open $src\nnot "
  unless open(TF,'>'.$src);
&ok;
print TF "$startime\n";
close TF;

## test 5
# test for actual update
my $now = &next_sec($startime);
$_ = daemon2_cache($cache,$src);
print "expected time $now\nne response $_\nnot "
  unless $_ == $now;
&ok;

## test 6
## check actual file contents
print "failed to open $cache\nnot "
  unless open(TF,$cache);
$_ = <TF>;
close TF;
print "contents $cache = $_ expected $startime\n\nnot "
  unless $_ eq "$startime\n";
&ok;

## test 7
## check that blocking works
print "failed to open shared $cache\nnot "
  unless share_open(*TLOCK,*TF,$cache.'.tmp');
&ok;

&next_sec($now);

if (open(TEST,'-|')) {
  print (<TEST>);
} else {
## test 8
## does block
  my @save_fail = daemon2_cache($cache,$src,0,2);	# alarm timeout = 2
  print "failed to block\nnot "
    unless $@ =~ /remote connect timeout/;
  &ok;
  print 'returned |', @save_fail, "| on failure\nnot "
    if @save_fail;
  &ok;
  exit;
}
close TEST;
close_file(*TLOCK,*TF);

$test += 2;

## test 10
# test again for actual update
$now = &next_sec($startime);
$_ = daemon2_cache($cache,$src);
print "expected time $now\nne response $_\nnot "
  unless $_ == $now;
&ok;

## test 11,12,13,14
## test aging
my $age = 3;
my ($time,$upd);
while (($time,$upd) = daemon2_cache($cache,$src,$age)) {
  last unless $now +$age > $time;
  print "spurious update\nnot " if $upd;
  &ok;
} continue {
  &next_sec(time);
}

## test 15
## final cache time
print 'expected time ', $now + $age +1,"\nne response $time\nnot "
  unless $time == $now + $age + 1;
&ok;

## test 16
## check for update mark
print "missing update mark\nnot "
  unless $upd;
&ok;

daemon2_cache;
print "failed to find missing out cache file\nnot "
  unless $@ =~ /missing output cache/;
&ok;
