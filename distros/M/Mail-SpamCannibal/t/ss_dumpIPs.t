# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..13\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Mail::SpamCannibal::ScriptSupport qw(
	checkclct
	dumpIPs
);

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
  unlink $dir if -e $dir;       # remove files of this name as well
}

my $path = './tmp';
mkdir $path,0755;

$path .= '/';


my $DNSBL = {
	ALLIPS => $path .'myfile.txt'
};

open (F,'>'. $DNSBL->{ALLIPS}) or die "could not open $DNSBL->{ALLIPS}\n";
print F q|
my $stuff = {
	'1.2.3.4' => 1,
	'3.4.5.6' => 2,
};
|;
close F;

## test 3	load data
my $allips;
print 'not ' unless ($allips = checkclct($DNSBL)) && ref $allips eq 'HASH';
&ok;

## test 3	check data
my @keys = sort keys %$allips;
print 'not ' unless @keys == 2;
&ok;

## test 4, 5	check data
foreach('1.2.3.4','3.4.5.6') {
  print 'not ' unless $_ eq shift @keys;
  &ok;
}

## test 6	check fail, no input
print 'not ' unless dumpIPs();
&ok;

## test 7	check fail, no config key
my $bogus = {};
print 'not ' unless dumpIPs($bogus,$allips);
&ok;

## test 8	write file
$allips->{'5.6.7.8'} = 3;
print 'not ' if dumpIPs($DNSBL,$allips);
&ok;

## test 9	load result
my $results;
print 'not ' unless ($results = checkclct($DNSBL)) && ref $results eq 'HASH';
&ok;

## test 10	check data
@keys = sort keys %$results;
print 'not ' unless @keys == 3;
&ok;

## test 11-13	check data
foreach('1.2.3.4','3.4.5.6','5.6.7.8') {
  print 'not ' unless $_ eq shift @keys;
  &ok;
}

