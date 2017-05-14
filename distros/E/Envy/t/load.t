# -*-perl-*-
use strict;
use Test; plan test => 8;
%ENV = (REGRESSION_ENVY_PATH => "./example/area1/etc/envy");
require Envy::Load;
ok 1;

ok $ENV{ENVY_CONTEXT}, '/perl/';

Envy::Load->import('area1');
ok $ENV{ETOP}, './example/area1';

{
    my $save = Envy::Load->new();

    $save->load('cc-tools');
    ok 0+(grep /ccs/, split(/:+/, $ENV{PATH} || '')), 1;

    $save->load('passwd');
    ok $ENV{R1}, $<;
    ok $ENV{E1}, $>;
}

ok 0+(grep /ccs/, split(/:+/, $ENV{PATH} || '')), 0;
ok !exists $ENV{R1};
