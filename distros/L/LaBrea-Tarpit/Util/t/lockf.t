# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..10\n"; }
END {print "not ok 1\n" unless $loaded;}
#use diagnostics;
use LaBrea::Tarpit::Util qw (
        ex_open
        share_open
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

############## test file locking #############################
local(*LOCK1,*LOCK2,*ONE,*TWO,*TEST);
my $filedb = 'tmp/locktmp.file';
my $filetxt = 
'The Quick Brown Fox Jumped 
over the Lazy Dog 1234567890';

my $NON_BLOCKING = 1;

my $extra = 
'extra stuff';

# write some stuff to locked file
ex_open(*LOCK1,*ONE,$filedb);
print ONE $filetxt;

# try to open lock it again, should fail

if (open(TEST,'-|')) {
  print (<TEST>);
} else {
## test 2
  print 'not ' if ex_open(*LOCK2,*ONE,$filedb,0,$NON_BLOCKING);
  print "ok $test\n";
  $test++;

  print 'not ' if share_open(*LOCK2,*ONE,$filedb,$NON_BLOCKING);
  print "ok $test\n";
  $test++;
  exit;
}
close TEST;
$test += 2;
close_file(*LOCK1,*ONE);

share_open(*LOCK1,*ONE,$filedb);
if (open(TEST,'-|')) {
  print (<TEST>);
} else {
  eval(share_open(*LOCK2,*TWO,$filedb));
  print "$@\nnot " if $@;
  print "ok $test\n";
  $test++;

  my $txt1 = '';
  my $txt2 = '';

  while(<ONE>) {
    $txt1 .= $_;
  }

  while(<TWO>) {
    $txt2 .= $_;
  }
  close_file(*LOCK2,*TWO);

  print "txt1 ne orig\nnot " if $txt1 ne $filetxt;
  print "ok $test\n";
  $test++;

  print "txt2 ne orig\nnot " if $txt2 ne $filetxt;
  print "ok $test\n";
  $test++;
  exit;
}
$test += 3;
close_file(*LOCK1,*ONE);

$APPEND = 1;
$NEWtxt = 'new';
$NEWnum = -1;

# open and append

ex_open(*LOCK1,*ONE,$filedb,$APPEND);
print ONE $extra;
close_file(*LOCK1,*ONE);

if (open(TEST,'-|')) {
  print (<TEST>);
} else {
  $txt1 = '';
  share_open(*LOCK1,*ONE,$filedb);

  while(<ONE>) {
    $txt1 .= $_;
  }

  close_file(*LOCK1,*ONE);
  print "extra not appended\nnot " if $txt1 ne $filetxt . $extra;
  print "ok $test\n";
  exit;
}
close TEST;
$test++;

# open new and add using text function flag

ex_open(*LOCK1,*ONE,$filedb, $NEWtxt);
print ONE $extra;
close_file(*LOCK1,*ONE);


if (open(TEST,'-|')) {
  print (<TEST>);
} else {
  share_open(*LOCK1,*ONE,$filedb);
  $txt1 = '';
  while(<ONE>) {
    $txt1 .= $_;
  }

  close_file(*LOCK1,*ONE);
  print "not NEW txt\nnot " if $txt1 ne $extra;
  print "ok $test\n";
  exit;
}
close TEST;
$test++;

# open and append
ex_open(*LOCK1,*ONE,$filedb,$APPEND);
print ONE $filetxt;
close_file(*LOCK1,*ONE);

if (open(TEST,'-|')) {
  print (<TEST>);
} else {
  $txt1 = '';
  share_open(*LOCK1,*ONE,$filedb);

  while(<ONE>) {
    $txt1 .= $_;
  }

  close_file(*LOCK1,*ONE);
  print "extra not appended\nnot " if $txt1 ne $extra . $filetxt;
  print "ok $test\n";
  exit;
}
close TEST;
$test++;  

# open new and add using numeric function flag

ex_open(*LOCK1,*ONE,$filedb, $NEWnum);
print ONE $extra;
close_file(*LOCK1,*ONE);

if (open(TEST,'-|')) {
  print (<TEST>);
} else {
  $txt1 = '';
  share_open(*LOCK1,*ONE,$filedb);

  while(<ONE>) {
    $txt1 .= $_;
  }

  close_file(*LOCK1,*ONE);
  print "not NEW txt\nnot " if $txt1 ne $extra;
  print "ok $test\n";
  exit;
}
close TEST;
$test++;  
