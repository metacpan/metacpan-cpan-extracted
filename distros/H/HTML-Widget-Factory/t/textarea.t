#!perl
use strict;
use warnings;

use Test::More tests => 15;

BEGIN { use_ok("HTML::Widget::Factory"); }

use lib 't/lib';
use Test::WidgetFactory;

{ # make a textarea widget
  my ($html, $tree) = widget(textarea => {
    name  => 'big_ol',
    value => 'This is some big old block of text.  Pretend!',
  });

  my ($textarea) = $tree->look_down(_tag => 'textarea');

  isa_ok($textarea, 'HTML::Element');

  is(
    $textarea->attr('name'),
    'big_ol',
    "got correct textarea name",
  );

  is(
    $textarea->as_text,
    'This is some big old block of text.  Pretend!',
    "the textarea has the right content"
  );
}

{ # make a textarea widget
  my $ok = 1;
  local $SIG{__WARN__} = sub { $ok = 0; };
  my ($html, $tree) = widget(textarea => {});
  ok($ok, "no warnings from valueless textarea");
}

{ # make a textarea widget
  my ($html, $tree) = widget(textarea => {
    id    => 'textarea123',
    value => 'This is some big old block of text.  Pretend!',
  });

  my ($textarea) = $tree->look_down(_tag => 'textarea');

  isa_ok($textarea, 'HTML::Element');

  is(
    $textarea->attr('id'),
    'textarea123',
    "got correct textarea id",
  );

  is(
    $textarea->attr('name'),
    'textarea123',
    "got correct textarea name, from id",
  );

  is(
    $textarea->as_text,
    'This is some big old block of text.  Pretend!',
    "the textarea has the right content"
  );
}

{ # default classes
  my $fac = HTML::Widget::Factory->new({
    plugins => [
      'HTML::Widget::Plugin::Attrs',
      HTML::Widget::Plugin::Textarea->new({ default_classes => [ 'foo' ] }),
    ],
  });

  {
    my ($html, $tree) = widget($fac, textarea => {
      id    => 'textarea123',
      value => 'This is some big old block of text.  Pretend!',
    });

    my ($textarea) = $tree->look_down(_tag => 'textarea');

    isa_ok($textarea, 'HTML::Element');

    is($textarea->attr('id'), 'textarea123', "got correct textarea id");
    is($textarea->attr('class'), 'foo',      "got correct textarea class");
  }

  {
    my ($html, $tree) = widget($fac, textarea => {
      id    => 'textarea123',
      value => 'This is some big old block of text.  Pretend!',
      class => 'bar baz',
    });

    my ($textarea) = $tree->look_down(_tag => 'textarea');

    isa_ok($textarea, 'HTML::Element');

    is($textarea->attr('id'), 'textarea123',    "got correct textarea id");
    is($textarea->attr('class'), 'foo bar baz', "got correct textarea class");
  }
}
