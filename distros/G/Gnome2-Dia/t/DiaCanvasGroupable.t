#!/usr/bin/perl -w
use strict;
use Gnome2::Dia;

use Test::More tests => 41;

# $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gnome2-Dia/t/DiaCanvasGroupable.t,v 1.2 2004/09/26 12:05:57 kaffeetisch Exp $

###############################################################################

# my $group = Gnome2::Dia::CanvasItem -> create("Gnome2::Dia::CanvasGroup");
my $group = MyTestBox -> new();
isa_ok($group, "Gnome2::Dia::CanvasGroupable");

my $line = Gnome2::Dia::CanvasItem -> create("Gnome2::Dia::CanvasLine");
my $text = Gnome2::Dia::CanvasItem -> create("Gnome2::Dia::CanvasText");

$group -> add($line);
$group -> remove($line);

$group -> add($line);
$group -> add($text);

my $iter = $group -> get_iter();
isa_ok($iter, "Gnome2::Dia::CanvasIter");

is($group -> value($iter), $line);
$group -> next($iter);
is($group -> value($iter), $text);

is($group -> length(), 2);
is($group -> pos($line), 0);

###############################################################################

package MyTestBox;

use strict;
use warnings;

use Glib qw(TRUE FALSE);
use Gnome2::Dia;

use Test::More;

use Glib::Object::Subclass
  Gnome2::Dia::CanvasBox::,
  interfaces => [ Gnome2::Dia::CanvasGroupable:: ];

sub INIT_INSTANCE {
  my ($self) = @_;

  $self -> { _children } = [];
}

sub ADD {
  my ($self, $item) = @_;

  isa_ok($self, "MyTestBox");
  isa_ok($item, "Gnome2::Dia::CanvasItem");

  $item -> set_child_of($self);
  push(@{$self -> { _children }}, $item);
}

sub REMOVE {
  my ($self, $item) = @_;

  isa_ok($self, "MyTestBox");
  isa_ok($item, "Gnome2::Dia::CanvasItem");

  my @tmp = ();

  foreach (@{$self -> { _children }}) {
    if ($_ != $item) {
      push(@tmp, $_);
    }
    else {
      $item -> set_child_of(undef);
    }
  }

  $self -> { _children } = \@tmp;
}

sub GET_ITER {
  my ($self) = @_;

  isa_ok($self, "MyTestBox");

  $self -> { _stamp } = int(rand(23));

  return [ $self -> { _stamp }, 0, "schmuh", "bla" ];
}

sub NEXT {
  my ($self, $iter) = @_;

  isa_ok($self, "MyTestBox");
  isa_ok($iter, "ARRAY");

  unless (defined $iter) {
    return undef;
  }

  my ($stamp, $index, $schmuh, $bla) = @$iter;

  is($schmuh, "schmuh");
  is($bla, "bla");

  unless ($stamp == $self -> { _stamp } &&
          $index < $#{$self -> { _children }}) {
    return undef;
  }

  return [ $stamp, ++$index, $schmuh, $bla ];
}

sub VALUE {
  my ($self, $iter) = @_;

  isa_ok($self, "MyTestBox");
  isa_ok($iter, "ARRAY");

  unless (defined $iter) {
    return undef;
  }

  my ($stamp, $index, $schmuh, $bla) = @$iter;

  is($schmuh, "schmuh");
  is($bla, "bla");

  unless ($stamp == $self -> { _stamp } &&
          $index <= $#{$self -> { _children }}) {
    return undef;
  }

  return $self -> { _children } -> [$index];
}
