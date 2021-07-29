#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use IntRange::Iter qw(intrange_iter);

sub iter_vals {
    my $iter = shift;
    my @vals;
    while (defined(my $val = $iter->())) { push @vals, $val }
    \@vals;
}

subtest intrange_iter => sub {
    dies_ok { intrange_iter('') };
    dies_ok { intrange_iter('1-') };

    is_deeply(iter_vals(intrange_iter('1')), [1]);

    is_deeply(iter_vals(intrange_iter('1-3')), [1,2,3]);
    is_deeply(iter_vals(intrange_iter('1 - 3')), [1,2,3]);
    is_deeply(iter_vals(intrange_iter('1,5-10,15')), [1,5..10,15]);
    is_deeply(iter_vals(intrange_iter('1,10-5,15')), [1,15]); # TODO: should we die instead?

    dies_ok { intrange_iter('1-3,4..6') };
    dies_ok { intrange_iter({allow_dash=>0, allow_dotdot=>1}, '1-3,4..6') };
    is_deeply(iter_vals(intrange_iter({allow_dash=>0, allow_dotdot=>1}, '4..6')), [4..6]);
    is_deeply(iter_vals(intrange_iter({allow_dotdot=>1}, '1-3,4..6')), [1..6]);

    is_deeply(iter_vals(intrange_iter({allow_dotdot=>1}, '1..3')), [1,2,3]);
    is_deeply(iter_vals(intrange_iter({allow_dotdot=>1}, '1 .. 3')), [1,2,3]);
};

done_testing;
