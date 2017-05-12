#!perl
use strict;
use warnings;

use Test::More tests => 24;

BEGIN { use_ok("HTML::Widget::Factory"); }

use lib 't/lib';
use Test::WidgetFactory;

{ # make a button with text
  my ($html, $tree) = widget(button => {
    id   => 'some_button',
    text => "This is right & proper.",
    type => 'submit',
  });

  like($html, qr/right &\S+; proper/, 'html entites escaped in content');
  
  my @buttons = $tree->look_down(_tag => 'button');

  is(@buttons, 1, "we created one button");

  my $button = $buttons[0];

  isa_ok($button, 'HTML::Element');

  is($button->attr('name'), 'some_button', "got correct button name");
  is($button->attr('type'), 'submit', "got requested buttont type");
}

{ # make a button with html (scalar)
  my ($html, $tree) = widget(button => {
    name => 'misc_button',
    html => '<img src="Foo" />',
  });

  like($html, qr/<img/, 'html entites not escaped with literal_content');

  my @buttons = $tree->look_down(_tag => 'button');

  is(@buttons, 1, "we created one button");

  my $button = $buttons[0];

  isa_ok($button, 'HTML::Element');

  is($button->attr('name'), 'misc_button', "got correct button name");
  is($button->attr('type'), 'button', "default button type: button");

  my @images = $button->look_down(_tag => 'img');
  
  is(@images, 1, "there's an image in the button");
  is($images[0]->attr('src'), 'Foo', "...with the correct src");
}

{ # make a button with html (element object)
  my $label = HTML::Element->new('img', src => 'bar');

  my ($html, $tree) = widget(button => {
    name => 'misc_button',
    html => $label,
  });

  like($html, qr/<img/, 'html entites not escaped with literal_content');

  my @buttons = $tree->look_down(_tag => 'button');

  is(@buttons, 1, "we created one button");

  my $button = $buttons[0];

  isa_ok($button, 'HTML::Element');

  is($button->attr('name'), 'misc_button', "got correct button name");
  is($button->attr('type'), 'button', "default button type: button");

  my @images = $button->look_down(_tag => 'img');
  
  is(@images, 1, "there's an image in the button") or diag $html;
  is($images[0]->attr('src'), 'bar', "...with the correct src");
}

{ # fail to make a button: bad type
  eval {
    widget(button => {
      name => 'will_totally_fail',
      text => 'Button Label',
      type => 'panic',
    });
  };

  like($@, qr/invalid button type/, "exception on bad button type");
}

{ # fail to make a button: both html and text
  eval {
    widget(button => {
      name => 'will_totally_fail',
      text => 'Button Label',
      html => '<b>Button Label</b>',
    });
  };

  like($@, qr/text and html/, "exception when passing both text and html");
}

{ # make a button with no text
  my ($html, $tree) = widget(button => {
    id   => 'simple_button',
    type => 'submit',
  });

  my ($button) = $tree->look_down(_tag => 'button');

  isa_ok($button, 'HTML::Element');

  is($button->as_text, 'Submit', "button with no text uses type");
}
