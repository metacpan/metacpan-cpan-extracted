#!perl
use strict;
use warnings;

use Test::More tests => 19;

BEGIN { use_ok("HTML::Widget::Factory"); }

use lib 't/lib';
use Test::WidgetFactory;

{ # make a super-simple input field
  my ($html, $tree) = widget(input => {
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

{ # make a disabled input field
  my ($html, $tree) = widget(input => {
    name  => 'flavor',
    value => 'minty',
    disabled => 1,
  });

  my ($input) = $tree->look_down(_tag => 'input');

  isa_ok($input, 'HTML::Element');

  is(
    $input->attr('disabled'),
    'disabled',
    "disabled is a bool arg",
  );
}

{ # make a hidden input field
  my ($html, $tree) = widget(hidden => {
    id    => 'secret',
    value => '123-432-345-654',
  });

  my ($input) = $tree->look_down(_tag => 'input');

  isa_ok($input, 'HTML::Element');

  is(
    $input->attr('name'),
    'secret',
    "got correct input name",
  );

  is(
    $input->attr('value'),
    '123-432-345-654',
    "got correct form value",
  );

  is(
    $input->attr('type'),
    'hidden',
    'got a hidden input',
  );
}

{ # default classes
  my $fac = HTML::Widget::Factory->new({
    plugins => [
      'HTML::Widget::Plugin::Attrs',
      HTML::Widget::Plugin::Input->new({ default_classes => [ 'foo' ] }),
    ],
  });

  {
    my ($html, $tree) = widget($fac, input => {
      id    => 'secret',
      value => '123-432-345-654',
    });

    my ($input) = $tree->look_down(_tag => 'input');

    isa_ok($input, 'HTML::Element');

    is($input->attr('name'),  'secret',          "got correct input name");
    is($input->attr('value'), '123-432-345-654', "got correct form value");
    is($input->attr('class'), 'foo',             "got correct class");
  }

  {
    my ($html, $tree) = widget($fac, input => {
      id    => 'secret',
      value => '123-432-345-654',
      class => 'bar baz',
    });

    my ($input) = $tree->look_down(_tag => 'input');

    isa_ok($input, 'HTML::Element');

    is($input->attr('name'),  'secret',          "got correct input name");
    is($input->attr('value'), '123-432-345-654', "got correct form value");
    is($input->attr('class'), 'foo bar baz',     "got correct class");
  }
}
