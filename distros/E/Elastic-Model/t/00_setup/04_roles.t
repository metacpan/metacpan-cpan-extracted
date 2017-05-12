#!/usr/bin/perl

use strict;
use warnings;
use Test::More 0.96;
use Test::Moose;
use Test::Deep;

use lib 't/lib';

our $es;
do 'es.pl';

use_ok 'RoleTest' || print 'Bail out';

my $model = new_ok( 'RoleTest', [ es => $es ], 'Model' );
isa_ok my $ns = $model->namespace('roletest'), 'Elastic::Model::Namespace';
ok my $map = $ns->mappings->{class}{properties}, 'Got mappings';

ok $map->{top}, 'Has top field';
ok !$map->{one}, 'Excluded field one';

cmp_deeply $map->{two}, { type => 'date' }, 'Field two is type date';

cmp_deeply $map->{three}, { type => 'integer' },
    'Field three is type integer';

cmp_deeply $map->{four}, { index => 'not_analyzed', type => 'string' },
    'Field four is not_analyzed';

done_testing;

__END__

