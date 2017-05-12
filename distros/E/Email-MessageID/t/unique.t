use strict;
use warnings;
use Test::More tests => 1;
use Email::MessageID;

my $n = shift || 1000;
my %ids = map {; Email::MessageID->new->address => 1 } (1 .. $n);
is(keys %ids, $n, "$n unique message ids");
