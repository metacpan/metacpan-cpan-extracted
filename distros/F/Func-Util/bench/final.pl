#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Benchmark qw(cmpthese);
use List::Util ();
use Func::Util qw(final final_gt final_lt final_ge);

print "=" x 60, "\n";
print "final - Find Last Matching Element Benchmark\n";
print "=" x 60, "\n\n";

my @numbers = 1..1000;

# Pure Perl final using reverse
sub pure_final {
    my ($code, $arr) = @_;
    for my $i (reverse 0..$#$arr) {
        local $_ = $arr->[$i];
        return $arr->[$i] if $code->();
    }
    return undef;
}

print "=== final (callback) vs reverse+first ===\n";
cmpthese(-2, {
    'util::final'       => sub { final(sub { $_ > 500 }, \@numbers) },
    'pure_final'        => sub { pure_final(sub { $_ > 500 }, \@numbers) },
    'reverse+first'     => sub { List::Util::first { $_ > 500 } reverse @numbers },
});

print "\n=== final_gt vs reverse+first ===\n";
cmpthese(-2, {
    'util::final_gt'    => sub { final_gt(\@numbers, 500) },
    'reverse+first'     => sub { List::Util::first { $_ > 500 } reverse @numbers },
});

print "\n=== final_lt ===\n";
cmpthese(-2, {
    'util::final_lt'    => sub { final_lt(\@numbers, 500) },
    'reverse+first'     => sub { List::Util::first { $_ < 500 } reverse @numbers },
});

print "\n=== final_ge (hash - last adult) ===\n";
my @users = map { { id => $_, age => 15 + int(rand(50)) } } 1..1000;
cmpthese(-2, {
    'util::final_ge'    => sub { final_ge(\@users, 'age', 18) },
    'reverse+first'     => sub { List::Util::first { $_->{age} >= 18 } reverse @users },
});

print "\nDONE\n";
