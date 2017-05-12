#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 21;

BEGIN {
    use_ok('Forest::Tree');
    use_ok('Forest::Tree::Reader::SimpleTextFile');
    use_ok('Forest::Tree::Writer');
    use_ok('Forest::Tree::Writer::SimpleASCII');
    use_ok('Forest::Tree::Writer::SimpleHTML');
};

my $tree = Forest::Tree->new(
    children => [
        Forest::Tree->new(node => '1.0'),
        Forest::Tree->new(node => '2.0'),
    ]
);

is($tree->get_child_at(0)->parent, $tree, '... correct parental relations');
is($tree->get_child_at(1)->parent, $tree, '... correct parental relations');

{
    my $w = Forest::Tree::Writer::SimpleASCII->new(tree => $tree);
    isa_ok($w, 'Forest::Tree::Writer::SimpleASCII');
    is($w->as_string,
q{1.0
2.0
}, '.... got the right output');

}

$tree->add_child(Forest::Tree->new(node => '3.0'));

{
    my $w = Forest::Tree::Writer::SimpleASCII->new(tree => $tree);
    isa_ok($w, 'Forest::Tree::Writer::SimpleASCII');
    is($w->as_string,
q{1.0
2.0
3.0
}, '.... got the right output');
}

$tree->add_child(Forest::Tree->new(node => '4.0'));

{
    my $w = Forest::Tree::Writer::SimpleASCII->new(tree => $tree);
    isa_ok($w, 'Forest::Tree::Writer::SimpleASCII');
    is($w->as_string,
q{1.0
2.0
3.0
4.0
}, '.... got the right output');
}

$tree->get_child_at(0)->add_children(
    Forest::Tree->new(node => '1.1'),
    Forest::Tree->new(node => '1.2'),
);

{
    my $w = Forest::Tree::Writer::SimpleASCII->new(tree => $tree);
    isa_ok($w, 'Forest::Tree::Writer::SimpleASCII');
    is($w->as_string,
q{1.0
    1.1
    1.2
2.0
3.0
4.0
}, '.... got the right output');
}

$tree->get_child_at(0)->get_child_at(1)->add_children(
    Forest::Tree->new(node => '1.2.1'),
);

{
    my $w = Forest::Tree::Writer::SimpleASCII->new(tree => $tree);
    isa_ok($w, 'Forest::Tree::Writer::SimpleASCII');
    is($w->as_string,
q{1.0
    1.1
    1.2
        1.2.1
2.0
3.0
4.0
}, '.... got the right output');
}

$tree->get_child_at(1)->add_children(
    Forest::Tree->new(node => '2.1'),
);

{
    my $w = Forest::Tree::Writer::SimpleASCII->new(tree => $tree);
    isa_ok($w, 'Forest::Tree::Writer::SimpleASCII');
    is($w->as_string,
q{1.0
    1.1
    1.2
        1.2.1
2.0
    2.1
3.0
4.0
}, '.... got the right output');

}

$tree->get_child_at(3)->add_children(
    Forest::Tree->new(
        node     => '4.1',
        children => [
            Forest::Tree->new(node => '4.1.1')
        ]
    ),
);


{
    my $w = Forest::Tree::Writer::SimpleASCII->new(tree => $tree);
    isa_ok($w, 'Forest::Tree::Writer::SimpleASCII');
    is($w->as_string,
q{1.0
    1.1
    1.2
        1.2.1
2.0
    2.1
3.0
4.0
    4.1
        4.1.1
}, '.... got the right output');

}
