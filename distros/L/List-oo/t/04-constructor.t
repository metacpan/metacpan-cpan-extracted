#!/usr/bin/perl

# t/04-constructor.t
# Contributed by Jim Keenan
BEGIN {
    use Test::More 
    # tests => 1;
    qw(no_plan);
    use_ok('List::oo', qw| L |);
}
use strict;
use warnings;

my $l = List::oo->new();
isa_ok($l, 'List::oo');

my @a0 = qw(abel abel baker camera delta edward fargo golfer);
my @a1 = qw(baker camera delta delta edward fargo golfer hilton);

my $m = List::oo->new(@a0);
isa_ok($m, 'List::oo');

my $n = L(@a0);
isa_ok($n, 'List::oo');

is_deeply($m, $n, "new and L return same structure");
is_deeply( List::oo->new(@a1), L(@a1), "new and L return same structure");

__END__
use Data::Dumper;
my @a2 = qw(fargo golfer hilton icon icon jerky);
my @a3 = qw(fargo golfer hilton icon icon);
my @a4 = qw(fargo fargo golfer hilton icon);
my @a8 = qw(kappa lambda mu);
print STDERR Dumper(\$m);
print STDERR Dumper(\$n);
