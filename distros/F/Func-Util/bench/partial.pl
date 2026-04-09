#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Benchmark qw(cmpthese);
use Func::Util qw(partial);

print "=" x 60, "\n";
print "partial - Partial Application Benchmark\n";
print "=" x 60, "\n\n";

my $add = sub { $_[0] + $_[1] };
my $multiply = sub { $_[0] * $_[1] * $_[2] };

# Pure Perl partial
sub pure_partial {
    my ($fn, @bound) = @_;
    return sub { $fn->(@bound, @_) };
}

my $util_add5 = partial($add, 5);
my $pure_add5 = pure_partial($add, 5);

print "=== Call partial (1 bound arg) ===\n";
cmpthese(-2, {
    'util::partial' => sub { $util_add5->(10) },
    'pure_partial'  => sub { $pure_add5->(10) },
    'closure'       => sub { (sub { $add->(5, $_[0]) })->(10) },
});

my $util_mul2_3 = partial($multiply, 2, 3);
my $pure_mul2_3 = pure_partial($multiply, 2, 3);

print "\n=== Call partial (2 bound args) ===\n";
cmpthese(-2, {
    'util::partial' => sub { $util_mul2_3->(4) },
    'pure_partial'  => sub { $pure_mul2_3->(4) },
});

print "\n=== Create + call ===\n";
cmpthese(-2, {
    'util::partial' => sub { partial($add, 5)->(10) },
    'pure_partial'  => sub { pure_partial($add, 5)->(10) },
});

print "\nDONE\n";
