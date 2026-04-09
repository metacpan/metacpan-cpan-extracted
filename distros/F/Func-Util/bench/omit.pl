#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Benchmark qw(cmpthese);
use Func::Util qw(omit);

print "=" x 60, "\n";
print "omit - Remove Hash Keys Benchmark\n";
print "=" x 60, "\n\n";

my %hash = (a => 1, b => 2, c => 3, d => 4, e => 5);
my $href = \%hash;

# Pure Perl omit
sub pure_omit {
    my ($hash, @keys) = @_;
    my %skip = map { $_ => 1 } @keys;
    my %result;
    for my $k (keys %$hash) {
        $result{$k} = $hash->{$k} unless $skip{$k};
    }
    return \%result;
}

print "=== omit 2 keys ===\n";
cmpthese(-2, {
    'util::omit' => sub { omit($href, 'a', 'c') },
    'pure_omit'  => sub { pure_omit($href, 'a', 'c') },
});

print "\n=== omit 4 keys ===\n";
cmpthese(-2, {
    'util::omit' => sub { omit($href, 'a', 'b', 'c', 'd') },
    'pure_omit'  => sub { pure_omit($href, 'a', 'b', 'c', 'd') },
});

print "\nDONE\n";
