#!/usr/bin/env perl

use warnings;
use strict;

use lib 't/lib';
use TestCommon;

use File::KDBX::Util qw(:erase);
use Test::More;

my $data1   = 'hello';
my $data2   = 'hello';
my $hash1   = {foo => 'secret'};
my $array1  = [qw(bar baz)];

erase $data1, \$data2, $hash1, $array1;
is $data1, undef, 'Erase by alias';
is $data2, undef, 'Erase by reference';
is scalar keys %$hash1, 0, 'Erase by hashref';
is scalar @$array1, 0, 'Erase by arrayref';

{
    my $data3 = 'hello';
    my $cleanup = erase_scoped $data3;
    is $data3, 'hello', 'Data not yet erased';
    undef $cleanup;
    is $data3, undef, 'Scoped erased';
}

sub get_secret {
    my $secret = 'conspiracy';
    my $cleanup = erase_scoped \$secret;
    return $secret;
}

my $another;
{
    my $thing = get_secret();
    $another = $thing;
    is $thing, 'conspiracy', 'Data not yet erased';
    undef $thing;
    is $thing, undef, 'Scope erased';
}
is $another, 'conspiracy', 'Data not erased in the other scalar';

done_testing;
