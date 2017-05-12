use strict;
use warnings;
use Data::Dumper;
use Gtk2 -init;
use constant TRUE => 1;
use constant FALSE => !TRUE;

use Gtk2::Ex::TreeMaker;


# Create an array to contain the column_names. These names appear as the header for each column.
# The first entry should be the title of the left side of the FreezePane.
my $column_names = [ 
	'Region',
	'Nov-2003', 'Dec-2003', 'Jan-2004', 
	'Feb-2004', 'Mar-2004', 'Apr-2004',
	'May-2004', 'Jun-2004', 'Jul-2004' 
];
	
# All the attributes of the cell in the treeview are specified here
# The value for these attributes are to be populated from the recordset
# The assumption is that the attributes are contained in the data record
# in the same order towards the **end** of the record. (the last few fields)
# Since we are using CellRendererText in the TreeView, any of the properties
# of the CellRendererText can be passed using this mechanism
# In addition to the properties of the CellRendererText, I have also added a
# custom property called 'hyperlinked'.
my $data_attributes = [
	{'text' => 'Glib::String'},
	{'editable' => 'Glib::Boolean'},
	{'hyperlinked' => 'Glib::Boolean'}, 
	{'background' => 'Glib::String'},
	{'strikethrough' => 'Glib::Boolean'},	
];

# Create a recordset as an array of arrays
my @recordset;
while(<DATA>) {
   next if /^#/;
   chomp;
   my @record = split /\,/, $_;
   push @recordset, \@record;
}

# Initialize our new widget
# The constructor requires two attributes
# This constitutes of the $column_name and the $data_attributes as described above
my $treemaker = Gtk2::Ex::TreeMaker->new($column_names, $data_attributes);

# We will inject our relational recordset into the new widget
$treemaker->set_data_flat(\@recordset);

# Actually build the model. The recursive wheels are turning right now
$treemaker->build_model;

# We will provide a hook (a call-back) sub to be called when a cell is being edited.
# For fun, we will find out which record from the original recordset is being edited
# and then we will keep pushing those records into an edited_records_cache
# This event is thrown only for an 'editable' cell
$treemaker->signal_connect ('cell-edited' => \&when_cell_edited);

# This event is thrown only for a 'hyperlinked' cell
$treemaker->signal_connect ('cell-clicked' => \&when_cell_clicked);

# This event is thrown only for a 'hyperlinked' cell
$treemaker->signal_connect ('cell-enter' => \&when_cell_enter);

# This event is thrown only for a 'hyperlinked' cell
$treemaker->signal_connect ('cell-leave' => \&when_cell_leave);

# Get a reference to the widget of the treemaker
my $treemaker_widget = $treemaker->get_widget();

# That's it. Now just create a new root window to add our new widget into.
my $window = Gtk2::Window->new;
$window->signal_connect(destroy => sub { Gtk2->main_quit; });

# We'll create a button to show the contents of the edited_records_cache
my $show_button = Gtk2::Button->new('Show Edit Cache');
my @edited_records_cache;
$show_button->signal_connect (clicked => 
	sub {
		print Dumper \@edited_records_cache;
	}
);

# Why not get a bit fancier ? Its fun !
my $tooltips = Gtk2::Tooltips->new;
$tooltips->set_tip ($show_button, 
	'Edit one or more of the editable cells and finally click here to see your edit history', 
	undef);

# Add the treemaker_widget and the show_button to the root window. Make it look good !
my $buttonbox = Gtk2::HBox->new(TRUE, 0);
my $status_label = Gtk2::Label->new();
$buttonbox->pack_start($status_label, TRUE, TRUE, 0);
$buttonbox->pack_start($show_button, TRUE, TRUE, 0);
$buttonbox->pack_start(Gtk2::Label->new(), TRUE, TRUE, 0);
my $vbox = Gtk2::VBox->new (FALSE, 0);
$vbox->pack_start ($treemaker_widget, TRUE, TRUE, 0);
$vbox->pack_start ($buttonbox, FALSE, FALSE, 0);
$window->add($vbox);
$window->set_default_size(500, 300);
$window->show_all;
Gtk2->main;

# Here is the definition of the callback functions

# This event is thrown only for an 'editable' cell
sub when_cell_edited {
	# The arguments received are:
	#   The TreeMaker object itself
   #   The Gtk2::TreePath to the CELL being edited
   #   The column_id of the TreeViewColumn being edited
   #   The newly entered text
   my ($treemaker, $edit_path, $column_id, $newtext) = @_;
   my $edited_record = $treemaker->locate_record($edit_path, $column_id);
   my $cache = { RECORD => $edited_record, NEW_TEXT => $newtext };
   push @edited_records_cache, $cache;
}

# This event is thrown only for a 'hyperlinked' cell
sub when_cell_clicked {
	# The arguments received are:
	#   The TreeMaker object itself
	#   The Gtk2::TreePath to the CELL that was clicked on
	#   The column_id of the TreeViewColumn being edited
   my ($treemaker, $clicked_path, $column_id) = @_;
   my $clicked_record = $treemaker->locate_record($clicked_path, $column_id);
   print Dumper $clicked_record;
}

# This event is thrown only for a 'hyperlinked' cell
sub when_cell_enter {
	# The arguments received are:
	#   The TreeMaker object itself
	#   The Gtk2::TreePath to the CELL that was clicked on
	#   The column_id of the TreeViewColumn being edited
   my ($treemaker, $path, $column_id) = @_;
   my $clicked_record = $treemaker->locate_record($path, $column_id);
   $status_label->set_label('Click me...');
   print "Enter hyperlinked cell\n";
}

# This event is thrown only for a 'hyperlinked' cell
sub when_cell_leave {
	# The arguments received are:
	#   The TreeMaker object itself
	#   The Gtk2::TreePath to the CELL that was clicked on
	#   The column_id of the TreeViewColumn being edited
   my ($treemaker, $path, $column_id) = @_;
   my $clicked_record = $treemaker->locate_record($path, $column_id);
   $status_label->set_label('');
   print "Leave hyperlinked cell\n";
}
__DATA__
#state,city,product,date,text,editable,underline,background
Texas,Dallas,Fruits,Dec-2003,300,0,1,white,0
Texas,Dallas,Veggies,Jan-2004,120,1,0,grey,1
Texas,Austin,Fruits,Nov-2003,310,1,0,red,1
Texas,Austin,Veggies,Feb-2004,20,0,1,blue,0
Texas,Austin,Veggies,Jun-2004,80,0,0,green,1
California,LA,Veggies,Jun-2004,80,1,0,yellow,0
