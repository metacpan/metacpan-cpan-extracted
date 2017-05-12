# IUP::Menu example
#
# Creates a dialog with a menu with two submenus

use strict;
use warnings;

use IUP ':all';

# Creates a text, sets its value and turns on text readonly mode;
my $text = IUP::Text->new( READONLY=>"YES", VALUE=>"Selecting show or hide will affect this text", SIZE=>300 );

sub action_show {
  $text->VISIBLE("YES");
  return IUP_DEFAULT;
} 

sub action_hide {
  $text->VISIBLE("NO");
  return IUP_DEFAULT;
} 

sub action_exit {
  return IUP_CLOSE
} 

sub key_cb {
  my ($self, $c) = @_;
  return action_hide if $c == K_cH; #ctrl+H
  return action_exit if $c == K_cE; #ctrl+E
  return action_show if $c == K_cS; #ctrl+S
  return IUP_DEFAULT;
}

# Creates items, sets its shortcut keys and deactivates edit item;
my $item_show = IUP::Item->new( TITLE=>"Show\tCtrl+S", ACTION=>\&action_show );
my $item_hide = IUP::Item->new( TITLE=>"Hide\tCtrl+H", ACTION=>\&action_hide );
my $item_edit = IUP::Item->new( TITLE=>"Edit", ACTIVE=>"NO" );
my $item_exit = IUP::Item->new( TITLE=>"Exit\tCtrl+E", ACTION=>\&action_exit );

# Creates two menus;
my $menu_file = IUP::Menu->new( child=>[$item_exit] );
my $menu_text = IUP::Menu->new( child=>[$item_show, $item_hide, $item_edit] );

# Creates two submenus;
my $submenu_file = IUP::Submenu->new( child=>$menu_file, TITLE=>"File" );
my $submenu_text = IUP::Submenu->new( child=>$menu_text, TITLE=>"Text" );

# Creates main menu with two submenus;
my $menu = IUP::Menu->new( child=>[$submenu_file, $submenu_text] );

# Creates dialog with a text, sets its title and associates a menu to it;
my $dlg = IUP::Dialog->new( child=>$text, TITLE=>"IupMenu Example", MENU=>$menu, K_ANY=>\&key_cb );

# Shows dialog in the center of the screen;
$dlg->ShowXY( IUP_CENTER, IUP_CENTER );

IUP->MainLoop;
