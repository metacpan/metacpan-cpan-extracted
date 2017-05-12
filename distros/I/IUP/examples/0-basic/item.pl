# IUP::Item Example

use strict;
use warnings;

use IUP ':all';

# create the main application windows (dialog)

my $text = IUP::Text->new( VALUE=>"This is an initial text", MULTILINE=>"YES", VISIBLECOLUMNS=>15, VISIBLELINES=>15 );

my $item_save     = IUP::Item->new( TITLE=>"Save\tCtrl+S", ACTIVE=>"NO" );
my $item_autosave = IUP::Item->new( TITLE=>"Auto Save\tCtrl+A", VALUE=>"ON" );
my $item_exit     = IUP::Item->new( TITLE=>"Exit\tAlt+X" );

my $menu_file = IUP::Menu->new( child=>[$item_save, $item_autosave, $item_exit] );

my $submenu_file = IUP::Submenu->new( TITLE=>"File", child=>$menu_file );

my $menu = IUP::Menu->new( child=>$submenu_file );

my $dlg = IUP::Dialog->new( child=>$text, TITLE=>"IUP::Item", MENU=>$menu );

# setup callbacks
$item_exit->ACTION(\&hide_cb);
$item_autosave->ACTION(\&autosave_cb);
$dlg->K_ANY(\&key_cb);

sub hide_cb {
  # not so common exit handler
  $dlg->Hide();
  return IUP_DEFAULT;
}

sub save_cb {
  IUP->Message("Save not implemented");
  return IUP_DEFAULT;
}

sub autosave_cb {
  if ( $item_autosave->VALUE eq "ON" ) {
    IUP->Message("Auto Save", "OFF");
    $item_autosave->VALUE("OFF");
  }
  else {
    IUP->Message("Auto Save", "ON");
    $item_autosave->VALUE("ON");
  }
  return IUP_DEFAULT;
}

sub key_cb {
  my ($self, $c) = @_;
  return save_cb     if $c == K_cS; #ctrl+S
  return autosave_cb if $c == K_cA; #ctrl+A
  return hide_cb     if $c == K_mX; #alt+X
}

# start the main loop
$dlg->ShowXY(IUP_CENTER, IUP_CENTER);
IUP->MainLoop;
