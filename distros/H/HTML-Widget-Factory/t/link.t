#!perl
use strict;
use warnings;

use Test::More tests => 19;

BEGIN { use_ok("HTML::Widget::Factory"); }

use lib 't/lib';
use Test::WidgetFactory;

{ # make a super-simple link
  my ($html, $tree) = widget(link => {
    href => 'http://www.codesimply.com/',
  });

  my ($link) = $tree->look_down(_tag => 'a');

  isa_ok($link, 'HTML::Element');

  is(
    $link->attr('href'),
    'http://www.codesimply.com/',
    "got correct hyper-ref",
  );

  is(
    $link->as_text,
    'http://www.codesimply.com/',
    "with no text, href has been used instead",
  );
}

{ # make a simple link
  my ($html, $tree) = widget(link => {
    href => 'http://rjbs.manxome.org/',
    text => "ricardo's home page",
    name => 'named-anchor',
  });

  my ($link) = $tree->look_down(_tag => 'a');

  isa_ok($link, 'HTML::Element');

  is(
    $link->attr('href'),
    'http://rjbs.manxome.org/',
    "got correct hyper-ref",
  );

  is(
    $link->as_text,
    "ricardo's home page",
    "got correct text",
  );
}

{ # make a link with html inside (text)
  my ($html, $tree) = widget(link => {
    href => 'http://rjbs.manxome.org/',
    html => "<img src='/jpg.jpg'>",
    id   => 'identified-anchor',
  });
  
  my ($link) = $tree->look_down(_tag => 'a');

  isa_ok($link, 'HTML::Element');

  is(
    $link->attr('href'),
    'http://rjbs.manxome.org/',
    "got correct hyper-ref",
  );

  like(
    $link->as_text,
    qr/\A\s*\z/,
    "no visible text inside A element",
  );

  my ($img) = $link->look_down(_tag => 'img');

  ok($img, "there is an IMG inside this A element");

  isa_ok($img, 'HTML::Element');
}

{ # make a link with html inside (element)
  my $image = HTML::Element->new('img', src => '/png.png');

  my ($html, $tree) = widget(link => {
    href => 'http://rjbs.manxome.org/',
    html => $image,
    id   => 'identified-anchor',
  });
  
  my ($link) = $tree->look_down(_tag => 'a');

  isa_ok($link, 'HTML::Element');

  is(
    $link->attr('href'),
    'http://rjbs.manxome.org/',
    "got correct hyper-ref",
  );

  like(
    $link->as_text,
    qr/\A\s*\z/,
    "no visible text inside A element",
  );

  my ($img) = $link->look_down(_tag => 'img');

  ok($img, "there is an IMG inside this A element");

  isa_ok($img, 'HTML::Element');
}

{ # fail to make a super-simple link: no href
  eval {
    widget(link => { name => 'wont-work' });
  };

  like($@, qr/without an href/, "exception: can't make a link with no href");
}

{ # fail to make a link: text and html
  eval {
    widget(link => {
      href => 'http://rjbs.manxome.org/',
      text => "ricardo's home page",
      html => "<img src='/rjbs.tiff'>",
    });
  };

  like($@, qr/text and html/, "exception: can't provide both text and html");
}
