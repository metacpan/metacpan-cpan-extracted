#!perl
use strict;
use warnings;

use Test::More;
use HTML::Widget::Factory;

my @expected = qw(
  HTML::Widget::Plugin::Attrs
  HTML::Widget::Plugin::Button
  HTML::Widget::Plugin::Checkbox
  HTML::Widget::Plugin::Image
  HTML::Widget::Plugin::Input
  HTML::Widget::Plugin::Link
  HTML::Widget::Plugin::Multiselect
  HTML::Widget::Plugin::Password
  HTML::Widget::Plugin::Radio
  HTML::Widget::Plugin::Select
  HTML::Widget::Plugin::Submit
  HTML::Widget::Plugin::Textarea
);

plan tests => 1 + @expected;

my $factory = HTML::Widget::Factory->new;

isa_ok($factory, 'HTML::Widget::Factory');

my @plugins = $factory->plugins;
for my $plugin (@expected) {
  ok(
    (grep { $_->isa($plugin) } @plugins),
    "core plugin $plugin found",
  );
}
