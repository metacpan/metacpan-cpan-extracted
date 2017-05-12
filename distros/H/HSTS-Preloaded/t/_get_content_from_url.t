use strict;
use warnings FATAL => 'all';

use Test::More;

use HSTS::Preloaded;

sub main_in_test {
    pass('Loaded ok');

    my $input = '
a
b
/ 0
// 1
// 2
    // 3

c
// 4
';

    my $expected_output = '
a
b
/ 0

c
';

    my $self = undef;

    is(
        HSTS::Preloaded::_get_data_without_comments($self, $input),
        $expected_output,
        '_get_data_without_comments()',
    );

    done_testing();
}
main_in_test();
