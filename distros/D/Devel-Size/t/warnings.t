#!/usr/bin/perl -w

use strict;
use Test::More;

BEGIN {
    # Not on CPAN yet. Interface may change. Mostly for my local use currently.
    unless (eval 'use Test::PerlRun; 1') {
	die $@ unless $@ =~ m!^Can't locate Test/PerlRun\.pm in \@INC!;
	plan(skip_all => 'no Test::PerlRun found')
    }
}

use Devel::Size ':all';

my %warn = (
	    F => "Devel::Size: Calculated sizes for FMs are incomplete\n",
	    R => "Devel::Size: Calculated sizes for compiled regexes are incompatible, and probably always will be\n"
	   );

sub test_stdout {
    my ($yell, $expecting, $what, $victim, $funcname, $expect) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $yell = "\$Devel::Size::warn = $yell\n;" if length $yell;
    my $want = '';
    if ($expecting) {
	foreach (split //, $expect) {
	    die "No warning for $_" unless $warn{$_};
	    $want .= $warn{$_};
	}
    }

    my $code = "$funcname($victim)";
    my $desc = "For $what, $expect, $code";

    perlrun_stdout_is({file => '-', stdin => <<"EOP"}, $want, $desc);
use strict;
use warnings;
use blib;
use Devel::Size ':all';

format STDOUT =
.

format STDERR =
.

$yell;
$code;
EOP
}

my $formatref1 = '*STDOUT{FORMAT}';
my $formatref2 = '*STDERR{FORMAT}';
my $coderef = 'sub {//}';

foreach (['', 1, 'defaults'], ['0', 0, 'yell = 0'], ['1', 1, 'yell = 1']) {
    my ($yell, $expecting, $what) = @$_;
    foreach(['[]', '', ''],
	    [$formatref1, 'F', 'F'],
	    [$coderef, 'R', 'R'],
	    ["[$formatref1]", '', 'F'],
	    ["[$formatref2]", '', 'F'],
	    ["[$formatref1, $formatref2]", '', 'F'],
	    ["[$coderef]", '', 'R'],
	    ["[$coderef, $coderef]", '', 'R'],
	    # The current implementation processes the list in reverse.
	    ["[$formatref1, $coderef]", '', 'RF'],
	    ["[$coderef, $formatref1]", '', 'FR'],
	    ["[$formatref1, $coderef, $formatref2]", '', 'FR'],
	    ["[$formatref1, $coderef, $formatref2, $coderef]", '', 'RF'],
	    ["[$formatref1, $coderef, $coderef, $formatref2]", '', 'FR'],
	    ["[$formatref1, $formatref2, $coderef, $coderef]", '', 'RF'],
	    ["[$coderef, $formatref1]", '', 'FR'],
	    ["[$coderef, $formatref1, $coderef]", '', 'RF'],
	    ["[$coderef, $formatref1, $coderef, $formatref2]", '', 'FR'],
	    ["[$coderef, $formatref1, $formatref2, $coderef]", '', 'RF'],
	    ["[$coderef, $coderef, $formatref1, $formatref2]", '', 'FR'],
	   ) {
	my ($victim, $size, $total) = @$_;
	test_stdout($yell, $expecting, $what, $victim, 'size', $size);
	test_stdout($yell, $expecting, $what, $victim, 'total_size', $total);
    }
}

done_testing();
