#!perl
use strict;
use warnings;

use Test::More tests => 2;

BEGIN { use_ok("HTML::Widget::Factory"); }

use lib 't/lib';
use Test::WidgetFactory;

{ # make an attr string
  my ($html, $tree) = widget(attrs => {
    -bool => [ qw(yn ny) ],
    id   => 'some_button',
    text => "This is right & proper.",
    type => 'submit',
    name => q(Michael "Five-Toes" O'Gambini),
    yn   => 1,
    ny   => 0,
    null => undef,
  });

  like(
    $html,
    qr/
      id="some_button"
      \s+
      name="Michael\s&quot;Five-Toes&quot;\sO&[^;]+;Gambini"
      \s+
      text="This\sis\sright\s&amp;\sproper."
      \s+
      type="submit"
      \s+
      yn="yn"
    /x,
    "got what we expected back",
  );
}
