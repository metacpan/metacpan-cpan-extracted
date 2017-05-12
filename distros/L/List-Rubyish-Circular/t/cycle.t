use strict;
use warnings;
use Test::More;

use List::Rubyish::Circular;

subtest 'cycle' => sub {
    my $list = List::Rubyish::Circular->new(1, 2, 3, 4, 5);


    is_deeply $list->cycle->to_a,    [2, 3, 4, 5, 1];
    is_deeply $list->cycle(2)->to_a, [4, 5, 1, 2, 3];
};

subtest 'rcycle' => sub {
    my $list = List::Rubyish::Circular->new(1, 2, 3, 4, 5);

    is_deeply $list->rcycle->to_a,    [5, 1, 2, 3, 4];
    is_deeply $list->rcycle(2)->to_a, [3, 4, 5, 1, 2];
};

subtest 'destractive opperation' => sub {
    my $list = List::Rubyish::Circular->new(1, 2, 3);

    $list->push(4, 5);
    is_deeply $list->to_a,           [1, 2, 3, 4, 5];
    is_deeply $list->cycle->to_a,    [2, 3, 4, 5, 1];
    is_deeply $list->cycle(2)->to_a, [4, 5, 1, 2, 3];

    $list->unshift(-1, 0);
    is_deeply $list->to_a,           [-1, 0, 4, 5, 1, 2, 3];

    is_deeply $list->cycle->to_a,    [0, 4, 5, 1,  2, 3, -1];
    is_deeply $list->cycle(2)->to_a, [5, 1, 2, 3, -1, 0,  4];
};

done_testing;
