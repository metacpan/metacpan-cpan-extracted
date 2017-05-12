use strict;
use warnings;
use Test::More 'no_plan';
use Test::Exception;
use Test::Warn;

use_ok('Math::Fraction::Egyptian','to_egyptian');

# test normal behavior
is_deeply([ to_egyptian(0,1) ], []);
is_deeply([ to_egyptian(0,3) ], []);
is_deeply([ to_egyptian(0,4) ], []);
is_deeply([ to_egyptian(1,3) ], [3]);
is_deeply([ to_egyptian(1,4) ], [4]);
is_deeply([ to_egyptian(43,48) ], [2,3,16]);   # 43/48 = 1/2 + 1/3 + 1/16

# test input that is an improper fraction
{
    my @e;
    warning_like { @e = to_egyptian(1,1) } qr{1/1 is an improper};
    is_deeply(\@e,[]);
}

{
    my @e;
    warning_like { @e = to_egyptian(4,3) } qr{4/3 is an improper};
    is_deeply(\@e,[3]);
}


#is_deeply([ to_egyptian(4,3) ], [3]);
#is_deeply([ to_egyptian(1,1) ], []);

# test exceptions
dies_ok { to_egyptian(1,0) } qr{cannot convert fraction 1/0};

dies_ok { to_egyptian(1,0) } qr{cannot convert fraction 1/0};

# test dispatcher
my $ded = sub { die 'dies' };
dies_ok { to_egyptian(1,0, dispatcher => $ded) } qr{dies};

