#!perl -T
use strict;
use warnings;

package Test::WidgetFactory;
use base qw(Exporter);

use HTML::TreeBuilder;
use HTML::Widget::Factory;
use HTML::Widget::Plugin::Struct;

our @EXPORT = qw(widget);

my $FACTORY;
sub factory {
  return $FACTORY ||= HTML::Widget::Factory->new({
    extra_plugins => [ "HTML::Widget::Plugin::Struct" ],
  });
}

sub widget {
  my $factory = eval { $_[0]->isa('HTML::Widget::Factory') } ? shift : factory;
  my $widget  = shift;
  my $arg     = shift;

  my $html = $factory->$widget($arg);

  my $tree = HTML::TreeBuilder->new_from_content($html);

  return ($html, $tree);
}

1;
