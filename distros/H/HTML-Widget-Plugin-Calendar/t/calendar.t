#!perl
use strict;
use warnings;

use Test::More 'no_plan';

use HTML::Widget::Factory;
use HTML::Widget::Plugin::Calendar;

my $factory = HTML::Widget::Factory->new({
  extra_plugins => [ HTML::Widget::Plugin::Calendar->new ],
});

can_ok($factory, 'calendar');

HTML::Widget::Plugin::Calendar->calendar_baseurl('/');

my $html = $factory->calendar({
  id     => 'birthday',
  format => '%Y-%d-%m',
});

