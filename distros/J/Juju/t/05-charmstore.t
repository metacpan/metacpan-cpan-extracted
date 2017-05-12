#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

diag("Test querying charm store");

use_ok('Juju::Util');
my $util = Juju::Util->new;

my $res = $util->query_cs('wordpress', 'precise');

ok( $res->{charm}->{name} eq 'wordpress',
    'can query charm with series defined'
);

$res = $util->query_cs('mysql');

ok($res->{charm}->{distro_series} eq 'trusty', 'can query default series');

dies_ok { $util->query_cs } 'dies on no charm defined';

dies_ok { $util->query_cs('wordpress', 'lucid') }
'dies on invalid series specified';

dies_ok { $util->query_cs('wordpress', 'trusty') }
'dies on no charm found for series';

done_testing();
