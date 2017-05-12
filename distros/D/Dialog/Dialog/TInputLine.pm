# $Id: TInputLine.pm,v 1.1 2000/06/06 07:05:41 mike_s Exp $

package Dialog::TInputLine;

use Carp;
use Dialog::Const;

require Dialog;

sub TInputLine::new {
  my($self, $owner, $name, $y, $x, $w, $s) = @_;
  $self = {
    owner   => $owner,
    name    => $name,
    tabstop => 1,
    y       => $y,
    x       => $x,
    w       => $w,
    s       => $s,
  };
  bless $self;
  $self->draw();
  return $self;
}

sub tabstop {
  ($self, $tab) = @_;
  return $self->{tabstop} unless defined $tab;
  $self->{tabstop} = $tab;
}

sub draw {
  my $self = shift;
  $self->drawbox;
  $self->drawline;
}

sub onkey {
  my $self = shift;
}

sub drawbox {
  my $self = shift;
  my $attr1 = menubox_border_attr;
  my $attr2 = item_attr;
  my($y, $x, $w) = ($self->{y}, $self->{x}, $self->{w});
  Dialog::draw_box($y, $x, 3, $w, $attr1, $attr2);
}

sub drawline {
  my $self = shift;
  my($y, $x, $w) = ($self->{y}, $self->{x}, $self->{w});
  Dialog::attrset(dialog_attr);
  my $fmt = sprintf("%%-%u.%us", $w-2, $w-2);
  Dialog::mvprintw($y+1, $x+1, sprintf($fmt, $self->{s}));
}

sub exec {
  my $self = shift;
  my($y, $x, $w) = ($self->{y}, $self->{x}, $self->{w});
  my $ret = Dialog::line_edit($y+1, $x+1, $w-2, $self->{s});
  $self->drawline;
  $ret;
}

sub data {
  ($self, $data) = @_;
  return $self->{s} unless defined $data;
  $self->{s} = $data;
  $self->drawline;
}

sub name {
  $_[0]->{name};
}

1;

__END__
