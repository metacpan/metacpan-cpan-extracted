use strict;
local $^W = 1;
use Test::More 'no_plan';
use HTML::Element::Tiny;

my $tree = HTML::Element::Tiny->new(
  [ html =>
    [ head => [ title => "Hello" ] ],
    [ body => 
      [ div => { class => "stuff some" }, "some stuff" ],
      [ div => "more stuff", [ span => { id => "foo" }, " now with fooness" ]
      ],
      [ div => "this is the last of the stuff" ],
      [ div => "except for this stuff: ",
        [ table =>
          map { [ tr => [ td => $_ ], [ td => $_ ], [ td => $_ ] ] }
          1..60
        ],
      ],
    ],
  ]
);

SKIP: for my $type (qw(my Clone)) {
  unless ($type eq 'my' or $HTML::Element::Tiny::HAS{$type}) {
    skip "need $type $HTML::Element::Tiny::_modver{$type}", 500;
  }
  my $method = "_$type\_clone";
  my $clone = $tree->$method;

  for my $elem ($clone->all->not({ -tag => '-text' })) {
    my $root = $elem;
    $root = $root->parent while $root->parent;
    is($root, $clone, "got from $elem to $clone");
    ok(
      ! grep({ $_->parent != $elem }
        grep { $_->tag ne '-text' } $elem->children),
      "all $elem\'s children have it as a parent",
    );
  }
}
