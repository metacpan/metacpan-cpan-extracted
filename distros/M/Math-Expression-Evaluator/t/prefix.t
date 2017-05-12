use strict;
use warnings;
use Test::More;
BEGIN { plan tests => 9 }

use Math::Expression::Evaluator;

my $m = new Math::Expression::Evaluator;
ok($m, 'new works');

sub e {
    return $m->parse(shift)->val();
}
sub o {
    return $m->parse(shift)->optimize->val();
}

my @tests = (
        ['+2'       ,2      ,'Prefix + with number'],
        ['+(1+2)'   ,3      ,'Prefix + with expression'],
        ['-2'       ,-2     ,'Prefix - with number'],
        ['-(1+2)'   ,-3     ,'Prefix - with expression'],
);

for (@tests){
    is e($_->[0]), $_->[1], $_->[2];
    is o($_->[0]), $_->[1], $_->[2] . ' (optimized)';
}

# vim: sw=4 ts=4 expandtab
