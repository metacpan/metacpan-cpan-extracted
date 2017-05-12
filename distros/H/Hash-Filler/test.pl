# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..19\n"; }
END {print "not ok 1\n" unless $loaded;}
use Hash::Filler;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

my $test = 1;

##
## Basic tests for the rules
##

my $hf = new Hash::Filler;
my %hash;

$hf->add('key0', 
	 sub { 
	     $_[0]->{$_[1]} = 'this ' 
		 . $_[0]->{'key1'} . ' '
		     . $_[0]->{'key2'}; 1; 
	 }, 
    [ 'key1', 'key2' ]);

$hf->add('key1', 
    sub { $_[0]->{$_[1]} = 'works'; 1; }, [  ]);

$hf->add('key2', 
    sub { $_[0]->{$_[1]} = 'ok!'; 1; }, [  ]);

$hf->fill(\%hash, 'key0');

my @calls = $hf->stats;

if ($calls[0] == 3 and
    $calls[1] == 1 and
    $calls[2] == 1 and
    $calls[3] == 1) {
    print "ok ", ++$test, "\n";
}
else {
    print "not ok ", ++$test, "\n";
}

if ($hash{'key0'} eq 'this works ok!') {
    print "ok ", ++$test, "\n";
}
else {
    print "not ok ", ++$test, "\n";
}

if ($hash{'key1'} eq 'works') {
    print "ok ", ++$test, "\n";
}
else {
    print "not ok ", ++$test, "\n";
}

if ($hash{'key2'} eq 'ok!') {
    print "ok ", ++$test, "\n";
}
else {
    print "not ok ", ++$test, "\n";
}

##
## Infinite loop avoidance tests
##

my $hf = new Hash::Filler;
my %hash;

$hf->add('key0', sub { $_[0]->{$_[1]} = 'failed!'; 1; }, [ 'key1' ]);
$hf->add('key1', sub { $_[0]->{$_[1]} = 'failed!'; 1; }, [ 'key0' ]);

if (not $hf->fill(\%hash, 'key0')) {
    print "ok ", ++$test, "\n";
}
else {
    print "not ok ", ++$test, "\n";
}

if (not $hf->fill(\%hash, 'key1')) {
    print "ok ", ++$test, "\n";
}
else {
    print "not ok ", ++$test, "\n";
}

if ($hash{'key0'} ne 'failed!') {
    print "ok ", ++$test, "\n";
}
else {
    print "not ok ", ++$test, "\n";
}

if ($hash{'key1'} ne 'failed!') {
    print "ok ", ++$test, "\n";
}
else {
    print "not ok ", ++$test, "\n";
}

##
## Wildcard rule and precedences
##

my $hf = new Hash::Filler;

$hf->add('key0', sub { $_[0]->{$_[1]} = 'ok'; 1; }, [ 'key1' ]);
$hf->add('key1', sub { $_[0]->{$_[1]} = 'ok'; 1; }, [ 'key2', 'key3' ]);
$hf->add(undef, sub { $_[0]->{$_[1]} = 'w1'; 1; }, [ ]);
$hf->add(undef, sub { $_[0]->{$_[1]} = 'w2'; 1; }, [ 'key2' ], 1000);

my %hash;

if ($hf->fill(\%hash, 'key0')) {
    print "ok ", ++$test, "\n";
}
else {
    print "not ok ", ++$test, "\n";
}

if ($hash{'key0'} eq "ok"
    and $hash{'key1'} eq "ok"
    and $hash{'key2'} eq "w1"
    and $hash{'key3'} eq "w2") {
    print "ok ", ++$test, "\n";
}
else {
    print "not ok ", ++$test, "\n";
}

my %hash;

$hash{'key2'} = 'foo';

if ($hf->fill(\%hash, 'key0')) {
    print "ok ", ++$test, "\n";
}
else {
    print "not ok ", ++$test, "\n";
}

if ($hash{'key0'} eq "ok"
    and $hash{'key1'} eq "ok"
    and $hash{'key2'} eq "foo"
    and $hash{'key3'} eq "w2") {
    print "ok ", ++$test, "\n";
}
else {
    print "not ok ", ++$test, "\n";
}

my %hash;

if ($hf->fill(\%hash, 'key5')) {
    print "ok ", ++$test, "\n";
}
else {
    print "not ok ", ++$test, "\n";
}

if ($hash{'key0'} eq ""
    and $hash{'key1'} eq ""
    and $hash{'key2'} eq "w1"
    and $hash{'key3'} eq ""
    and $hash{'key5'} eq "w2") {
    print "ok ", ++$test, "\n";
}
else {
    print "not ok ", ++$test, "\n";
}

my $hf = new Hash::Filler;

$hf->add('key0', sub { $_[0]->{$_[1]} = 'ok'; 1; }, [ 'key1' ]);
$hf->add('key1', sub { $_[0]->{$_[1]} = 'ok'; 1; }, [ 'key2']);
$hf->add('key1', sub { $_[0]->{$_[1]} = 'fail'; 1; }, [ 'key2', 'key3' ]);

my %hash;

$hash{'key2'} = 'ok';
$hash{'key3'} = 'ok';

if ($hf->fill(\%hash, 'key0')) {
    print "ok ", ++$test, "\n";
}
else {
    print "not ok ", ++$test, "\n";
}

if ($hash{'key0'} eq "ok"
    and $hash{'key1'} eq "ok"
    and $hash{'key2'} eq "ok"
    and $hash{'key3'} eq "ok"){
    print "ok ", ++$test, "\n";
}
else {
    print "not ok ", ++$test, "\n";
}

my $hf = new Hash::Filler;

$hf->add('key0', sub { $_[0]->{$_[1]} = 'ok'; 1; }, [ 'key1' ]);
$hf->add('key1', sub { $_[0]->{$_[1]} = 'fail'; 1; }, [ 'key2']);
$hf->add('key1', sub { $_[0]->{$_[1]} = 'ok'; 1; }, [ 'key2', 'key3' ], 1000);

my %hash;

$hash{'key2'} = 'ok';
$hash{'key3'} = 'ok';

if ($hf->fill(\%hash, 'key0')) {
    print "ok ", ++$test, "\n";
}
else {
    print "not ok ", ++$test, "\n";
}

if ($hash{'key0'} eq "ok"
    and $hash{'key1'} eq "ok"
    and $hash{'key2'} eq "ok"
    and $hash{'key3'} eq "ok"){
    print "ok ", ++$test, "\n";
}
else {
    print "not ok ", ++$test, "\n";
}

