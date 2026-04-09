#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Benchmark qw(cmpthese);
use Func::Util qw(partition);

print "=" x 60, "\n";
print "partition - Split by Predicate Benchmark\n";
print "=" x 60, "\n\n";

my @numbers = 1..100;

# Pure Perl partition
sub pure_partition {
    my ($code, @list) = @_;
    my (@pass, @fail);
    for (@list) {
        if ($code->()) {
            push @pass, $_;
        } else {
            push @fail, $_;
        }
    }
    return (\@pass, \@fail);
}

my $is_even = sub { $_ % 2 == 0 };

print "=== partition 100 numbers (evens/odds) ===\n";
cmpthese(-2, {
    'util::partition' => sub { partition($is_even, @numbers) },
    'pure_partition'  => sub { pure_partition($is_even, @numbers) },
    'two_greps'       => sub { [grep { $_ % 2 == 0 } @numbers], [grep { $_ % 2 != 0 } @numbers] },
});

print "\nDONE\n";
