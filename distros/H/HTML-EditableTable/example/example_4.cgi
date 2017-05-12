#!/usr/bin/perl

# EditableTable Example 4
# demonstrates the Horizontal table with a fairy complex dataset and rowspanning

use strict;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use Getopt::Std;
use HTML::EditableTable;
use HTML::EditableTable::Horizontal;

my @tableData = 
    (
     {
       'part_id' => 7765,
       'catalog_id' => 'UX35AT',
       'addition_date' => '2008-10-10',
       'part_name' => 'control module',
       'vendor' => 'Praxis',
       'description' => 'ABS package with revA firmware.  Used in low-cost applications and as replacement for model UX34AT.  Includes adaptor wiring harness for UX34AT',
       'part_options' => 
	   [
	    { 
	      'option_id' => 'O17G',
	      'color' => 'green',
	      'power_rating' => '17w',
	    },
	    {
	      'option_id' => 'O24R',
	      'color' => 'red',
	      'power_rating' => '24w',
	    }
	   ],	   
       'rohs_category' => 2,
       'reorder_class' => 'C',
       'last_order_date' => '2010-06-10',
     },
     {
       'part_id' => 7961,
       'catalog_id' => 'ZX42AT',
       'addition_date' => '2009-03-01',
       'part_name' => 'power regulator',
       'vendor' => 'Armscor',
       'description' => 'Minature power supply with redundant relays',
       'part_options' => 
	   [
	    { 
	      'option_id' => 'O3W',
	      'color' => 'yellow',
	      'power_rating' => '3w',
	    },
	    {
	      'option_id' => 'O4P',
	      'color' => 'pink',
	      'power_rating' => '4w',
	    }
	   ],
       'rohs_category' => 2,
       'reorder_class' => 'A',
       'last_order_date' => '2009-12-17',
     },
    {
       'part_id' => 8055,
       'catalog_id' => 'UX24AT',
       'addition_date' => '2007-04-08',
       'part_name' => 'control module',
       'vendor' => 'Subarashii',
       'description' => 'Obsolete control module for A45 overthruster.  Requires UX27AZ conditioner and 3F buffering caps if the overthruster runs >18psi',
       'part_options' => 
	   [
	    { 
	      'option_id' => 'O76B',
	      'color' => 'blue',
	      'power_rating' => '76w',
	    },
	    {
	      'option_id' => 'O98O',
	      'color' => 'orange',
	      'power_rating' => '98w',
	    },
	    { 
	      'option_id' => 'Z103',
	      'color' => 'red',
	      'power_rating' => '103w',
	    },
	    {
	      'option_id' => 'Z120',
	      'color' => 'pink',
	      'power_rating' => '120w',
	    }
	   ],
       'rohs_category' => 4,
       'reorder_class' => 'A',
       'last_order_date' => '2005-08-19',
     },
    );

my @tableFields =
    (
     {
       'editOnly' => 1,
       'formElement' => 'deleteRowButton',
     },
     {
       'dbfield' => 'part_id',
       'label' => 'Part Id',
       'viewOnly' => 1,
       'callback'=> \&cbPartId,
     },
     {
       'dbfield' => 'catalog_id',
       'label' => 'Catalog Id',
       'formElement' => 'textfield',
       'size' => 15,
       'uniquifierField' => 'part_id',
       'rowspanArrayKeyForUniquification' => 'part_options',
       'rowspanArrayUniquifier' => 'option_id',
     },
     {
       'dbfield' => 'addition_date',
       'label' => 'Available From',
       'formElement' => 'calendar',
       'uniquifierField' => 'part_id',
     },
     {
       'dbfield' => 'part_name',
       'label' => 'Part Name',
       'formElement' => 'textfield',
       'size' => 20,
       'uniquifierField' => 'part_id',
     },
     {
       'dbfield' => 'vendor',
       'label' => 'Vendor',
       'formElement' => 'popup',
       'selectionList' => ['', 'Amexx', 'Armscor', 'Consolidated', 'Gentine', 'Oroco', 'Praxis',  'Shellalco', 'Subarashii',],
       'uniquifierField' => 'part_id',
     },
     {
       'dbfield' => 'description',
       'label' => 'Part Description',
       'formElement' => 'textarea',
       'subBr' => 1,
       'drillDownTruncate' => 60,
       'uniquifierField' => 'part_id',
       'style' => "font-family:'Times New Roman';font-size:12px;",     
     },
     {
       'dbfield' => 'part_options',
       'rowspanArrayKey' => 'option_id',
       'label' => 'Option #',
     },
     {
       'dbfield' => 'part_options',
       'rowspanArrayKey' => 'color',
       'uniquifierField' => 'part_id',
       'rowspanArrayUniquifier' => 'option_id',
       'label' => 'Color',
       'formElement' => 'popup',
       'selectionList' => ['blue', 'green', 'orange', 'pink', 'red', 'yellow'],
     },
     {
       'dbfield' => 'part_options',
       'rowspanArrayKey' => 'power_rating',
       'uniquifierField' => 'part_id',
       'rowspanArrayUniquifier' => 'option_id',
       'label' => 'Power Rating',
       'formElement' => 'textfield',
       'minimalEditSize' => 1,
     },
     {
       'dbfield' => 'rohs_category',
       'label' => 'RoHS',
       'formElement' => 'popup',
       'selectionList' => ['',1..10],
       'selectionLabels' => {
	 1 => 'Large and small household appliances',
	 2 => 'IT equipment',
	 3 => 'Telecommunications equipment',
	 4 => 'Consumer equipment',
	 5 => 'Lighting equipment',
	 6 => 'Electronic and electrical tools',
	 7 => 'Toys, leisure, and sports equipment',
	 8 => 'Medical devices',
	 9 => 'Monitoring and control instruments',
	 10 => 'Automatic dispensers',
       },
       'uniquifierField' => 'part_id',
     },
     {
       'dbfield' => 'reorder_class',
       'label' => 'Reorder Class',
       'formElement' => 'popup',
       'selectionList' => ['', 'A', 'B', 'C'],
       'uniquifierField' => 'part_id',
     },
     {
       'dbfield' => 'last_order_date',
       'label' => 'Last Ordered',
       'formElement' => 'calendar',
       'uniquifierField' => 'part_id',
     },     
    );

######## CGI Controller ##########

our $t = CGI->new();
print $t->header();

print "<h3>" . "Example using EditableTable::Horizontal" . "</h3>";



my $context = $t->param('context') || 'view';

# might be getting a context from command-line if the script is being run in the test suite
my %opts = ();
getopts('c:', \%opts);

if ($opts{c}) { $context = $opts{c}; }

my $tabIndex  = 100;



my $table = HTML::EditableTable::Horizontal->new
    (
     {
       'tableFields' => \@tableFields,
       'width' => '100%',
       'jsAddData' => 1,
       'editMode' => $context,
       'data' => \@tableData,
       'tabindex' => \$tabIndex,
       'title' => "title test",
       'sortHeader' => "example_4.cgi?",  # server side sort url
       'sortData' => 1, # let EditableTable do the sort rather than assume it is done by the caller (in SQL, typically)
     }
    );

print "<form method=post>";

$table->htmlDisplay();

my $nextContext = $context eq 'view' ? 'edit' : 'view';

print "<input type=submit name=context value=$nextContext>";
print "</form>";

######## TABLE CALLBACKS ##########

sub cbPartId {
  my ($row, $colSpec, $editMode, $rowspanSubcounter) = shift @_;   
  return "<a href=example_4.cgi?context=view&uid=$row->{part_id}>" . $row->{part_id} . "</a>";
  
}

  
