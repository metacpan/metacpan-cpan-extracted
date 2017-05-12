#!perl
use strict;
use warnings;

use Test::More tests => 9;

BEGIN { use_ok("HTML::Widget::Factory"); }

use lib 't/lib';
use Test::WidgetFactory;

{ # make a super-simple image
  my ($html, $tree) = widget(image => {
    href => 'http://www.example.com/foo.jpg',
    alt  => "photo of a foo",
  });

  my ($image) = $tree->look_down(_tag => 'img');

  isa_ok($image, 'HTML::Element');

  is(
    $image->attr('src'),
    'http://www.example.com/foo.jpg',
    "got correct image source",
  );

  is($image->as_text, q{}, "got correct text version (nothing)");

  is($image->attr('alt'), 'photo of a foo', "and got non-empty alt text");
}

{ # make another super-simple image
  my ($html, $tree) = widget(image => {
    src  => 'http://www.example.com/bar.jpg',
    alt  => "photo of a bar",
  });

  my ($image) = $tree->look_down(_tag => 'img');

  isa_ok($image, 'HTML::Element');

  is(
    $image->attr('src'),
    'http://www.example.com/bar.jpg',
    "got correct image source",
  );
}

{ # fail to make an image: src and href
  eval {
    widget(image => {
      href => 'http://www.example.com/foo.jpg',
      src  => 'http://www.example.com/bar.jpg',
      alt  => "photo of a foobar",
    });
  };

  like($@, qr/href and src/, "exception if both src and href given");
}

{ # fail to make an image: no src or href
  eval {
    widget(image => {
      alt  => "photo of a foobar",
    });
  };

  like($@, qr/without a src/, "exception; can't make an image without a src");
}
