#!perl -T
use strict;
use warnings;

use Test::More tests => 3;

BEGIN { use_ok("HTML::Widget::Factory"); }
BEGIN { use_ok("HTML::Widget::Plugin::Struct"); }

use lib 't/lib';
use Test::WidgetFactory;

{ # make a recursive input field
  my $array = [ 0, 1, 2 ];
  push @$array, $array;
  eval { widget(struct => { name  => 'deadly', value => $array }); };
  like($@, qr/loop/, "you can't dump a loopy struct!");
}
