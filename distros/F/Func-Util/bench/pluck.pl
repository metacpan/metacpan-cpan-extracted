#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Benchmark qw(cmpthese);
use Func::Util qw(pluck);

print "=" x 60, "\n";
print "pluck - Extract Property from Array of Hashes Benchmark\n";
print "=" x 60, "\n\n";

my @users = map { { id => $_, name => "user$_", age => 20 + $_ } } 1..100;

# Pure Perl pluck
sub pure_pluck {
    my ($aref, $key) = @_;
    return map { $_->{$key} } @$aref;
}

print "=== pluck 'id' from 100 hashes ===\n";
cmpthese(-2, {
    'util::pluck' => sub { pluck(\@users, 'id') },
    'pure_pluck'  => sub { pure_pluck(\@users, 'id') },
    'map'         => sub { map { $_->{id} } @users },
});

print "\n=== pluck 'name' ===\n";
cmpthese(-2, {
    'util::pluck' => sub { pluck(\@users, 'name') },
    'map'         => sub { map { $_->{name} } @users },
});

print "\nDONE\n";
