#!perl -T
use strict;
use warnings;

use Test::More tests => 41;

use lib 't/lib';
use Test::WidgetFactory;

{ # make a super-simple input field
  my ($html, $tree) = widget(struct => {
    name  => 'flavor',
    value => 'minty',
    class => 'orange',
  });

  my ($input) = $tree->look_down(_tag => 'input');

  isa_ok($input, 'HTML::Element');

  is(
    $input->attr('name'),
    'flavor',
    "got correct input name",
  );

  is(
    $input->attr('type'),
    'hidden',
    "structs are hidden inputs",
  );

  is(
    $input->attr('value'),
    'minty',
    "got correct form value",
  );

  is(
    $input->attr('class'),
    'orange',
    "class passed through",
  );
}

{ # let's make a hash
  my ($html, $tree) = widget(struct => {
    name  => 'pain',
    value => { hands => 'hurt', feet => 'fine' },
  });

  is($tree->content_list,  2, "there are two html elements");

  my ($feet, $hands) = sort { $a->attr('name') cmp $b->attr('name') }
                       $tree->look_down(_tag => 'input');

  isa_ok($feet,  'HTML::Element');
  isa_ok($hands, 'HTML::Element');

  is($feet->attr('name'),  'pain.feet',  "feet got correct input name");
  is($hands->attr('name'), 'pain.hands', "hands got correct input name");

  is($feet->attr('value'),  'fine',  "feet got correct value");
  is($hands->attr('value'), 'hurt', "hands got correct value");

  is($feet->attr('type'),  'hidden',  "feet got correct type");
  is($hands->attr('type'), 'hidden', "hands got correct type");
}

{ # let's make an array
  my ($html, $tree) = widget(struct => {
    name  => 'pain',
    value => [ qw(hands feet) ],
  });

  is($tree->content_list,  2, "there are two html elements");

  my (@pains) = $tree->look_down(_tag => 'input');

  isa_ok($_,  'HTML::Element') for @pains;

  is($pains[0]->attr('name'), 'pain.0', "pain.0 got correct input name");
  is($pains[1]->attr('name'), 'pain.1', "pain.1 got correct input name");

  is($pains[0]->attr('value'), 'hands', "pain.0 got correct value");
  is($pains[1]->attr('value'), 'feet',  "pain.1 got correct value");

  is($pains[0]->attr('type'), 'hidden', "pain.0 got correct type");
  is($pains[1]->attr('type'), 'hidden', "pain.1 got correct type");
}

{ # let's make a complex thing
  my ($html, $tree) = widget(struct => {
    name  => 'hero',
    value => [
      qw(hands feet),
      { shoulders => 'broad', eyes => 'black as pitch' },
      [ qw(tall dark handsome), { temper => 'latin' } ]
    ],
  });

  my @pairs = (
    'hero.0'           => 'hands',
    'hero.1'           => 'feet',
    'hero.2.eyes'      => 'black as pitch',
    'hero.2.shoulders' => 'broad',
    'hero.3.0'         => 'tall',
    'hero.3.1'         => 'dark',
    'hero.3.2'         => 'handsome',
    'hero.3.3.temper'  => 'latin',
  );

  my @elements = sort { $a->attr('name') cmp $b->attr('name') }
                 grep { ref $_ } $tree->guts;

  is(@elements, @pairs / 2, "there are as many elements as we expected");

  is($tree->content_list,  2, "there are two html elements");

  my $e = 0;
  while (my ($name, $value) = splice @pairs, 0, 2) {
    my $element = shift @elements;

    is($element->attr('name'),  $name,  "correct name for element $e");
    is($element->attr('value'), $value, "correct value for element $e");

    $e++;
  }
}
