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

my $elems = $tree->all->not({ -tag => '-text' });
isa_ok($elems, 'HTML::Element::Tiny::Collection');
is($elems->size, 9, "all non-text == 9 elems");

$elems = $tree->find({ -tag => 'p' });
isa_ok($elems, 'HTML::Element::Tiny::Collection');
is($elems->size, 5, "p == 5 elems");

is($elems->filter({ id => "" })->size, 3, "filter");
is($elems->grep({ id => "" })->size, 3, "grep");
is($elems->not({ id => "" })->size, 2, "not");

is_deeply(
  [ $elems->map(sub { $_->attr('id') }) ],
  [ 'intro', undef, undef, undef, 'conclusion' ],
  'map (id)',
);

eval { $elems->one };
like $@, '/not exactly one element/';
eval { $elems->filter({ id => "blort" })->one };
like $@, '/not exactly one element/';
my $one = eval { $elems->filter({ id => "intro" })->one };
is $@, '', "one didn't die";
is $one, $elems->[0];

is_deeply(
  [ $elems->all ],
  [ $tree->find_one({ -tag => 'body' })->children ],
);

$elems->attr({ id => undef });
is($elems->filter({ id => "" })->size, 5, "all p elems have no id now");
