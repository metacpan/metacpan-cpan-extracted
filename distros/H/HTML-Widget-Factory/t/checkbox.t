#!perl
use strict;
use warnings;

use Test::More tests => 11;

BEGIN { use_ok("HTML::Widget::Factory"); }

use lib 't/lib';
use Test::WidgetFactory;

{ # make a super-simple checkbox widget
  my ($html, $tree) = widget(checkbox => {
    name    => 'flavor',
    value   => 'minty',
    checked => 1,
  });
  
  my ($checkbox) = $tree->look_down(_tag => 'input');

  isa_ok($checkbox, 'HTML::Element');

  is(
    $checkbox->attr('name'),
    'flavor',
    "got correct checkbox name",
  );

  is(
    $checkbox->attr('value'),
    'minty',
    "it's got the right value!",
  );

  is(
    $checkbox->attr('type'),
    'checkbox',
    "it's a checkbox!",
  );

  ok(
    $checkbox->attr('checked'),
    "it's checked"
  );
}

{ # use value instead of checked, id instead of name
  my ($html, $tree) = widget(checkbox => {
    id    => 'flavor',
    value => 'minty',
  });
  
  my ($checkbox) = $tree->look_down(_tag => 'input');

  isa_ok($checkbox, 'HTML::Element');

  is(
    $checkbox->attr('name'),
    'flavor',
    "got correct checkbox name",
  );

  is(
    $checkbox->attr('value'),
    'minty',
    "got the right value",
  );

  is(
    $checkbox->attr('type'),
    'checkbox',
    "it's a checkbox!",
  );

  ok(
    ! $checkbox->attr('checked'),
    "it's not checked"
  );
}
