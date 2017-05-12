# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; 
  $supported = qx|./dbtarpit_test_object -V 2>&1|;
  if ($supported =~ /^dbtarpit\s+\d+\.\d+/) {
    print "1..465\n";
  } else {
    print "1..0 # Skipped...\n";
    print STDERR $supported;
    exit;
  }
}
END {print "not ok 1\n" unless $loaded;}

use Cwd;
use CTest;
use constant INT	=> 2;

$TCTEST		= 'IPTables::IPv4::DBTarpit::CTest';
$loaded = 1;
print "ok 1\n";
######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$test = 2;

sub ok {
  print "ok $test\n";
  ++$test;
}

my $localdir = cwd();

my %args;
my $extra;
my %expect;

# input array @_ used in child process after } else {
sub dumpargs {
  %args = ();
  $extra = '';
  if (open(FROMCHILD, "-|")) {
    while (my $record = <FROMCHILD>) { 
      if ($record =~ /(\S+)\s+=>\s+(\S+)/) {
# keep for testing
# print "$1	=> '$2',\n";
        $args{$1} = $2;
      } else {
        $extra .= $record;
# print "rec => $record\n";
      }
    }
  } else {
# program name is always argv[0]
    unless (open STDERR, '>&STDOUT') {
      print "can't dup STDERR to /dev/null: $!";
      exit;
    }
    &{"${TCTEST}::t_main"}('CTest',@_);
    exit;
  }
  close FROMCHILD;
}

sub checkargs {
  my $y = keys %args;
  my $x = keys %expect;
  print "key count expect = $x\n".
	"key count found  = $y\nnot "
	unless $x == $y;
  &ok;
  foreach(sort keys %expect) {
    if (!exists $args{$_}) {
      print "key '$_' not found\nnot ";
    }
    elsif (	($args{$_} =~ /\D/ && $args{$_} ne $expect{$_}) ||
		($args{$_} !~ /\D/ && $args{$_} != $expect{$_})) {
      print "$_ is $args{$_}, should be $expect{$_}\nnot ";
    }
    &ok;
  }
}

sub dumpnchk {
  dumpargs(@_);
  checkargs;
}

# check contents of extra print variables
sub checkextra {
  my ($x) = @_;
  if($x) {
    print "UNMATCHED RETURN TEXT\n$extra\nnot "
	unless $extra =~ /^$x/;
  } else {
    print "UNEXPECTED RETURN TEXT\n$extra\nnot "
	if $extra;
  }
  &ok;
}

## test 2-21 T flag only
my @x = qw(-T);
%expect = (
dbhome  => '/var/run/dbtarpit',
dbprimary       => 'tarpit',
dbsecondary     => '(null)',
fifo_name       => '(null)',
lflag   => '0',
vflag   => '0',
oflag   => '0',
Oflag   => '0',
bflag   => '0',
dflag   => '0',
aflag   => '0',
xflag   => '0',
Xflag   => '0',
Rflag   => '0',
kflag   => '0',
tflag   => '10',
Pflag   => '0',
pflag   => '0',
Lflag   => '0',
Tflag   => '1',
);
dumpnchk(@x);

## test 23 - check extra text
checkextra();

## test 24-44 T d
$expect{dflag} = 1;
@x = qw(-T -d);
dumpnchk(@x);

## test 45 - check extra text
checkextra();

## test 46-66 - dflag is active with oflag
$expect{oflag} = 1;
@x = qw(-T -o);
dumpnchk(@x);

## test 67 - check extra text
checkextra('Exiting');

## test 68-88 - dflag * oflag are active with Oflag
$expect{Oflag} = 1;
@x = qw(-T -O);
dumpnchk(@x);  

## test 89 - check extra text
checkextra('Exiting');

# clear previous test flags to initial state
$expect{dflag} = $expect{oflag} = $expect{Oflag} = 0;

## test 90-110 Pflag does not work if there is no pflag
@x = qw(-T -P);
dumpnchk(@x);

## test 111 - check extra text
checkextra();

## test 112 fail with help string, no pflag argument
@x = qw(-T -p);
dumpargs(@x);  
checkextra('Usage: dbtarpit <options>');

