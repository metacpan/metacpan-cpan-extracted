# $Id: Const.pm,v 1.1 2000/06/06 07:05:41 mike_s Exp $

package Dialog::Const;

use Carp;
use vars qw(@ISA @EXPORT $AUTOLOAD);

require Exporter;
require AutoLoader;

@ISA = qw(Exporter);
@EXPORT = qw(
  KEY_TAB
  KEY_RET
  KEY_ESC
  KEY_DOWN
  KEY_UP
  KEY_BTAB
  KEY_LEFT
  KEY_RIGHT

  ATTRIBUTE_COUNT
  FALSE
  MAX_LEN
  TRUE
  VERSION
  border_attr
  button_active_attr
  button_inactive_attr
  button_key_active_attr
  button_key_inactive_attr
  button_label_active_attr
  button_label_inactive_attr
  check_attr
  check_selected_attr
  darrow_attr
  dialog_attr
  inputbox_attr
  inputbox_border_attr
  item_attr
  item_selected_attr
  menubox_attr
  menubox_border_attr
  position_indicator_attr
  screen_attr
  searchbox_attr
  searchbox_border_attr
  searchbox_title_attr
  shadow_attr
  tag_attr
  tag_key_attr
  tag_key_selected_attr
  tag_selected_attr
  title_attr
  uarrow_attr
  mrOk
  mrCancel
);

%auto = (
  KEY_TAB   => 9,
  KEY_RET   => 10,
  KEY_ESC   => 27,
  KEY_DOWN  => 258,
  KEY_UP    => 259,
  KEY_BTAB  => 353,
  KEY_LEFT  => 260,
  KEY_RIGHT => 261,

  ATTRIBUTE_COUNT            => 0x1D,
  FALSE                      => 0x0,
  MAX_LEN                    => 0x800,
  TRUE                       => 0x1,
  VERSION                    => 0x16AC,
  border_attr                => 0x200500,
  button_active_attr         => 0x200600,
  button_inactive_attr       => 0x700,
  button_key_active_attr     => 0x200800,
  button_key_inactive_attr   => 0x900,
  button_label_active_attr   => 0x200A00,
  button_label_inactive_attr => 0x200B00,
  check_attr                 => 0x1A00,
  check_selected_attr        => 0x201B00,
  darrow_attr                => 0x201D00,
  dialog_attr                => 0x300,
  inputbox_attr              => 0xC00,
  inputbox_border_attr       => 0xD00,
  item_attr                  => 0x1400,
  item_selected_attr         => 0x201500,
  menubox_attr               => 0x1200,
  menubox_border_attr        => 0x201300,
  position_indicator_attr    => 0x201100,
  screen_attr                => 0x200100,
  searchbox_attr             => 0xE00,
  searchbox_border_attr      => 0x201000,
  searchbox_title_attr       => 0x200F00,
  shadow_attr                => 0x200200,
  tag_attr                   => 0x201600,
  tag_key_attr               => 0x201800,
  tag_key_selected_attr      => 0x201900,
  tag_selected_attr          => 0x201700,
  title_attr                 => 0x200400,
  uarrow_attr                => 0x201C00,
  mrOk                       => 1,
  mrCancel                   => 2
);

sub AUTOLOAD {
  my $const;
  ($const = $AUTOLOAD) =~ s/.*:://;
  my $ret = $auto{$const};
  confess "Not defined $const" unless defined $ret;
  $ret;
}

1;

__END__
