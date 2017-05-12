#!perl
use strict;
use warnings;

use Test::More tests => 4;

BEGIN { use_ok("HTML::Widget::Factory"); }

use lib 't/lib';
use Test::WidgetFactory;

{ # make a super-simple submit input
  my ($html, $tree) = widget('submit');
  
  my ($input) = $tree->look_down(_tag => 'input');

  isa_ok($input, 'HTML::Element');
}

{ # make a super-simple input field
  my ($html, $tree) = widget(submit => { value => 'Click Me!' });
  
  my ($input) = $tree->look_down(_tag => 'input');

  isa_ok($input, 'HTML::Element');

  is(
    $input->attr('value'),
    'Click Me!',
    "the label (value) is passed along"
  );
}
