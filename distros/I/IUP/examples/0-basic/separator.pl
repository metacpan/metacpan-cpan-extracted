# IUP::Separator example
#
# Creates a dialog with a menu and some items
# A IupSeparator was used to separate the menu items

use strict;
use warnings;

use IUP ':all';

# Creates a text, sets its value and turns on text readonly mode
my $text = IUP::Text->new( VALUE=>"This text is here only to compose", EXPAND=>"YES" );

# Creates six items;
my $item_new = IUP::Item->new( TITLE=>"New" );
my $item_open = IUP::Item->new( TITLE=>"Open" );
my $item_close = IUP::Item->new( TITLE=>"Close" );
my $item_pagesetup = IUP::Item->new( TITLE=>"Page Setup" );
my $item_print = IUP::Item->new( TITLE=>"Print" );
my $item_exit = IUP::Item->new( TITLE=>"Exit", ACTION=>sub { return IUP_CLOSE } );

# Creates file menus;
my $menu_file = IUP::Menu->new( child=>[$item_new, $item_open, $item_close, IUP::Separator->new(), $item_pagesetup, $item_print, IUP::Separator->new(), $item_exit] );

# Creates file submenus;
my $submenu_file = IUP::Submenu->new( child=>$menu_file, TITLE=>"File");

# Creates main menu with file submenu;
my $menu = IUP::Menu->new( child=>$submenu_file );

# Creates dialog with a text, sets its title and associates a menu to it;
my $dlg = IUP::Dialog->new( child=>$text,
                            TITLE=>"IupSeparator Example",
                            MENU=>$menu,
                            SIZE=>"QUARTERxEIGHTH" );

# Shows dialog in the center of the screen;
$dlg->ShowXY(IUP_CENTER,IUP_CENTER);

IUP->MainLoop;
