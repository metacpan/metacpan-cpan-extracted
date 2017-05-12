#!perl
use strict;
use warnings;

use Test::More tests => 10;

BEGIN { use_ok("HTML::Widget::Factory"); }

use lib 't/lib';
use Test::WidgetFactory;

{ # make an empty password-entry widget, no password
  my ($html, $tree) = widget(password => {
    name  => 'pw',
  });
  
  my ($input) = $tree->look_down(_tag => 'input');

  isa_ok($input, 'HTML::Element');

  is(
    $input->attr('name'),
    'pw',
    "got correct input name",
  );

  is(
    $input->attr('type'),
    'password',
    "it's a password input!",
  );

  ok(
    ! $input->attr('value'),
    "the content has been replaced"
  );
}

{ # make a password-entry widget, password
  my ($html, $tree) = widget(password => {
    name  => 'pw',
    value => 'minty',
  });
  
  my ($input) = $tree->look_down(_tag => 'input');

  isa_ok($input, 'HTML::Element');

  is(
    $input->attr('name'),
    'pw',
    "got correct input name",
  );

  is(
    $input->attr('type'),
    'password',
    "it's a password input!",
  );

  is(
    $input->attr('value'),
    q{ }x8,
    "the content has been replaced"
  );
}

{ # make a password-entry widget, empty password
  my ($html, $tree) = widget(password => {
    name  => 'pw',
    value => '',
  });
  
  my ($input) = $tree->look_down(_tag => 'input');

  ok(
    ! $input->attr('value'),
    "no value for input if given input was empty string",
  );
}
