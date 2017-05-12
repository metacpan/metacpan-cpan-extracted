# IUP::Submenu example
#
# Creates a dialog with a menu with three submenus. One of the submenus
# has a submenu, which has another submenu.

use strict;
use warnings;

use IUP ':all';

# Creates a text, sets its value and turns on text readonly mode
my $text = IUP::Text->new( VALUE=>"This text is here only to compose", EXPAND=>"YES" );

# Creates items of menu file
my $item_new   = IUP::Item->new( TITLE=>"New" );
my $item_open  = IUP::Item->new( TITLE=>"Open" );
my $item_close = IUP::Item->new( TITLE=>"Close" );
my $item_exit  = IUP::Item->new( TITLE=>"Exit" );

# Creates items of menu edit
my $item_copy  = IUP::Item->new( TITLE=>"Copy" );
my $item_paste = IUP::Item->new( TITLE=>"Paste" );

# Creates items for menu triangle
my $item_equilateral = IUP::Item->new( TITLE=>"Equilateral" );
my $item_isoceles    = IUP::Item->new( TITLE=>"Isoceles" );
my $item_scalenus    = IUP::Item->new( TITLE=>"Scalenus" );

# Creates menu triangle
my $menu_triangle = IUP::Menu->new( child=>[$item_equilateral, $item_isoceles, $item_scalenus] );

# Creates submenu triangle
my $submenu_triangle = IUP::Submenu->new( child=>$menu_triangle, TITLE=>"Triangle" );

# Creates items of menu create
my $item_line   = IUP::Item->new( TITLE=>"Line" );
my $item_circle = IUP::Item->new( TITLE=>"Circle" );

# Creates menu create
my $menu_create = IUP::Menu->new( child=>[$item_line, $item_circle, $submenu_triangle] );

# Creates submenu create
my $submenu_create = IUP::Submenu->new( child=>$menu_create, TITLE=>"Create" );

# Creates items of menu help
my $item_help = IUP::Item->new( TITLE=>"Help" );

# Creates menus of the main menu
my $menu_file = IUP::Menu->new( child=>[$item_new, $item_open, $item_close, IUP::Separator->new(), $item_exit] );
my $menu_edit = IUP::Menu->new( child=>[$item_copy, $item_paste, IUP::Separator->new(), $submenu_create] );
my $menu_help = IUP::Menu->new( child=>[$item_help] );

# Creates submenus of the main menu
my $submenu_file = IUP::Submenu->new( child=>$menu_file, TITLE=>"File" );
my $submenu_edit = IUP::Submenu->new( child=>$menu_edit, TITLE=>"Edit" );
my $submenu_help = IUP::Submenu->new( child=>$menu_help, TITLE=>"Help" );

# Creates main menu with file submenu
my $menu = IUP::Menu->new( child=>[$submenu_file, $submenu_edit, $submenu_help] );

# Creates dialog with a text, sets its title and associates a menu to it
my $dlg = IUP::Dialog->new( child=>$text,
                            TITLE=>"IUP::Submenu Example",
                            MENU=>$menu,
                            SIZE=>"QUARTERxEIGHTH" );

# Shows dialog in the center of the screen
$dlg->ShowXY (IUP_CENTER,IUP_CENTER);

$item_help->ACTION( sub {
  IUP->Message ("Warning", "Only Help and Exit items performs an operation");
  return IUP_DEFAULT;
} );

$item_exit->ACTION( sub {
  return IUP_CLOSE;  
} );

IUP->MainLoop;
