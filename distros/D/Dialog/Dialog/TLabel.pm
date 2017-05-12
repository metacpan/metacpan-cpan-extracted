# $Id: TLabel.pm,v 1.1 2000/06/06 07:05:41 mike_s Exp $

package Dialog::TLabel;

use Carp;
use Dialog::Const;

require Dialog;

sub TLabel::new {
  my($self, $owner, $name, $y, $x, $s) = @_;
  $self = {
    owner   => $owner,
    name    => $name,
    tabstop => 0,
    y       => $y,
    x       => $x,
    s       => $s,
  };
  bless $self;
  return $self;
}

sub draw {
  my $self = shift;
  my($y, $x, $s) = ($self->{y}, $self->{x}, $self->{s});
  Dialog::attrset(item_attr);
  Dialog::mvprintw($y, $x, $s);
}

sub tabstop {
  ($self, $tab) = @_;
  return $self->{tabstop} unless defined $tab;
  $self->{tabstop} = $tab;
}

sub onkey {
#  my ($self, $key) = @_;
#  if($self == &Dialog::current and ($key == 32 or $key == KEY_RET)) {
#    &Dialog::endmodal($self->{res})
#  }
}

sub exec {
  my $self = shift;
  confess ref($self)." can not receive focus";
#  my $self = shift;
#  my($y, $x, $s) = ($self->{y}, $self->{x}, $self->{s});
#  $self->print(1);
#  my $ret = &Dialog::getch;
#  $self->print(0);
#  $ret;
}

sub data {
  ($self, $data) = @_;
  return $self->{s} unless defined $data;
  $self->{s} = $data;
  $self->draw;
}

sub name {
  $_[0]->{name};
}

1;

__END__
