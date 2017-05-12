# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..6\n"; }
END {print "not ok 1\n" unless $loaded;}

use Mail::SpamCannibal::Session qw(
	new_ses
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

my $b64ID = 'QwerTy';
my $error;

my $now = next_sec();

## test 2	bogus session attempt
my $sess = new_ses($sesdir . 'nothere',$b64ID,'secret',\$error);
print "created bogus session\nnot "
	if $sess && $error ne 'could not create session key';
&ok;

## test 3	create real session
$sess = new_ses($sesdir,$b64ID,'secret',\$error);
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

## test 6	validate session
print "unexpected error, $error\nnot "
	unless $b64ID = validate($sesdir,$sess,'secret',\$error);
&ok;