## test 113-133 pflag argument forces throttle size -> 3
$expect{tflag} = 3;
$expect{pflag} = 25;	# bandwidth
@x = qw(-T -p 25);
dumpnchk(@x);  

## test 134 - check extra text
checkextra();

## test 135-155 attempt to overide throttle size
@x = qw(-T -p 25 -t 66);
dumpnchk(@x);       

## test 156 - check extra text
checkextra();

## test 157-177 add Pflag
$expect{Pflag} = 1;
@x = qw(-T -p 25 -P);
dumpnchk(@x);

## test 178 - check extra text
checkextra();

# clear previous test flags to initial state
$expect{Pflag} = $expect{pflag} = 0;

## test 179-199 overide throttle when no p
$expect{tflag} = 66;
@x = qw(-T -t 66);
dumpnchk(@x);       

## test 200 - check extra text
checkextra();

## test 201 fail with help string, zero pflag argument
@x = qw(-T -p 0);
dumpargs(@x);  
checkextra('Usage: dbtarpit <options>');

# clear previous test flags to initial state
$expect{tflag} = 10;

## test 202-222 lflag
$expect{lflag} = $expect{vflag} = 1;
@x = qw(-T -l);
dumpnchk(@x);

## test 223 - check extra text
checkextra();

## test 224-244 vflag, same as lflag
$expect{lflag} = $expect{vflag} = 2;
@x = qw(-T -v);
dumpnchk(@x);

## test 245 - check extra text
checkextra();

## test 246-266 both v & l is verbose
$expect{lflag} = $expect{vflag} = 3;
@x = qw(-T -v -l);
dumpnchk(@x);  

## test 267 - check extra text
checkextra();

# clear previous test flags to initial state
$expect{lflag} = $expect{vflag} = 0;

## test 268 get help string
@x = qw(-T -?);
dumpargs(@x);    
checkextra('Usage: dbtarpit <options>');

## test 269 version ID
@x = qw(-T -V);  
dumpargs(@x);    
checkextra('dbtarpit');

## test 270-290 db home dir
$expect{dbhome} = '/somewhere/else';
@x = qw(-T -r /somewhere/else);
dumpnchk(@x);     

## test 291 - check extra text
checkextra(); 

## test 292-312 db primary file
$expect{dbprimary} = 'primary';
@x = qw(-T -r /somewhere/else -f primary);
dumpnchk(@x);     

## test 313 - check extra text
checkextra(); 

## test 314-334 db secondary file
$expect{dbsecondary} = 'secondary';        
@x = qw(-T -r /somewhere/else -f primary -s secondary);
dumpnchk(@x);     

## test 335 - check extra text
checkextra(); 

# clear previous test flags to initial state
$expect{dbhome} = '/var/run/dbtarpit';
$expect{dbprimary} = 'tarpit';
$expect{dbsecondary} = '(null)';

## test 336-356 final check should be same as beginning
@x = qw(-T);
dumpnchk(@x);     

## test 357 - check extra text
checkextra();     

## test 358 - check failed directory, not there
@x = ('-r', "${localdir}/xxx", '-d', '-o');
dumpargs(@x);
checkextra("${localdir}/xxx");

## test 359 - check failed directory, not a directory
@x = ('-r', "${localdir}/MANIFEST", '-d', '-o');
dumpargs(@x);
checkextra("${localdir}/MANIFEST");

## test 360 get help string using -h
@x = qw(-T -h);
dumpargs(@x);
checkextra('Usage: dbtarpit <options>');

## test 361-381 - check fifo_name
$expect{fifo_name} = 'dbtplog';
@x = qw(-T -u dbtplog);
dumpnchk(@x);

## test 382-402 - check that Oflag is silently ignored
@x = qw(-T -u dbtplog -O);
dumpnchk(@x);

## test 403-423 - check that oflag is silently ignored
@x = qw(-T -u dbtplog -o);
dumpnchk(@x);

# clear previous test flags to initial state
$expect{fifo_name} = '(null)';

## test 424-444	check Lflag
$expect{Lflag} = 1;
@x = qw( -T -L );
dumpnchk(@x);

## test 445-465	check Xflag
$expect{Xflag} = 1;
@x = qw( -T -L -X );
dumpnchk(@x);
