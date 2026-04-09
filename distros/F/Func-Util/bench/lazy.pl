#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Benchmark qw(cmpthese);
use Func::Util qw(lazy force);

print "=" x 60, "\n";
print "lazy/force - Lazy Evaluation Benchmark\n";
print "=" x 60, "\n\n";

# Pure Perl lazy
sub pure_lazy {
    my $code = shift;
    my $forced = 0;
    my $value;
    return sub {
        unless ($forced) {
            $value = $code->();
            $forced = 1;
        }
        return $value;
    };
}

sub pure_force {
    my $lazy = shift;
    return ref($lazy) eq 'CODE' ? $lazy->() : $lazy;
}

my $computation = sub { my $x = 0; $x += $_ for 1..100; $x };

print "=== Force cached value ===\n";
my $util_lazy = lazy { $computation->() };
my $pure_lazy = pure_lazy($computation);
force($util_lazy);  # warm up
pure_force($pure_lazy);  # warm up

cmpthese(-2, {
    'util::force'  => sub { force($util_lazy) },
    'pure_force'   => sub { pure_force($pure_lazy) },
});

print "\n=== Create + force (first time) ===\n";
cmpthese(-2, {
    'util::lazy+force' => sub { force(lazy { 42 }) },
    'pure_lazy+force'  => sub { pure_force(pure_lazy(sub { 42 })) },
});

print "\nDONE\n";
