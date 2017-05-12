# $Id: Dialog.pm,v 1.1 2000/06/06 07:05:36 mike_s Exp $

package Dialog;

use strict;
use Carp qw(croak);
use vars qw($VERSION @ISA @EXPORT $AUTOLOAD);
use Dialog::TInputLine;
use Dialog::TButton;
use Dialog::TLabel;
use Dialog::Const;

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader Dialog::Const);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	ATTRIBUTE_COUNT
	FALSE
	HAVE_NCURSES
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
);
$VERSION = '0.03';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
		Carp::confess "Your vendor has not defined Dialog macro $constname";
	}
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

bootstrap Dialog $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

no strict "vars";
no strict "subs";

sub new {
  %objlist = {};
  @objlist = ();
  $current = 0;

  ($self, $title, $y, $x, $height, $width) = @_;
  $self = bless {};
  Init() unless $instances++;
  Clear();
  draw();
  $self;
}

sub DESTROY {
  Exit() unless --$instances;
}

sub draw {
  draw_box($y, $x, $height, $width, dialog_attr, border_attr);
  draw_shadow($y, $x, $height, $width);
  return unless $title;
  attrset(title_attr);
  mvprintw($y, $x+($width-length($title)-1)/2, " $title ");
}

sub run {
  $self = shift;

  my $key;
  $modalresult = 0;
  while(! $modalresult) {
    Update();
    $key = $objlist{$objlist[$current]}->exec();
    Update();
    if($key == KEY_TAB or $key == KEY_DOWN or $key == KEY_RIGHT) { tab() }
    elsif($key == KEY_UP or $key == KEY_BTAB or $key == KEY_LEFT) { s_tab() }
    elsif($key == KEY_ESC) { $modalresult = mrCancel }
    else { dispatch($key) }
  }
  $modalresult;
}

sub s_tab {
  my $old = $current;
  while() {
    $current = $current ? $current-1 : $#objlist;
    return if $current == $old or $objlist{$objlist[$current]}->tabstop;
  }
}

sub tab {
  my $old = $current;
  while() {
    $current = $current < $#objlist ? $current+1 : 0;
    return if $current == $old or $objlist{$objlist[$current]}->tabstop;
  }
}

sub dispatch {
  $objlist{$objlist[$current]}->onkey(shift);
}

sub current {
  my($self, $name) = @_;
  return $objlist{$objlist[$current]} unless defined $name;
  $name = $name->name if ref($name);
  Carp::carp "No such object: $name" unless defined $objlist{$name};
  for($current = 0; $current <= $#objlist; $current++) {
    last if $objlist[$current] eq $name;
  }
  redraw();
}

sub endmodal {
  my($self, $mr) = @_;
  return $modalresult unless defined $mr;
  $modalresult = $mr;
}

sub object {
  my($self, $name) = @_;
  $objlist{$name};
}

sub redraw {
  draw();
  foreach(@objlist) { $objlist{$_}->draw };
  refresh();
}

sub inputline {
  my($self, $_name, $_y, $_x, $_w, $_s) = @_;
  Carp::carp "Inputline \"$_name\" already defined" if $objlist{$_name};
  $objlist{$_name} = TInputLine->new($self, $_name, $_y+$y, $_x+$x, $_w, $_s);
  push @objlist, $_name;
  $objlist{$_name};
}

sub button {
  my($self, $_name, $_y, $_x, $_s, $_res) = @_;
  Carp::carp "Inputline \"$_name\" already defined" if $objlist{$_name};
  $objlist{$_name} = TButton->new($self, $_name, $_y+$y, $_x+$x, $_s, $_res);
  push @objlist, $_name;
  $objlist{$_name};
}

sub label {
  my($self, $_name, $_y, $_x, $_s) = @_;
  Carp::carp "Inputline \"$_name\" already defined" if $objlist{$_name};
  $objlist{$_name} = TLabel->new($self, $_name, $_y+$y, $_x+$x, $_s);
  push @objlist, $_name;
  $objlist{$_name};
}

1;
__END__
