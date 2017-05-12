#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 4;

use Gtk2::Ex::TreeMaker;
use Data::Dumper;

my $column_names = [ 
	'Region',
	'Nov-2003', 'Dec-2003', 'Jan-2004', 
	'Feb-2004', 'Mar-2004', 'Apr-2004',
	'May-2004', 'Jun-2004', 'Jul-2004' 
];

my $data_attributes = [
	{'text' => 'Glib::String'},
	{'editable' => 'Glib::Boolean'},
	{'hyperlinked' => 'Glib::Boolean'}, 
	{'background' => 'Glib::String'},
	{'strikethrough' => 'Glib::Boolean'},  
];

my @recordset;
while(<DATA>) {
	next if /^#/;
	chomp;
	my @record = split /\,/, $_;
	push @recordset, \@record;
}

my $treemaker = Gtk2::Ex::TreeMaker->new($column_names, $data_attributes);
isa_ok($treemaker, "Gtk2::Ex::TreeMaker");

ok($treemaker->set_data_flat(\@recordset));

ok(!$treemaker->build_model);

my $treemaker_widget = $treemaker->get_widget();
isa_ok($treemaker_widget, "Gtk2::HPaned");

my $window = Gtk2::Window->new;
$window->signal_connect(destroy => sub { Gtk2->main_quit; });

$window->add($treemaker_widget);
$window->set_default_size(500, 300);
$window->show_all;

__DATA__
#state,city,product,date,text,editable,underline,background
Texas,Dec-2003,300,0,1,white,0
Texas,Jan-2004,120,1,0,grey,1
Texas,Nov-2003,310,1,0,red,1
Texas,Feb-2004,20,0,1,blue,0
Texas,Jun-2004,80,0,0,green,1
California,Jun-2004,80,1,0,yellow,0
