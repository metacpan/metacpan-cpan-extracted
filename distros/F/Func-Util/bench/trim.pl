#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Benchmark qw(cmpthese);
use Func::Util qw(trim ltrim rtrim);

print "=" x 60, "\n";
print "trim/ltrim/rtrim Benchmark\n";
print "=" x 60, "\n\n";

my $str = "   hello world   ";

print "=== trim ===\n";
cmpthese(-2, {
    'util::trim'  => sub { trim($str) },
    'regex_s///'  => sub { my $s = $str; $s =~ s/^\s+|\s+$//g; $s },
    'two_regex'   => sub { my $s = $str; $s =~ s/^\s+//; $s =~ s/\s+$//; $s },
});

print "\n=== ltrim ===\n";
cmpthese(-2, {
    'util::ltrim' => sub { ltrim($str) },
    'regex'       => sub { my $s = $str; $s =~ s/^\s+//; $s },
});

print "\n=== rtrim ===\n";
cmpthese(-2, {
    'util::rtrim' => sub { rtrim($str) },
    'regex'       => sub { my $s = $str; $s =~ s/\s+$//; $s },
});

print "\n=== trim (already trimmed) ===\n";
my $trimmed = "hello world";
cmpthese(-2, {
    'util::trim'  => sub { trim($trimmed) },
    'regex_s///'  => sub { my $s = $trimmed; $s =~ s/^\s+|\s+$//g; $s },
});

print "\nDONE\n";
