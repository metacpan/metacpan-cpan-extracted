# -*- mode: cperl; cperl-indent-level: 2; cperl-continued-statement-offset: 2; indent-tabs-mode: nil -*-
use Test::More tests => 7;
#use Test::More qw/no_plan/;
BEGIN { use_ok('Math::EMA') };

my $avg=Math::EMA->new;

ok $avg, 'object created';
cmp_ok sprintf('%.10f', $avg->set_param(60, 0.01) ), '==', 0.9261187281,
       'set_param';
cmp_ok sprintf('%.10f', $avg->alpha ), '==', 0.9261187281, 'retrieve alpha';

cmp_ok $avg->add(12), '==', 12, 'added the 1st value';
cmp_ok $avg->ema, '==', 12, 'ema after the 1st value';

$avg->add(0) for(1..60);

printf("# value after 60 iterations: %.10f\n", $avg->ema);
cmp_ok sprintf('%.10f', $avg->ema), '==', 0.12, 'ema after 60 iterations';
