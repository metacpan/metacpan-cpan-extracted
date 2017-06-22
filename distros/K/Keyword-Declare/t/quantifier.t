use warnings;
use strict;

use Test::More;

use Keyword::Declare;

keyword once (Int $n) {{{
    ok «$n» == 1, 'once';
}}}

keyword once_or_more (Int+ $n) {
    my @count = split /\s+/, $n;
    return 'ok ' .scalar(@count).' >= 1, "once_or_more";';
}

keyword zero_or_more (Int* $n) {
    my @count = split /\s+/, $n;
    return 'ok ' .scalar(@count).' >= 0, "zero_or_more";';
}

keyword optional (Int? $n) {
    my @count = split /\s+/, $n;
    return 'ok ' .scalar(@count).' >= 0 && '.scalar(@count).' <=1, "optional";';
}

keyword once_or_more_minimal (Int+? $n) {
    my @count = split /\s+/, $n;
    return 'ok ' .scalar(@count).' == 1, "once_or_more_minimal";';
}

keyword zero_or_more_minimal (Int*? $n) {
    return "ok '$n' eq '', 'zero_or_more_minimal';";
}

keyword optional_minimal (Int?? $n) {
    return "ok '$n' eq '', 'optional_minimal';";
}

keyword sequence (Int+? $first, Int++ @all, Int? $none) {
    ok $first == 1, 'sequence first';
    ok @all == 3, 'sequence all';
    is $none, '', 'sequence none';
}

sequence 1 2 3 4;

once 1;
once_or_more 1;
once_or_more 1 2;
once_or_more 1 2 3;
zero_or_more;
zero_or_more 4;
zero_or_more 5 6 7 8 9 10;
optional;
optional 99;
once_or_more_minimal 1;
once_or_more_minimal 1 1;
zero_or_more_minimal;
zero_or_more_minimal 1;
zero_or_more_minimal 1;
optional_minimal;
optional_minimal 1;

done_testing();

