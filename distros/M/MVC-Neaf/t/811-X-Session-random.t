#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf::X::Session;

my $sess = MVC::Neaf::X::Session->new;
my $rex  = $sess->session_id_regex;
$rex = qr(^$rex$);

my $times = shift || 1000;
my %uniq;

while ($times --> 0 ) {
    $uniq{ $sess->get_session_id }++;
};
my @dup = grep { $uniq{$_} > 1 } keys %uniq;

is (scalar @dup, 0, "No dupes")
    or diag "Dupe session ids: @dup";

my @bad = grep { $_ !~ $rex } keys %uniq;
is (scalar @bad, 0, "All session ids match regex" );

done_testing;
