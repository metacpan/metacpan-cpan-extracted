#!/home/markt/bin/perl -w

use strict;
no strict 'subs';
use lib qw(../..);
use Java;

# Set up some convenience stuff
my $awt = "java.awt";
my $swing = "javax.swing";

# Create connection to JavaServer
my $java = new Java();

# Create the window and a Panel
my $frame = $java->create_object("$swing.JFrame","Menu Demo");
my $panel = $java->create_object("$swing.JPanel");

# Add the panel to the 'Center' of the Content Pane
$frame->getContentPane->add($panel,"Center");

#// Menus

#// File Menu
# Set up the File Menu
my $file_menu = $java->create_object("$swing.JMenu","File");
$file_menu->setMnemonic("F:char");

# Call 'menu_item' convenience function to add this menu item
# It takes a Label, event handler, Action string, and short-cut

# New
$file_menu->add(&menu_item("New",\&menu_handler,"new",'N',$java->get_field("java.awt.event.KeyEvent","VK_N")));
# Open
$file_menu->add(&menu_item("Open...",\&menu_handler,"open",'O',$java->get_field("java.awt.event.KeyEvent","VK_O")));
# Save
$file_menu->add(&menu_item("Save",\&menu_handler,"save",'S',$java->get_field("java.awt.event.KeyEvent","VK_S")));
# Save As
$file_menu->add(&menu_item("Save As...",\&menu_handler,"savea",'A',$java->get_field("java.awt.event.KeyEvent","VK_A")));

# Edit Menu
my $edit_menu = $java->create_object("$swing.JMenu","Edit");
$edit_menu->setMnemonic("E:char");

# Cut
$edit_menu->add(&menu_item("Cut",\&menu_handler,"cut",0,$java->get_field("java.awt.event.KeyEvent","VK_X")));
# Copy
$edit_menu->add(&menu_item("Copy",\&menu_handler,"copy",'C',$java->get_field("java.awt.event.KeyEvent","VK_C")));
# Paste
$edit_menu->add(&menu_item("Paste",\&menu_handler,"paste",0,$java->get_field("java.awt.event.KeyEvent","VK_V")));

# A dummy menu to let user know they can click in window to get popup menu
my $t_menu = $java->create_object("$swing.JMenu","Click in window for popup menu!");

# Menu bar
my $menu_bar = $java->create_object("$swing.JMenuBar");
$menu_bar->add($file_menu);
$menu_bar->add($edit_menu);
$menu_bar->add($t_menu);

# Add menu bar to our frame
$frame->setJMenuBar($menu_bar);

# Going for popup menu

# Create Popup menu
my $popup = $java->create_object("$swing.JPopupMenu");

# Add some stuff to it...
$popup->add(&menu_item("Open...",\&menu_handler,"open",0,0));
$popup->addSeparator;

# Like a sub-menu...
my $colors = $java->create_object("$swing.JMenu","Colors");
$popup->add($colors);

# Set up some radio items in the sub-menu of the popup menu
my $color_group = $java->create_object("$swing.ButtonGroup");
$colors->add(&radio_item("Red",\&menu_handler,"color(red)",$color_group));
$colors->add(&radio_item("Green",\&menu_handler,"color(green)",$color_group));
$colors->add(&radio_item("Blue",\&menu_handler,"color(blue)",$color_group));

#// Now have it show up when user clicks in the window...
# So when I get an event that I want I'll show 'em the popup window
$java->do_event($panel,"addMouseListener",\&mouse_handler);

# Get the main frame rockin'!
$frame->setSize(450,300);
$frame->setVisible("true:b");
$frame->show;

# This is my exciting event loop!
my $cont = 1;
while($cont)
{
	$java->go;
}

#// Convenience function to create a JMenuItem
sub menu_item
{
	my($label, $callback, $command, $mnemonic, $accelerator_key) = @_;

	# Create a menu item
	my $jmenu_item = $java->create_object("$swing.JMenuItem",$label);

	# Add the event listener
	$java->do_event($jmenu_item, "addActionListener", $callback);

	# Set the action command
	$jmenu_item->setActionCommand($command);
	if ($mnemonic)
	{
		# Set mnemonic
		$jmenu_item->setMnemonic("$mnemonic:char");
	}
	if ($accelerator_key)
	{
		# Get control mask 
		my $mask = $java->get_field("java.awt.Event","CTRL_MASK");

		# Call static function 'getKeyStroke' on
		#	javax.swing.KeyStroke class with the actual
		#	value of the accelerator key (an integer)
		#	and the control mask.
		my $key_stroke = $java->javax_swing_KeyStroke("getKeyStroke",$accelerator_key->get_value,$mask);

		# And set it
		$jmenu_item->setAccelerator($key_stroke);
	}

	return $jmenu_item;
}

# convenience radio item function
sub radio_item
{
	my($label, $callback, $command, $mutExGroup) = @_;

	# Make the menu item
	my $jmenu_item = $java->create_object("$swing.JMenuItem",$label);

	# Add event handler
	$java->do_event($jmenu_item, "addActionListener", $callback);

	# Set action command
	$jmenu_item->setActionCommand($command);

	# add to group
	$mutExGroup->add($jmenu_item);

	return $jmenu_item;
}
	

###
# Event handler for menu items
###
sub menu_handler
{
	my($object,$event) = @_;

	###
	# Get actual string value of command
	# 	(we set this earlier)
	##
	my $cmd = $object->getActionCommand->get_value;

	##
	# Pop open dialog box with that string
	#	(Note static method call)
	##
	$java->javax_swing_JOptionPane("showMessageDialog",$frame,"$cmd was selected.");
}

##
# Handler for mouse clicks
##
sub mouse_handler
{
	my($object,$event) = @_;

	##
	# We're only interested in 'MOUSE PRESSSED' Events
	##
	my $mp = $java->get_field("$awt.event.MouseEvent","MOUSE_PRESSED")->get_value;
	## Get ID of this event
	my $id = $event->getID->get_value;
	
	#// A MousePressed Event...
	if ($mp == $id)
	{
# This works on every other platform but Windows!  Ridickerous.
		# 'get_value' for boolean values returns the string
		#	"true" or "false"
		if ($event->isPopupTrigger->get_value eq "true")
		{
			# Show our popup window at X,Y coordinates of mouse
			#	Note use of 'get_value' to get the actual
			#	integer position of mouse!
			$popup->show($object,$event->getX->get_value,$event->getY->get_value);
		}
	}
}
