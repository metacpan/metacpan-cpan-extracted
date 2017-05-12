#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

# TEST SCOPE: These tests exercise the ":split" keyword

plan tests => 12;

# Since there isn't a default behavior with regards to :split, and it doesn't
# carry over like the flags do, that actually simplifies the set of test cases.

$ENV{SPLIT1} = 'a:b:c';
$ENV{SPLIT2} = 'a-b--c';
$ENV{SPLIT3} = 'a--b--c-d';
$ENV{SPLIT4} = '1,2,3';
$ENV{SPLIT5} = '4,5,6';
$ENV{SPLIT6} = '7,8,9';

my $eval_ret;
my $namespace = 'namespace0000';

# 1. Basic
$eval_ret = eval qq|
package namespace1;
use Env::Export qw(:split : SPLIT1);
1;
|;
SKIP: {
    skip "Error in eval<1>: $@", 2 if (! $eval_ret);

    is(scalar(namespace1::SPLIT1()), 3, 'Basic :split, count');
    is(join('|', namespace1::SPLIT1()), 'a|b|c', 'Basic :split');
}

# 2. Make sure null shows up
$eval_ret = eval qq|
package namespace2;
use Env::Export qw(:split - SPLIT2);
1;
|;
SKIP: {
    skip "Error in eval<2>: $@", 2 if (! $eval_ret);

    is(scalar(namespace2::SPLIT2()), 4, ':split with an empty, count');
    is(join('|', namespace2::SPLIT2()), 'a|b||c', ':split with an empty');
}

# 3. Regex test
$eval_ret = eval qq|
package namespace3;
use Env::Export (':split' => qr/-{2,}/, 'SPLIT3');
1;
|;
SKIP: {
    skip "Error in eval<3>: $@", 2 if (! $eval_ret);

    is(scalar(namespace3::SPLIT3()), 3, ':split with regex, count');
    is(join('/', namespace3::SPLIT3()), 'a/b/c-d', ':split with regex');
}

# 4 & 5. Carries over to a multi-key match
$eval_ret = eval qq|
package namespace45;
use Env::Export (':split' => q{,}, qr/SPLIT[45]/);
1;
|;
SKIP: {
    skip "Error in eval<45>: $@", 4 if (! $eval_ret);

    is(scalar(namespace45::SPLIT4()), 3, ':split carryover [1], count');
    is(join(',', namespace45::SPLIT4()), $ENV{SPLIT4}, ':split carryover [1]');
    is(scalar(namespace45::SPLIT5()), 3, ':split carryover [2], count');
    is(join(',', namespace45::SPLIT5()), $ENV{SPLIT5}, ':split carryover [2]');
}

# 6. Test :link with :split
$eval_ret = eval qq|
package namespace6;
use Env::Export (':link' => ':split' => q{,}, 'SPLIT6');
1;
|;
SKIP: {
    skip "Error in eval<6>: $@", 2 if (! $eval_ret);

    $ENV{SPLIT6} = 'a,b,c';
    is(scalar(namespace6::SPLIT6()), 3, ':split + :link, count');
    is(join('|' => namespace6::SPLIT6()), 'a|b|c', ':split + :link');
}

exit;
