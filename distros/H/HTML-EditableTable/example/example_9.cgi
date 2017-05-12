#!/usr/bin/perl

# EditableTable Example 9 - test case for multiple tables in same cgi
# demonstrates the Horizontal table

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
       'qa_results' => 'see http://yoururl.com/index.cgi?context=qa',
       'qoh' => '65',
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
       'qa_results' => '2ppm confirmed',
       'qoh' => '32',
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
       'qa_results' => 'see http://yoururl.com/index.cgi?context=qa',
       'qoh' => '2',
       'rohs_category' => 4,
       'reorder_class' => 'A',
       'last_order_date' => '2005-08-19',
     },
    );

my @tableData2 = @tableData;

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
     },
     {
       'dbfield' => 'catalog_id',
       'label' => 'Catalog Id',
       'formElement' => 'textfield',
       'size' => 15,
       'uniquifierField' => 'part_id',
       'tooltip' => '2010 Catalog Id',
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
     },
     {
       'dbfield' => 'qa_results',
       'label' => 'QA Results',
       'formElement' => 'textfield',
       'linkifyContentOnView' => 1,
       'uniquifierField' => 'part_id',
     },
     {
       'dbfield' => 'qoh',
       'label' => 'Quantity',
       'formElement' => 'textfield',
       'size' => 5,
       'uniquifierField' => 'part_id',
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

my @tableFields2 = @tableFields;

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
       'style' => "border-width:5px;",
       'jsSortHeader' => 1,       
     }
    );

print "<form method=post>";

print "<h2>Table 1</h2>";
$table->htmlDisplay();

$tabIndex  = 500;

my $table2 = HTML::EditableTable::Horizontal->new
    (
     {
       'tableFields' => \@tableFields2,
       'width' => '100%',
       'jsAddData' => 1,
       'editMode' => $context,
       'data' => \@tableData2,
       'tabindex' => \$tabIndex,
       'style' => "border-width:5px;",
       'sortHeader' => "example_9.cgi?context=$context&",
       'sortData' => 1,       
     }
    );

print "<h2>Table 2</h2>";
$table2->htmlDisplay();

my $nextContext = $context eq 'view' ? 'edit' : 'view';

print "<input type=submit name=context value=$nextContext>";
print "</form>";

  
