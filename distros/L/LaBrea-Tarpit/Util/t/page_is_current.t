# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as erl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..6\n"; }
END {print "not ok 1\n" unless $loaded;}
use LaBrea::Tarpit::Util qw(
	page_is_current
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

my $src = 'tmp/test.src';

## test 2
## test for non-existent file
print "found non-existent file\nnot "
  if page_is_current(0,$src);
&ok;

my $ctime = &next_sec(time);

## test 3
## create test file
print "failed to open $src\nnot "
  unless open(F,'>'.$src);		# make the file
&ok;

close F;

my $file_time = page_is_current($ctime,$src);

## test 4
## file should equal ctime
print "expected $ctime\nne response $file_time\nnot "
  unless $file_time == $ctime;
&ok;

--$ctime;		# older 
$file_time = page_is_current($ctime,$src);

## test 5
print "expected $ctime\nne response $file_time\nnot "
  unless $file_time > $ctime;
&ok;

$ctime +=2;		# expire
$file_time = page_is_current($ctime,$src);

## test 6
print "failed to expire\nnot "
  if $file_time;
&ok;
