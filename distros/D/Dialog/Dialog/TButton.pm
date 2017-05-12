# $Id: TButton.pm,v 1.1 2000/06/06 07:05:41 mike_s Exp $

package Dialog::TButton;

use Carp;
use Dialog::Const;

require Dialog;

sub TButton::new {
  my($self, $owner, $name, $y, $x, $s, $res) = @_;
  $self = {
    owner   => $owner,
    name    => $name,
    tabstop => 1,
    y       => $y,
    x       => $x,
    s       => $s,
    res     => $res,
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
  my($y, $x, $s) = ($self->{y}, $self->{x}, $self->{s});
  Dialog::draw_box($y, $x, 3, length($s)+5, dialog_attr, border_attr);
  $self->print(0);
}

sub onkey {
  my ($self, $key) = @_;
  my $dlg = $self->{owner};
  if($self == $dlg->current and ($key == 32 or $key == KEY_RET)) {
    $dlg->endmodal($self->{res})
  }
}

sub print {
  my ($self, $active) = @_;
  my($y, $x, $s) = ($self->{y}, $self->{x}, $self->{s});
  my $ss;
  ($ss = $s) =~ s/&//;
  Dialog::attrset($active ? button_label_active_attr : button_label_inactive_attr);
  Dialog::mvprintw($y+1, $x+2, " $ss ");
  my $pos = index($s, '&');
  return if $pos == -1;
  Dialog::attrset($active ? button_key_active_attr : button_key_inactive_attr);
  Dialog::mvprintw($y+1, $x+3+$pos, substr($ss, $pos, 1));
}

sub exec {
  my $self = shift;
  my($y, $x, $s) = ($self->{y}, $self->{x}, $self->{s});
  $self->print(1);
  my $ret = &Dialog::getch;
  $self->print(0);
  $ret;
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
