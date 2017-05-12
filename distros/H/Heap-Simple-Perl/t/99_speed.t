#!/usr/bin/perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/99_speed.t'
BEGIN { $^W = 1 };
use strict;
use Benchmark;
use FindBin qw($Bin);

use Test::More tests => 2;

my $cachegrind  = 0;
my $simple_only = 1;
my $dirty       = 0;

my $calibrate	= 5;

# Don't use insanely much memory even on very fast computers
my $max_size = 1e6;

my $hires;
BEGIN {
    $hires = eval 'use Time::HiRes qw(time); 1';
    @Heap::Simple::implementors = qw(Heap::Simple::Perl) unless
        @Heap::Simple::implementors;
};

my $option_file = "$Bin/options";
my %options;
open(my $fh, "< $option_file") || die "Could not open '$option_file': $!";
{
    local $_;
    while (<$fh>) {
        s/#.*//;
        next unless /\S/;
        my ($name, $value) =
            /^\s*(BENCHMARK|BENCHMARK_OTHERS|DIRTY|VALGRIND)\s*=\s*(\S+)\s*$/ or
            die "Could not parse line $. of $option_file\n";
        $options{$name} = $value;
    }
}
close($fh) || die "Could not close '$option_file': $!";

SKIP: {
    skip "No benchmark requested", 2 unless $options{BENCHMARK};
    use_ok("Heap::Simple");
    is(Heap::Simple->implementation, "Heap::Simple::Perl");
}
exit if !$options{BENCHMARK};

$simple_only = !$options{BENCHMARK_OTHERS} if
    exists $options{BENCHMARK_OTHERS};
$cachegrind = $options{VALGRIND} if exists $options{VALGRIND};
$dirty      = $options{DIRTY}    if exists $options{DIRTY};

my $class = Heap::Simple->implementation;
$dirty = 1 if !defined $dirty && $class eq "Heap::Simple::XS";
$dirty = $dirty ? 1 : 0;

my $exit = 0;
my @run;

sub run {
    my $script = shift;
    if (my $rc = system(@run, "$Bin/$script", @_)) {
        $rc /= 256 unless $rc % 256;
        $exit = $rc;
    }
}

sub mark {
    print STDERR "------\n";
}

my $do_fibonacci = !$simple_only && !$cachegrind && eval '
    use Heap::Fibonacci;
    use Heap::Elem::Num qw(NumElem);
    use Heap::Elem::Str qw(StrElem);
    1';
my $do_binary = !$simple_only && !$cachegrind && eval '
    use Heap::Binary;
    use Heap::Elem::Num qw(NumElem);
    use Heap::Elem::Str qw(StrElem);
    1';
my $do_binomial = !$simple_only && !$cachegrind && eval '
    use Heap::Binomial;
    use Heap::Elem::Num qw(NumElem);
    use Heap::Elem::Str qw(StrElem);
    1';
my $do_priority = !$simple_only && !$cachegrind && eval '
    use Heap::Priority;
    1';
my $do_array = !$simple_only && !$cachegrind && eval '
    use Array::Heap2;
    1';

print STDERR "\n";
my $size;
if ($cachegrind) {
    @run = ("valgrind", "--tool=cachegrind", $^X);
    $size = 10000;
} else {
    @run = ($^X);
    # Calibrate perl speed
    mark();
    print STDERR "Calibrating. Should take about $calibrate seconds\n";
    my $i = 0;
    my $from;
    if (!$hires) {
        $from = time;
        1 while $from == time;
    }
    $from = $calibrate+time;
    do {
        $i++ for 1..10000;
    } while $from > time;
    $size = int($i/$calibrate/24);
    $size *= 5 if
        !$do_fibonacci && !$do_binary && !$do_binomial && !$do_priority;
    $size =~ s/\B./0/g;
    $size = $max_size if $size > $max_size;
}

my $inc = join(":", map {
    my $a = $_;
    $a =~ s/(.)/"%" . ord($1)/esg;
    $a;
} @INC);
for my $string (0) {
    my %options = (INC	  => $inc,
                   size   => $size,
                   srand  => 832516216,	# We want repeatable benchmarks
                   string => $string);

    if (!$simple_only && !$cachegrind) {
        run("speed_fibonacci", %options) if $do_fibonacci;
        run("speed_binary",    %options) if $do_binary;
        run("speed_binomial",  %options) if $do_binomial;
        run("speed_priority",  %options) if $do_priority;
        run("speed_array_heap2",  %options) if $do_array;
    }
    if ($cachegrind) {
        run("speed_array",  %options, class  => $class, dirty => $dirty);
    } else {
        run("speed_hash",   %options, class  => $class, dirty => $dirty);
        run("speed_array",  %options, class  => $class, dirty => $dirty);
        run("speed_scalar", %options, class  => $class, dirty => $dirty);
        run("speed_scalar", %options, class  => $class, dirty => 1) if
            !$dirty && $class ne "Heap::Simple::Perl";
    }
}
exit $exit;
