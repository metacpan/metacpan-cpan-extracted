# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..15\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Mail::SpamCannibal::Session 0.04 qw(
	new_ses
	encode
	validate
);

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

sub next_sec {
  my ($then) = @_;
  $then = time unless $then;
  my $now;
# wait for epoch
  do { select(undef,undef,undef,0.1); $now = time }
        while ( $then >= $now );
  $now;
}

mkdir './tmp',0755;

my $sesdir = './tmp';

my $ID = 'QwerTy';
my $b64ID = encode($ID);
my $error;

my $now = next_sec();

## test 2	bogus session attempt
my $sess = new_ses($sesdir . 'nothere',$b64ID,'secret',\$error);
print "created bogus session\nnot "
	if $sess && $error ne 'could not create session key';
&ok;

## test 3	create real session
$sess = new_ses($sesdir,$b64ID,'secret',\$error,1);
print "got unexpected error: $error\nnot "
	unless $sess;
&ok;

## test 4	check the pieces
my($uniqueID,$mac,$file) = split(/\./,$sess,3);
print "missing session file $sesdir/$file\nnot "
	unless -e $sesdir .'/'. $file;
&ok;

## test 5
print "got: $uniqueID, exp: $b64ID\nnot "
	unless $uniqueID eq $b64ID;
&ok;

## test 6	fail to validate session
print "unexpected user value returned '$_'\nnot "
	if ($_ = validate($sesdir,$sess,'secret',\$error));
&ok;

## test 7	check error return
print "got: $error\nexp: login required\nnot "
	unless $error eq 'login required';
&ok;

## test 8	validate session by array
print "Bail Out! unexpected error, $error\nnot "
	unless (@_ = validate($sesdir,$sess,'secret',\$error)) > 0;
&ok;

## test 9-11	check valid return info
my($user,$contents,$fn) = @_;
print "got: $user, exp: $ID\nnot "
	unless $user eq $ID;
&ok;

## test 10
print "got: $contents, exp: -1\nnot "
	unless $contents && $contents == 1;
&ok;

## test 11
print "got: $fn\nexp: $file\nnot "
	unless $fn eq $file;
&ok;

## test 12	open session file
open(SES,'>'. $sesdir .'/'. $file) or
	print "Bail Out! could not open ${sesidr}/$file for write\nnot ";
&ok;

## test 13	and re-write positive
print SES -1;
close SES or print "failed to close ${sesidr}/$file\nnot ";
&ok;

## test 14	validate session
print "unexpected error return '$error'\nnot "
	unless ($user = validate($sesdir,$sess,'secret',\$error));
&ok;

## test 15	check returned user value
print "got: $user, exp: $ID\nnot "
	unless $user eq $ID;
&ok;
