#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 31;

use Gtk2::Ex::TreeMaker;
use Data::Dumper;

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
isa_ok($treemaker, "Gtk2::Ex::TreeMaker");

# We will inject our relational recordset into the new widget
ok($treemaker->set_data_flat(\@recordset));

# Actually build the model. The recursive wheels are turning right now
ok(!$treemaker->build_model);

# We will provide a hook (a call-back) sub to be called when a cell is being edited.
# For fun, we will find out which record from the original recordset is being edited
# and then we will keep pushing those records into an edited_records_cache
ok($treemaker->signal_connect ('cell-edited' => \&when_cell_edited));

ok($treemaker->signal_connect ('cell-clicked' => \&when_cell_clicked));

# Get a reference to the widget of the treemaker
my $treemaker_widget = $treemaker->get_widget();
isa_ok($treemaker_widget, "Gtk2::HPaned");

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

# Add the treemaker_widget and the show_button to the root window. Make it look good !
my $buttonbox = Gtk2::HBox->new(TRUE, 0);
$buttonbox->pack_start(Gtk2::Label->new(), TRUE, TRUE, 0);
$buttonbox->pack_start($show_button, TRUE, TRUE, 0);
$buttonbox->pack_start(Gtk2::Label->new(), TRUE, TRUE, 0);
my $vbox = Gtk2::VBox->new (FALSE, 0);
$vbox->pack_start ($treemaker_widget, TRUE, TRUE, 0);
$vbox->pack_start ($buttonbox, FALSE, FALSE, 0);
$window->add($vbox);
$window->set_default_size(500, 300);
$window->show_all;


my $CELL = undef;

# Here is the definition of the callback functions
sub when_cell_edited {
	# The arguments received are:
	#	The TreeMaker object itself
	#	The Gtk2::TreePath to the CELL being edited
	#	The column_id of the TreeViewColumn being edited
	#	The newly entered text
	my ($treemaker, $edit_path, $column_id, $newtext) = @_;
	# Since we will compare multiple cells, write a simple function for the comparison
	my $x = $edit_path->to_string();
	my $y = $column_id;
	my $z = $newtext;
	my $cell = [ $x, $y, $z ];
	is(Dumper($cell), Dumper ($CELL));
	
	#is($edit_path->to_string(), "0:1:0");
	#is($column_id, 3);
	#is($newtext, 120);
}

# Here is the definition of the callback functions
sub when_cell_clicked {
	# The arguments received are:
	#	The TreeMaker object itself
	#	The Gtk2::TreePath to the CELL that was clicked on
	#	The column_id of the TreeViewColumn being edited
	my ($treemaker, $clicked_path, $column_id) = @_;
	my $clicked_record = $treemaker->locate_record($clicked_path, $column_id);
	print Dumper $clicked_record;
}

# ------------------------------------------------------------------ #
# Start testing the values in the treemodel
# ------------------------------------------------------------------ #
my $model = $treemaker->{tree_view_full}->get_model;
my $values1 = [
	["1", 0, 'Texas'],
	["1:0", 0, 'Austin'],
	["1:0:1", 0, 'Veggies'],
	["1:0:0", 0, 'Fruits'],
	["1:1", 0, 'Dallas'],
	["1:1:1", 0, 'Veggies'],
	["1:1:0", 0, 'Fruits'],

	["0", 0, 'California'],
	["0:0", 0, 'LA'],

	["1:0:1", 0, 'Veggies'],
	["1:0:1", 1, 0],
	["1:0:1", 2, 0],
	["1:0:1", 3, undef],
	["1:0:1", 4, 0],

	# Test something from the tree_view_full side
	# First we will test a blank cell
	["1:0:1", 5, undef],
	["1:0:1", 6, 0],
	["1:0:1", 7, 0],
	["1:0:1", 8, undef],
	["1:0:1", 9, 0],
	
	# Now test a non-blank cell
	["1:0:1", 40, '80'],
	["1:0:1", 41, 0],
	["1:0:1", 42, 0],
	["1:0:1", 43, 'green'],
	["1:0:1", 44, 1],

];

my $count = 0;
foreach my $value (@$values1) {
	my $path = $value->[0];
	my $column = $value->[1];
	my $string = $value->[2];
	print Dumper $string;
	is($model->get($model->get_iter_from_string($path), $column), $string, "compare-test".$count++);
}

# ------------------------------------------------------------------ #
# Let us test the locate_record function using the same approach as above
# ------------------------------------------------------------------ #
$Data::Dumper::Sortkeys = 1;

my $x = [
	'Texas',
	'Dallas',
	'Fruits',
	'Dec-2003',
	{
		'Name' => 'Dec-2003',
		'text' => '300',
		'strikethrough' => '0',
		'background' => 'white',
		'editable' => '0',
		'hyperlinked' => '1',
	}
];

my $y = $treemaker->locate_record(Gtk2::TreePath->new_from_string("1:1:0"), 2);
is(Dumper($x), Dumper ($y));

# ------------------------------------------------------------------ #
# Figure out how to add tests for the events
# ------------------------------------------------------------------ #
# Let us start editing
#print Dumper $treemaker->{treeview_columns};
$CELL = ['0:1:0', '3', '120'];
$treemaker->{tree_view_full}->set_cursor (Gtk2::TreePath->new_from_string("0:1:0"), $treemaker->{treeview_columns}->[3], TRUE);
$window->get_focus->activate;

$CELL = ['0:0:1', '1', '310'];
$treemaker->{tree_view_full}->set_cursor (Gtk2::TreePath->new_from_string("0:0:1"), $treemaker->{treeview_columns}->[1], TRUE);
$window->get_focus->activate;

__DATA__
#state,city,product,date,text,editable,underline,background
Texas,Dallas,Fruits,Dec-2003,300,0,1,white,0
Texas,Dallas,Veggies,Jan-2004,120,1,0,grey,1
Texas,Austin,Fruits,Nov-2003,310,1,0,red,1
Texas,Austin,Veggies,Feb-2004,20,0,1,blue,0
Texas,Austin,Veggies,Jun-2004,80,0,0,green,1
California,LA,Veggies,Jun-2004,80,1,0,yellow,0
