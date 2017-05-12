#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 29;

BEGIN {
    use_ok('Forest::Tree');
    use_ok('Forest::Tree::Reader::SimpleTextFile');
    use_ok('Forest::Tree::Writer');
    use_ok('Forest::Tree::Writer::SimpleASCII');
    use_ok('Forest::Tree::Writer::SimpleHTML');
};

my $reader = Forest::Tree::Reader::SimpleTextFile->new;
$reader->read(\*DATA);

sub to_pure {
    my $tree = shift;

    Forest::Tree::Pure->new(
        ( $tree->has_node ? ( node => $tree->node ) : () ),
        children => [ map { to_pure($_) } @{ $tree->children } ],
    );
}

my $tree = $reader->tree;
my $pure = to_pure($tree);

foreach my $tree ( $tree, $pure ) {
    my $w = Forest::Tree::Writer::SimpleASCII->new(tree => $tree);
    isa_ok($w, 'Forest::Tree::Writer::SimpleASCII');

    isa_ok($w->tree, 'Forest::Tree::Pure');

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

foreach my $tree ( $tree, $pure ) {
    my $w = Forest::Tree::Writer::SimpleASCII->new(
        tree           => $tree,
        node_formatter => sub { '[' . (shift)->node . ']' }
    );
    isa_ok($w, 'Forest::Tree::Writer::SimpleASCII');

    isa_ok($w->tree, 'Forest::Tree::Pure');

    is($w->as_string, 
q{[1.0]
    [1.1]
    [1.2]
        [1.2.1]
[2.0]
    [2.1]
[3.0]
[4.0]
    [4.1]
        [4.1.1]
}, '.... got the right output');

}

foreach my $tree ( $tree, $pure ) {
    my $w = Forest::Tree::Writer::SimpleHTML->new(tree => $tree);
    isa_ok($w, 'Forest::Tree::Writer::SimpleHTML');

    isa_ok($w->tree, 'Forest::Tree::Pure');

    is($w->as_string, 
    q{<ul>
    <li>1.0</li>
    <ul>
        <li>1.1</li>
        <li>1.2</li>
        <ul>
            <li>1.2.1</li>
        </ul>
    </ul>
    <li>2.0</li>
    <ul>
        <li>2.1</li>
    </ul>
    <li>3.0</li>
    <li>4.0</li>
    <ul>
        <li>4.1</li>
        <ul>
            <li>4.1.1</li>
        </ul>
    </ul>
</ul>
}, '.... got the right output');
}

foreach my $tree ( $tree, $pure ) {
    my $w = Forest::Tree::Writer::SimpleHTML->new(
        tree           => $tree,
        node_formatter => sub { '<b>' . (shift)->node . '</b>' }
    );
    isa_ok($w, 'Forest::Tree::Writer::SimpleHTML');

    isa_ok($w->tree, 'Forest::Tree::Pure');

    is($w->as_string, 
    q{<ul>
    <li><b>1.0</b></li>
    <ul>
        <li><b>1.1</b></li>
        <li><b>1.2</b></li>
        <ul>
            <li><b>1.2.1</b></li>
        </ul>
    </ul>
    <li><b>2.0</b></li>
    <ul>
        <li><b>2.1</b></li>
    </ul>
    <li><b>3.0</b></li>
    <li><b>4.0</b></li>
    <ul>
        <li><b>4.1</b></li>
        <ul>
            <li><b>4.1.1</b></li>
        </ul>
    </ul>
</ul>
}, '.... got the right output');
}

__DATA__
1.0
    1.1
    1.2
        1.2.1
2.0
    2.1
3.0
4.0
    4.1
        4.1.1
