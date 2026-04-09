#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Benchmark qw(cmpthese);
use Func::Util qw(compose);

print "=" x 60, "\n";
print "compose - Function Composition Benchmark\n";
print "=" x 60, "\n\n";

my $double = sub { $_[0] * 2 };
my $add_one = sub { $_[0] + 1 };
my $square = sub { $_[0] ** 2 };

# Pure Perl compose
sub pure_compose {
    my @fns = @_;
    return sub {
        my $val = shift;
        $val = $_->($val) for reverse @fns;
        return $val;
    };
}

my $util_composed = compose($square, $add_one, $double);
my $pure_composed = pure_compose($square, $add_one, $double);

print "=== Composed function call (3 functions) ===\n";
cmpthese(-2, {
    'util::compose'  => sub { $util_composed->(5) },
    'pure_compose'   => sub { $pure_composed->(5) },
    'nested_calls'   => sub { $square->($add_one->($double->(5))) },
});

print "\n=== Creation + call ===\n";
cmpthese(-2, {
    'util::compose'  => sub { compose($square, $add_one, $double)->(5) },
    'pure_compose'   => sub { pure_compose($square, $add_one, $double)->(5) },
});

print "\nDONE\n";
