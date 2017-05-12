# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..28\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Mail::SMTP::Honeypot;
*uniquemsgid	= \&Mail::SMTP::Honeypot::uniquemsgid;
*get_unique	= \&Mail::SMTP::Honeypot::get_unique;

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

my $debug = 0;

# set the pid
local $$ = 0;

# seed the unique number
get_unique(65534);	# preset to 1 when called in Run

## test 2 - 12	test high order 32 bits of ID usually taken from 'time'
my %t = qw(
        1               aaaaaaaaaabb
        10              aaaaaaaaaakc
        100             aaaaaaaabaMd
        1000            aaaaaaaaqaie
        10000           aaaaaacaLasf
        100000          aaaaaaAaaa4g
        1000000         aaaaeamajach
        10000000        aaaaPa7aCaui
        100000000       aagaVaKaJaoj
        1000000000      bafaPa3aQaqk
        4294967266      eaQaPapalaKl
);

foreach my $key (sort {$a <=> $b} keys %t) {
  $_ = uniquemsgid($key);
  if ($debug) {
    print "\t$key\t";
    print "\t" if length($key) < 8;
    print "$_\n";
  } else {
    print "got: $_, exp: $t{$key}\nnot "
	unless $_ eq $t{$key};
    &ok;
  }
}

## test 13 - 20	test low order 32 bits, high 16 bits
get_unique(65534);	# preset to 1 when called in Run
my %high = qw(
        1       aaaaaaaradbd
        10      aaaaacaUaEbw
        100     aaaaaBaEa3br
        1000    aaaeaAa8a4bu
        10000   aaaSavaZaebP
        20000   abaAaRaOajbq
        40000   aca1azasasbB
	60000	aeasaga6aBbM
);

foreach my $key (sort {$a <=> $b} keys %high) {
  $$ = $key;
  $_ = uniquemsgid(1);
  if ($debug) {
    print "\t$key\t$_\n";
  } else {
    print "got: $_, exp: $high{$key}\nnot "
	unless $_ eq $high{$key};
    &ok;
  }
}

## test 21 - 28	test low order 32 bits, low 16 bits
my %low = qw(
        1       aaaaaaaaaabd
        10      aaaaaaaaaabm
        100     aaaaaaaaabbO
        1000    aaaaaaaaaqbk
        10000   aaaaaaacaLbu
        20000   aaaaaaafambM
        40000   aaaaaaakazbm
	60000	aaaaaaapaLbW
);

$$ = 0;

foreach my $key (sort {$a <=> $b} keys %low) {
  get_unique($key);
  $_ = uniquemsgid(1);
  if ($debug) {
    print "\t$key\t$_\n";
  } else {
    print "got: $_, exp: $low{$key}\nnot "
	unless $_ eq $low{$key};
    &ok;
  }
}
