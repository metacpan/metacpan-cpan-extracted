use strict;
use Test::More;
use GitInsight::Util qw(label label_step);

subtest 'commit range 0..10', sub {
    label_step( 0 .. 10 );

    is label(0),  0, "label for 0 commit is 0";
    is label(1),  1, "label for 1 commit is 1";
    is label(2),  1, "label for 2 commit is 1";
    is label(3),  2, "label for 3 commit is 2";
    is label(4),  2, "label for 4 commit is 2";
    is label(5),  2, "label for 5 commit is 2";
    is label(6),  3, "label for 6 commit is 3";
    is label(7),  4, "label for 7 commit is 4";
    is label(8),  4, "label for 8 commit is 4";
    is label(9),  4, "label for 9 commit is 4";
    is label(10), 4, "label for 10 commit is 4";
    is label(20), 4, "label for 20 commit is 4";
};

subtest 'commit range 0..20', sub {
    label_step( 0 .. 20 );

    is label(0),  0, "label for 0 commit is 0";
    is label(1),  1, "label for 1 commit is 1";
    is label(2),  1, "label for 2 commit is 1";
    is label(3),  1, "label for 3 commit is 1";
    is label(4),  1, "label for 4 commit is 1";
    is label(5),  1, "label for 5 commit is 1";
    is label(6),  2, "label for 6 commit is 2";
    is label(7),  2, "label for 7 commit is 2";
    is label(8),  2, "label for 8 commit is 2";
    is label(9),  2, "label for 9 commit is 2";
    is label(10), 2, "label for 10 commit is 2";
    is label(11), 3, "label for 11 commit is 3";
    is label(12), 3, "label for 12 commit is 3";
    is label(13), 3, "label for 13 commit is 3";
    is label(14), 3, "label for 14 commit is 3";
    is label(15), 3, "label for 15 commit is 3";
    is label(16), 4, "label for 16 commit is 4";
    is label(17), 4, "label for 17 commit is 4";
    is label(18), 4, "label for 18 commit is 4";
    is label(19), 4, "label for 19 commit is 4";
    is label(20), 4, "label for 20 commit is 4";

};
done_testing;
