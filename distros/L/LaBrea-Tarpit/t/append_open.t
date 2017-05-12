# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..7\n"; }
END {print "not ok 1\n" unless $loaded;}
#use diagnostics;
use Fcntl qw(:DEFAULT :flock);
use LaBrea::Tarpit;

$loaded = 1;
print "ok 1\n";

*ex_open = \&LaBrea::Tarpit::_ex_append;

sub close_file {
  my ($lock,$file) = @_;
  close $file;
  close $lock;
}

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

############## test file locking #############################
local(*LOCK1,*LOCK2,*ONE);
my $filedb = 'tmp/locktmp.file';
my $filetxt = 
'The Quick Brown Fox Jumped 
over the Lazy Dog 1234567890';

my $extra = 
'extra stuff';

# write some stuff to locked file
ex_open(*LOCK1,*ONE,$filedb);
print ONE $filetxt;

# try to open lock it again, should fail

local *TEST;
if (open TEST,'-|') {
  print (<TEST>);
} else {


  local $SIG{ALRM} = sub {die "timeout"};

## test ex open against previous ex_open
## test 2
  eval {
    alarm 1;
    ex_open(*LOCK2,*ONE,$filedb);
    alarm 0;
  };
  if ( $@ && $@ !~ /timeout/ ) {
    print "$@\nnot ";
  } elsif ( ! $@ ) {
    print "unwanted exclusive lock succeeded\nnot ";
  }
  print "ok $test\n";
  $test++;

  close LOCK2;

## test shared open against previous ex_open
## test 3
  eval {
    alarm 1;
    sysopen LOCK2, $filedb . '.flock', O_RDWR|O_CREAT|O_TRUNC;
    flock(LOCK2,LOCK_SH);
    alarm 0;
  };
  if ( $@ && $@ !~ /timeout/ ) {
    print "$@\nnot ";
  } elsif ( ! $@ ) {   
    print "unwanted shared lock succeeded\nnot ";
  }
  print "ok $test\n";
  $test++;
  close LOCK2;

  exit;
}
close TEST;
close_file(*LOCK1,*ONE);

$test = 4;
## test 4
my $txt1 = '';
my $txt2 = '';

print 'not ' unless open(ONE,$filedb);
print "ok $test\n";
$test++;

while(<ONE>) {
  $txt1 .= $_;
}

close ONE;

print "txt1 ne orig\nnot " if $txt1 ne $filetxt;
print "ok $test\n";
$test++;

## test 5
# open and append

ex_open(*LOCK1,*ONE,$filedb);
print ONE $extra;
close_file(*LOCK1,*ONE);

## test 6
$txt1 = '';
print 'not ' unless open(ONE,$filedb);
print "ok $test\n";
$test++;

while(<ONE>) {
  $txt1 .= $_;
}

close ONE;

## test 7
print "extra not appended\nnot " if $txt1 ne $filetxt . $extra;
print "ok $test\n";
$test++;

