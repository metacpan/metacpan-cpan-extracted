use strict;
local $^W = 1;
use Test::More 'no_plan';
use HTML::Element::Tiny;

my $tree = HTML::Element::Tiny->new(
  [ html =>
    [ head => 
      [ title => "test" ],
    ],
    [ body =>
      [ p => { id => "intro" }, "Welcome to stuff" ],
      [ p => "here's some more stuff" ],
      [ p => "stuff sure is great" ],
      [ p => "it's make of win" ],
      [ p => { id => "conclusion" }, "so use stuff" ],
    ],
  ],
);

sub elems_ok {
  my ($iter, $count, $label, $spec) = @_;
  my @elems;
  while (my $elem = $iter->next) { push @elems, $elem }
  my $elems = HTML::Element::Tiny::Collection->new(@elems);
  is($elems->size, $count, "$label: $count items");
  if ($spec and %$spec) {
    is($elems->filter($spec)->size, $count, "$label: all match");
  }
}

elems_ok($tree->iter, 15, "all elems");
elems_ok($tree->find_iter({ -tag => '-text' }), 6, "text elems",
  { -tag => '-text' });
