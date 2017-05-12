# -*- mode: Perl; -*-
package SupportArgumentsTest;

use parent qw(Eve::Test);

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Eve::Support;

sub test_unique : Test(3) {
    is_deeply(
        Eve::Support::unique(list => [1, 3, 4, 2]),
        [1, 3, 4, 2]);

    is_deeply(
        Eve::Support::unique(list => [1, 3, 1, 2]),
        [1, 3, 2]);

    my $items = [{}, {}, {}];
    is_deeply(
        Eve::Support::unique(
            list => [$items->[0], $items->[1], $items->[2], $items->[1]]),
        [$items->[0], $items->[1], $items->[2]]);

}

sub test_open : Test(2) {
    for my $content ('some text', 'another text') {
        my $filehandle = Eve::Support::open(
            mode => '<', file => \ $content);
        is(<$filehandle>, $content);
    }
}

sub test_indexed_hash : Test {
    is_deeply(
        [keys %{Eve::Support::indexed_hash('1' => 2, '3' => 4, '5' => 6)}],
        [1, 3, 5]);
}

sub test_trim : Test(2) {
    is_deeply(
        [map(Eve::Support::trim(string => $_),
             '  ', '   a', 'b   ', ' c  ')],
        ['', 'a', 'b', 'c']);

    throws_ok(
        sub { Eve::Support::trim(string => undef); },
        'Eve::Error::Value');
}

1;
