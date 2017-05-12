# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..120\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Cwd;
use CTest;

$TCTEST		= 'Mail::SpamCannibal::BDBaccess::CTest';
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
    my $exp = ($expect{$_} =~ /^(\d+)/)
	? $1 : $expect{$_};
    if (!exists $args{$_}) {
      print "key '$_' not found\nnot ";
    }
    elsif (	($args{$_} =~ /\D/ && $args{$_} ne $exp) ||
		($args{$_} !~ /\D/ && $args{$_} != $exp)) {
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

## test 2-10 T flag only
my @x = qw(-T);
%expect = (
-r		=> '/var/run/dbtarpit',
-s		=> 'bdbread',
inetd           => '0 use inetd',
port            => '0 port number',
dflag           => '0 no daemon',
oflag           => '0 log to stdout',
loglvl          => '0 log enabled > 0',
Tflag           => '1 test mode',
);
dumpnchk(@x);

## test 11-20	add a database
@x = qw(-T -f abcde);
%expect = (
-r		=> '/var/run/dbtarpit',
-f		=> 'abcde',
-s		=> 'bdbread',
inetd           => '0 use inetd',
port            => '0 port number',
dflag           => '0 no daemon',
oflag           => '0 log to stdout',
loglvl          => '0 log enabled > 0',
Tflag           => '1 test mode',
);
dumpnchk(@x);

## test 21-30	add another database
@x = qw(-T -f abcde -f lmnop);
%expect = (
-r		=> '/var/run/dbtarpit',
-f		=> 'abcde',
-f		=> 'lmnop',
-s		=> 'bdbread',
inetd           => '0 use inetd',
port            => '0 port number',
dflag           => '0 no daemon',
oflag           => '0 log to stdout',
loglvl          => '0 log enabled > 0',
Tflag           => '1 test mode',
);
dumpnchk(@x);

## test 31-40	change home directory
@x = qw(-T -f abcde -f lmnop -r /somewhere/else);
%expect = (
-r		=> '/somewhere/else',
-f		=> 'abcde',
-f		=> 'lmnop',
-s		=> 'bdbread',
inetd           => '0 use inetd',
port            => '0 port number',
dflag           => '0 no daemon',
oflag           => '0 log to stdout',
loglvl          => '0 log enabled > 0',
Tflag           => '1 test mode',
);
dumpnchk(@x);

## test 41-50	change socket name
@x = qw(-T -f abcde -f lmnop -r /somewhere/else -s newsockname);
%expect = (
-r		=> '/somewhere/else',
-f		=> 'abcde',
-f		=> 'lmnop',
-s		=> 'newsockname',
inetd           => '0 use inetd',
port            => '0 port number',
dflag           => '0 no daemon',
oflag           => '0 log to stdout',
loglvl          => '0 log enabled > 0',
Tflag           => '1 test mode',
);
dumpnchk(@x);

## test 51-60	no daemon
@x = qw(-T -f abcde -f lmnop -r /somewhere/else -s newsockname -d);
%expect = (
-r		=> '/somewhere/else',
-f		=> 'abcde',
-f		=> 'lmnop',
-s		=> 'newsockname',
inetd           => '0 use inetd',
port            => '0 port number',
dflag           => '1 no daemon',
oflag           => '0 log to stdout',
loglvl          => '0 log enabled > 0',
Tflag           => '1 test mode',
);
dumpnchk(@x);

## test 61-70	no daemon
@x = qw(-T -f abcde -f lmnop -r /somewhere/else -s newsockname -d -o);
%expect = (
-r		=> '/somewhere/else',
-f		=> 'abcde',
-f		=> 'lmnop',
-s		=> 'newsockname',
inetd           => '0 use inetd',
port            => '0 port number',
dflag           => '1 no daemon',
oflag           => '1 log to stdout',
loglvl          => '0 log enabled > 0',
Tflag           => '1 test mode',
);
dumpnchk(@x);

## test 71-80	enable logging
@x = qw(-T -f abcde -f lmnop -r /somewhere/else -s newsockname -d -o -l);
%expect = (
-r		=> '/somewhere/else',
-f		=> 'abcde',
-f		=> 'lmnop',
-s		=> 'newsockname',
inetd           => '0 use inetd',
port            => '0 port number',
dflag           => '1 no daemon',
oflag           => '1 log to stdout',
loglvl          => '1 log enabled > 0',
Tflag           => '1 test mode',
);
dumpnchk(@x);

## test 81-90	daemon off, but -o sets d flag
@x = qw(-T -f abcde -f lmnop -r /somewhere/else -s newsockname  -o);
%expect = (
-r		=> '/somewhere/else',
-f		=> 'abcde',
-f		=> 'lmnop',
-s		=> 'newsockname',
inetd           => '0 use inetd',
port            => '0 port number',
dflag           => '1 no daemon',
oflag           => '1 log to stdout',
loglvl          => '0 log enabled > 0',
Tflag           => '1 test mode',
);
dumpnchk(@x);

## test 91-100	-l alone
@x = qw(-T -f abcde -f lmnop -r /somewhere/else -s newsockname  -l);
%expect = (
-r		=> '/somewhere/else',
-f		=> 'abcde',
-f		=> 'lmnop',
-s		=> 'newsockname',
inetd           => '0 use inetd',
port            => '0 port number',
dflag           => '0 no daemon',
oflag           => '0 log to stdout',
loglvl          => '1 log enabled > 0',
Tflag           => '1 test mode',
);
dumpnchk(@x);

## test 101-110		add port
@x = qw(-T -f abcde -f lmnop -r /somewhere/else -p 13);
%expect = (
-r              => '/somewhere/else',
-f              => 'abcde',
-f              => 'lmnop',
-s              => 'bdbread',
inetd           => '0 use inetd',
port            => '13 port number',
dflag           => '0 no daemon',  
oflag           => '0 log to stdout',
loglvl          => '0 log enabled > 0',
Tflag           => '1 test mode',
);
dumpnchk(@x);

## test 111-120		add inetd
@x = qw(-T -f abcde -f lmnop -r /somewhere/else -p 10123 -i);
%expect = (
-r              => '/somewhere/else',
-f              => 'abcde',
-f              => 'lmnop',
-s              => 'bdbread',
inetd           => '1 use inetd',
port            => '10123 port number',
dflag           => '1 no daemon',  
oflag           => '0 log to stdout',
loglvl          => '0 log enabled > 0',
Tflag           => '1 test mode',
);
dumpnchk(@x);

