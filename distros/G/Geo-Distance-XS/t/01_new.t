use strict;
use warnings;
use Geo::Distance::XS;
use Test::More;

my $geo = Geo::Distance->new;
isa_ok $geo, 'Geo::Distance', 'new';
can_ok 'Geo::Distance', qw(distance formula);
cmp_ok scalar @Geo::Distance::XS::FORMULAS, '>', 2, '@FORMULAS exists';

done_testing;
