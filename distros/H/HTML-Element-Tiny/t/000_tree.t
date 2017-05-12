use strict;
local $^W = 1;
use Test::More 'no_plan';

BEGIN { use_ok('HTML::Element::Tiny') }

my $tree = HTML::Element::Tiny->new(
  [ div =>
    [ ul => { id => 'mylist', class => 'menu foo' },
      map({ [ li => "hello $_" ] } qw(alice bob sue trent)),
    ],
  ]
);

is($tree->parent, undef, 'no parent for root');
is(
  scalar $tree->children, 1,
  "root has one child",
);

my $div = $tree->find_one({ -tag => 'div' });
is($div->tag, 'div', "find found a div");
is($div, $tree, "it is the tree");

my $ul = $tree->find_one({ id => 'mylist' });
is($ul->tag, 'ul', "find found an ul");
is($ul->id, 'mylist', "it has the right id");
is($ul->parent, $div, "it has the right parent");
for (qw(menu foo)) {
  is($tree->find_one({ class => $_ }), $ul,
    "it can be found by class '$_'");
}
is($tree->find_one({ class => "menu foo" }), $ul,
  "it can be found by classes 'menu foo'");

for my $elem ($tree, $div, $ul) {
  for my $child ($elem->children) {
    is($child->parent, $elem, "child has parent");
  }
}

my $p = HTML::Element::Tiny->new([ p => "new node" ]);
is($p->parent, undef);
$tree->append($p);
is($p->parent, $tree, "did not clone element without parent");
$tree->append($p);
is($tree->find({ -tag => 'p' })->size, 2, "cloned element with parent");
$tree->prepend([ p => "new node 3" ]);
is($tree->find({ -tag => 'p' })->size, 3, "new elem from lol");

is($tree->remove_child($tree->find({ -tag => 'p' }))->size, 3,
  "removed 3 p tags");
is($tree->find({ -tag => 'p' })->size, 0, "no p elems left");
is($p->parent, undef, "removed child's parent is undef");
is($tree->remove_child(0)->size, 1, "removed 1 child by index");
is($tree->children, 0, "removed only child");
is($ul->parent, undef, "removed child's parent is undef");
