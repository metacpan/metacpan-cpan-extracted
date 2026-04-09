#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Benchmark qw(cmpthese);
use Func::Util qw(count);

print "=" x 60, "\n";
print "count - Count Substring Occurrences Benchmark\n";
print "=" x 60, "\n\n";

my $str = "the quick brown fox jumps over the lazy dog the end the";
my $long_str = $str x 100;

# Pure Perl count using tr///
sub pure_count_tr {
    my ($str, $char) = @_;
    return ($str =~ tr///c) - (($str =~ s/\Q$char\E//g) || 0);
}

# Pure Perl count using split
sub pure_count_split {
    my ($str, $needle) = @_;
    return scalar(() = $str =~ /\Q$needle\E/g);
}

# Pure Perl count using index
sub pure_count_index {
    my ($str, $needle) = @_;
    my $count = 0;
    my $pos = 0;
    my $len = length($needle);
    while (($pos = index($str, $needle, $pos)) != -1) {
        $count++;
        $pos += $len;
    }
    return $count;
}

print "=== count 'the' in short string (4 occurrences) ===\n";
cmpthese(-2, {
    'util::count'   => sub { count($str, "the") },
    'regex_global'  => sub { scalar(() = $str =~ /the/g) },
    'index_loop'    => sub { pure_count_index($str, "the") },
});

print "\n=== count 'the' in long string (400 occurrences) ===\n";
cmpthese(-2, {
    'util::count'   => sub { count($long_str, "the") },
    'regex_global'  => sub { scalar(() = $long_str =~ /the/g) },
    'index_loop'    => sub { pure_count_index($long_str, "the") },
});

print "\n=== count 'xyz' (not found) ===\n";
cmpthese(-2, {
    'util::count'   => sub { count($str, "xyz") },
    'regex_global'  => sub { scalar(() = $str =~ /xyz/g) },
    'index_loop'    => sub { pure_count_index($str, "xyz") },
});

print "\nDONE\n";
