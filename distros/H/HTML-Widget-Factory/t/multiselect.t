#!perl
use strict;
use warnings;

use Test::More tests => 17;

BEGIN { use_ok("HTML::Widget::Factory"); }

use lib 't/lib';
use Test::WidgetFactory;

{ # make a select field with options
  my ($html, $tree) = widget(multiselect => {
    options => [ qw(portable rechargeable delicious diet) ],
    name    => 'options',
    value   => [ qw(diet portable) ],
    size    => 5,
  });

  my ($select) = $tree->look_down(_tag => 'select');

  is(
    $select->attr('name'),
    'options',
    "got correct input name",
  );

  ok(
    $select->attr('multiple'),
    "multiple attr is set",
  );

  my @options = $select->look_down(_tag => 'option');

  is(@options, 4, "we created four options");
  
  my @selected = $select->look_down(sub { $_[0]->attr('selected') });

  is(@selected, 2, "two options are selected");

  is(
    $selected[0]->attr('value'),
    'portable',
    "the first selected element is one we selected",
  );

  is(
    $selected[1]->attr('value'),
    'diet',
    "the second selected element is one we selected",
  );
}

{ # make a select field with options, nothing selected
  my ($html, $tree) = widget(multiselect => {
    options => [ qw(portable rechargeable delicious diet) ],
    name    => 'options',
    size    => 5,
  });

  my ($select) = $tree->look_down(_tag => 'select');

  is(
    $select->attr('name'),
    'options',
    "got correct input name",
  );

  my @options = $select->look_down(_tag => 'option');

  is(@options, 4, "we created four options");
  
  my @selected = $select->look_down(sub { $_[0]->attr('selected') });

  is(@selected, 0, "nothing is selected");
}

{ # make a select field with options, tweaked
  my ($html, $tree) = widget(multiselect => {
    options => [ 
      [ portable     => 'Can be carried', ],
      [ rechargeable => 'Many uses',      ],
      [ delicious    => 'Tastes great!',  ],
      [ diet         => 'Less filling!',  ],
    ],
    id      => 'options-food',
    values  => [ qw(diet portable) ],
    size    => 5,
  });

  my ($select) = $tree->look_down(_tag => 'select');

  is(
    $select->attr('id'),
    'options-food',
    "got correct input id",
  );

  is(
    $select->attr('name'),
    'options-food',
    "got correct input name (from id)",
  );

  my @options = $select->look_down(_tag => 'option');

  is(@options, 4, "we created four options");
  
  my @selected = $select->look_down(sub { $_[0]->attr('selected') });

  is(@selected, 2, "two options are selected");

  is(
    $selected[0]->attr('value'),
    'portable',
    "the first selected element is one we selected",
  );

  is(
    $selected[1]->attr('value'),
    'diet',
    "the second selected element is one we selected",
  );
}

{ # exception: invalid value
  eval {
    widget(multiselect => {
      options => [ qw(portable rechargeable delicious diet) ],
      value   => [ qw(delicious splenda-free) ],
      size    => 5,
    });
  };

  like($@, qr/not in given options/, "exception on invalid value");
}
