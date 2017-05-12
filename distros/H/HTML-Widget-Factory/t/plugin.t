#!perl
use strict;
use warnings;

use Test::More tests => 14;

sub provides_ok {
  my ($fac, $wid) = @_;
  ok(
    $fac->provides_widget($wid),
    "factory provides widget $wid",
  );
}

require_ok("HTML::Widget::Factory");

# generic factory
my $widget_factory = HTML::Widget::Factory->new;

isa_ok($widget_factory, 'HTML::Widget::Factory');

provides_ok($widget_factory, 'input');
provides_ok($widget_factory, 'hidden');
provides_ok($widget_factory, 'password');

# specialized factory
my $input_factory = HTML::Widget::Factory->new({
  plugins => [ qw(HTML::Widget::Plugin::Input) ],
});

isa_ok($input_factory,  'HTML::Widget::Factory');

provides_ok($input_factory, 'input');
provides_ok($input_factory, 'hidden');

ok(
  ! $input_factory->provides_widget('password'),
  "input-only factory can't do password",
);

# derived factory
my $derived_factory = $input_factory->new({
  plugins => [ qw(HTML::Widget::Plugin::Password) ],
});

isa_ok($derived_factory, 'HTML::Widget::Factory');
isa_ok($derived_factory, ref $input_factory);

provides_ok($derived_factory, 'input');
provides_ok($derived_factory, 'hidden');

ok(
  $derived_factory->provides_widget('password'),
  "derived-frominput-only factory *can* do password",
);
