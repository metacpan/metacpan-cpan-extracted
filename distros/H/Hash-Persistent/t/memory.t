#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib';
use Test::More;

use Hash::Persistent::Memory;

my $state = Hash::Persistent::Memory->new;
$state->{foo} = 5;
is $state->{foo}, 5, "works as a simple hashref";

$state->commit;
undef $state;

$state = Hash::Persistent::Memory->new;
is $state->{foo}, undef, "nothing restored on object's recreation";

$state->{foo} = 6;
$state->remove;
is_deeply {%$state}, {}, "remove removes data from memory too";

done_testing;
