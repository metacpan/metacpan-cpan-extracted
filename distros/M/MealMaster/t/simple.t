#!perl
use strict;
use warnings;
use IO::File;
use Test::More tests => 82;
use_ok('MealMaster');

my $mm = MealMaster->new();
isa_ok($mm, 'MealMaster');

my @recipes = $mm->parse("t/31000.mmf");
is(scalar(@recipes), 132, "Parsed all recipes");

my $r = $recipes[0];
isa_ok($r, 'MealMaster::Recipe');
is($r->title, "HOMEMADE GRANOLA (ALASKAN)");
eq_array($r->categories, ["Snacks"]);
is($r->yield, "6 Servings");

my $ingredients = $r->ingredients;
is(scalar(@$ingredients), 11);

my @t = (
  '1/3', 'c', 'Instant cream of wheat (prepared)',
  '3 1/2', 'c', 'Quick oats',
  '1', 'ts', 'Vanilla extract',
  '2', 'ts', 'Cinnamon',
  '', '', 'Small pinch nutmeg',
  '1', 'c', 'Applesauce',
  '1', 'ts', 'Salt',
  '1/2', 'c', 'Melted butter',
  '1/2', 'c', 'Chopped nuts',
  '1', 'c', 'Raisins',
  '1/2', 'lb', 'Brown sugar',
);

check_ingredients($ingredients, @t);
is($r->directions, '**** HOMEMADE GRANOLA ****
Mix all the ingredients; spread mixture evenly on a large cookie
sheet and bake at 350 degrees (F) for 20 minutes, stirring with a
fork to brown evenly. Reduce heat to 300 degrees (F) or 325 degrees
(F) and continue baking until brown and fairly dry. Store at room
temperature in a covered container. ************************* Recipe
from "COOKING ALASKAN", page 402
');



$r = $recipes[-1];
isa_ok($r, 'MealMaster::Recipe');
is($r->title, "HOT VANILLA SAUCE");
eq_array($r->categories, ["Sauces", "Desserts", "Appetizers", "Microwave"]);
is($r->yield, "4 Servings");

$ingredients = $r->ingredients;
is(scalar(@$ingredients), 5);

@t = (
'1', 'c', 'Sugar',
'2', 'tb', 'Cornstarch',
'2', 'c', 'Water',
'1/4', 'c', 'Butter or margarine',
'2', 'ts', 'Vanilla extract',
);

check_ingredients($ingredients, @t);
is($r->directions, "1. Combine sugar and cornstarch in a deep, 1-quart, heat- resistant
non-metallic casserole. 2. Gradually add water, stirring constantly.
3. Add butter and heat, uncovered, in Microwave Oven 5 minutes; stir
every 1 1/2 minutes. 4. Heat, uncovered, in Microwave Oven an
additional 3 minutes or until sauce is thickened and clear. Makes 2
cups
");





@recipes = $mm->parse("t/0222-1.TXT");
is(scalar(@recipes), 110, "Parsed all recipes");

$r = $recipes[-1];
isa_ok($r, 'MealMaster::Recipe');
is($r->title, "Crumb Topping Mix");
eq_array($r->categories, ["Master mix"]);
is($r->yield, "1");

$ingredients = $r->ingredients;
is(scalar(@$ingredients), 5);

@t = (
  '1 1/3', 'c', 'Brown Sugar, Firmly Packed',
  '2', 'ts', 'Cinnamon Or To Taste',
  '3/4', 'c', 'Butter or Margarine',
  '1', 'c', 'Unbleached Flour',
  '1/2', 'ts', 'Nutmeg',
);

check_ingredients($ingredients, @t);
is($r->directions, 'In a medium bowl, combine brown sugar, flour and spices.  Blend well. With
a pastry blender cut in butter or margarine until mixture is very fine. Put
in a 1-quart airtight container and label as Crumb Topping Mix. Store in
the refregator and use within 1 to 2 months.
Makes about 2 cups of mix.
Use Crumb Topping Mix on cobblers, fruit pies, puddings, ice cream and
fruit cups.
');




sub check_ingredients {
  my($ingredients, @t) = @_;
  my @i = @$ingredients;
  while (@t) {
    my $q = shift @t;
    my $m = shift @t;
    my $p = shift @t;
    my $i = shift @i;
    is($i->quantity, $q);
    is($i->measure, $m);
    is($i->product, $p);
  }
}
