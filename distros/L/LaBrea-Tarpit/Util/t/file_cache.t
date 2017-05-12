# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as erl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..33\n"; }
END {print "not ok 1\n" unless $loaded;}
use LaBrea::Tarpit::Util qw(
	cache_is_valid
	update_cache
	close_file
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

sub next_sec {
  my ($then) = @_;
  my $now;
# wait for epoch
  do { select(undef,undef,undef,0.1); $now = time }
	while ( $then >= $now );
  $now;
}

local(*H);

my $test_cache = './tmp/html_cache.tst';

my $lnf = {};		# empty array;
my $expected = "one line
";
&next_sec(time);

# create file
open(H,'>'. $test_cache);
my $tmp = select H;
$| = 1;
select $tmp;
print H $expected;
close H;

## test various failure combinations
# non existent cache file name
print 'non-existent cache file name
not ' if cache_is_valid(*H,$lnf);
print "ok $test\n";
$test++;

$lnf->{html_cache_file} = undef;
# non existent cache file name
print 'empty cache file name
not ' if cache_is_valid(*H,$lnf);
print "ok $test\n";
$test++;

$lnf->{html_cache_file} = $test_cache;
# no timeout
print 'no timeout value
not ' if cache_is_valid(*H,$lnf);
print "ok $test\n";
$test++;

$lnf->{html_expire} = 0;
# zero html_expire
print 'zero timeout value
not ' if cache_is_valid(*H,$lnf);
print "ok $test\n";
$test++;

$lnf->{html_expire} = -1;
# negative html_expire
print 'negative timeout value
not ' if cache_is_valid(*H,$lnf);
print "ok $test\n";
$test++;

my $size;

$lnf->{html_expire} = 1;
# should open now
print 'file failed to open
not ' unless ($size = cache_is_valid(*H,$lnf));
print "ok $test\n";
$test++;

undef $/;
my $txt = <H>;
my $len = length($txt);

print "size 1 mismatch file $size ne length $len\nnot "
	unless $size == $len;
print "ok $test\n";
$test++;

open(H,'>'.$lnf->{html_cache_file});	# erase file, size0;
close H;

print "response 1:\n$txt\nne expected:\n$expected\nnot "
	unless $txt eq $expected;
print "ok $test\n";
$test++;

# should fail, size is now 0
print 'zero size file
not ' if cache_is_valid(*H,$lnf);
print "ok $test\n";
$test++;

$expected .= 'two lines
';

open(H,'>'.$lnf->{html_cache_file});
select H;
$| = 1;
select STDOUT;
print H $expected;
close H;

# should open again
print 'file failed to open again
not ' unless ($size = cache_is_valid(*H,$lnf));
print "ok $test\n";
$test++;

$txt = <H>;
close H;
$len = length($txt);

print "size 2 mismatch file $size ne length $len\nnot "
        unless $size == $len;
print "ok $test\n";
$test++;

# check that file is re written
print "response 2:\n$txt\nne expected:\n$expected\nnot "
        unless $txt eq $expected;
print "ok $test\n";
$test++;


$tmp = (stat($lnf->{html_cache_file}))[9];
$txt = &next_sec($tmp+1);	# expire cache

# should be expired now
print "file not expired, mtime=$tmp, time=$txt\nnot "
	if cache_is_valid(*H,$lnf);
print "ok $test\n";
$test++;

# now do an update
$expected = 'cache update complete
';
print 'cache update failed
not ' unless update_cache($lnf,\$expected);
print "ok $test\n";
$test++;

# should open again
print 'file failed to open again
not ' unless ($size = cache_is_valid(*H,$lnf));
print "ok $test\n";
$test++;

$txt = <H>;
close H;
$len = length($txt);

print "size 3 mismatch file $size ne length $len\nnot "
        unless $size == $len;
print "ok $test\n";
$test++;

# check that file is re written
print "response 3:\n$txt\nne expected:\n$expected\nnot "
        unless $txt eq $expected;
print "ok $test\n";
$test++;

########## now check short cache

# this file should not be there

# should fail, size should be 0
print 'zero size file
not ' if cache_is_valid(*H,$lnf,1);
print "ok $test\n";
$test++;

# update_cache appends '.short' to file name automatically

my $short = 'contents of short report cache
';

print 'short cache update failed
not ' unless update_cache($lnf,undef,\$short);
print "ok $test\n";
$test++;

# should open again
print 'file failed to open again
not ' unless ($size = cache_is_valid(*H,$lnf,1));
print "ok $test\n";
$test++;

$txt = <H>;
close H;   
$len = length($txt);

print "size 3 mismatch file $size ne length $len\nnot "
        unless $size == $len;
print "ok $test\n";
$test++;

# check that file is re written
print "response 3:\n$txt\nne expected:\n$short\nnot "
        unless $txt eq $short;
print "ok $test\n";
$test++;

# and check that original cache is still OK

# should open again
print 'file failed to open again
not ' unless ($size = cache_is_valid(*H,$lnf));
print "ok $test\n";
$test++;

$txt = <H>;
close H;
$len = length($txt);

print "size 3 mismatch file $size ne length $len\nnot "
        unless $size == $len;
print "ok $test\n";
$test++;

# check that file is re written
print "response 3:\n$txt\nne expected:\n$expected\nnot "
        unless $txt eq $expected;
print "ok $test\n";
$test++;

###################
# now update both and test results
#
$expected = 'second update for standard cache
';
$short = 'second update for short cache
';
print 'dual cache update failed
not ' unless update_cache($lnf,\$expected,\$short);
print "ok $test\n";
$test++;

# check standard cache
# should open again
print 'file failed to open again
not ' unless ($size = cache_is_valid(*H,$lnf));
print "ok $test\n";
$test++;

$txt = <H>;
close H;   
$len = length($txt);

print "size 3 mismatch file $size ne length $len\nnot "
        unless $size == $len;
print "ok $test\n";
$test++;

# check that file is re written
print "response 3:\n$txt\nne expected:\n$expected\nnot "
        unless $txt eq $expected;
print "ok $test\n";
$test++;

# should open again
print 'file failed to open again
not ' unless ($size = cache_is_valid(*H,$lnf,1));
print "ok $test\n";
$test++;

$txt = <H>;
close H;
$len = length($txt);

print "size 3 mismatch file $size ne length $len\nnot "
        unless $size == $len;
print "ok $test\n";
$test++;

# check that file is re written
print "response 3:\n$txt\nne expected:\n$short\nnot "
        unless $txt eq $short;
print "ok $test\n";
$test++;

# done!
