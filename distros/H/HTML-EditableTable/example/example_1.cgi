#!/usr/bin/perl

# EditableTable Example 1
# demonstrates the Vertical table with a single column of data 

use strict;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use Getopt::Std;
use HTML::EditableTable;
use HTML::EditableTable::Vertical;

# this is a example of the editable vertical table.  The most basic form of this ths stores the data in a hash

my $data = {
  'tps_uid' => '404',
  'green_checks' => '4',
  'green_yellow_checks' => undef,
  'tpsid' => 'm22h',
  'project_status' => 'review',
  'manf_target' => 'internal',
  'ready_for_prod_time' => undef,
  'project_type' => 'revision',
  'creation_time' => '2007-11-09 10:25:11',
  'zpg_ref' => undef,
  'project_name' => 'm22z_octopus_revision_r7',
  'uid' => '414',
  'project_owner' => '2',
  'yellow_checks' => '1',
  'grey_checks' => undef,
  'design_name' => 'octopus',
  'manf_site' => undef,
  'prod_date' => '2008-01-14 00:00:00',
  'comment' => '',
  'technology' => '2',
  'red_checks' => undef,
  'black_checks' => undef,
};

# the specification for the table fields  - array of hash elements

my @tableFields = 
    (
     {
       'dbfield' => 'uid',
       'label' => 'project id',
     },
     {
       'dbfield' => 'creation_time',
       'label' => 'Creation Date',
     },
     {
       'dbfield' => 'tps_uid',
       'label' => 'tps id',
       'suppressCallbackOnEdit' => 1,
       'formElement' => 'textfield',
       'callback' => \&cbTPSUid,
     },
     {
       'dbfield' => 'zpg_ref',
       'label' => 'ZPG Component Reference',
       'formElement' => 'textfield',
       'tooltip' => 'must be valid id from the Zorph database',
     },
     {
       'dbfield' => 'project_name',
       'label' => 'project name',
       'tooltip' => 'poor project names will be punished',
     },
     {
       'dbfield' => 'tpsid',
       'label' => 'tps report #',
       'formElement' => 'textfield',
     },
     {
       'dbfield' => 'design_name',
       'label' => 'design name',
       'formElement' => 'textfield',
     },
     {
       'dbfield' => 'project_owner',
       'label' => 'owner',
       'formElement' => 'popup',
       'selectionList' => [1,2,3,4],
       'selectionLabels' => {1=>'Andy', 2=>'Vishesh', 3=>'Vijay', 4=>'Sergei'},
       'suppressCallbackOnEdit' => 1,
     },
     {
       'dbfield' => 'project_type',
       'label' => 'project type',
       'formElement' => 'popup',
       'selectionList' => ['PTV', 'NPI', 'Revision'],
     },
     {
       'dbfield' => 'technology',
       'label' => 'technology',
       'formElement' => 'popup',
       'selectionList' => [1,2,3,4],
       'selectionLabels' => {1=>'lfet24', 2=>'cmos17up', 3=>'hdtyos', 4=>'cmos22soi'},
     },
     {
       'dbfield' => 'manf_target',
       'label' => 'internal/external manf',
       'formElement' => 'popup',
       'selectionList' => ['internal', 'external'],
     },
     {
       'dbfield' => 'project_status',
       'label' => 'project status',
       'formElement' => 'popup',
       'selectionList' => ['review', 'rejected', 'approved'],
     },
     {
       'dbfield' => 'prod_date',
       'label' => 'design prod (YYYY-MM-DD)',
       'formElement' => 'calendar',
     },
     {
       'dbfield' => 'ready_for_prod_time',
       'label' => 'ready for prod date',
       'viewOnly' => 1,
     },	 
     {
       'dbfield' => 'comment',
       'label' => 'comment',
       'formElement' => 'textarea',
       'editOnly' => 1,
     }
     
    );

######## CGI Controller ##########

our $t = CGI->new();
print $t->header();

print "<h3>" . "Example using EditableTable::Vertical" . "</h3>";

my $context = $t->param('context') || 'view';

# might be getting a context from command-line if the script is being run in the test suite
my %opts = ();
getopts('c:', \%opts);
if ($opts{c}) { $context = $opts{c}; }

my $table = HTML::EditableTable::Vertical->new();
$table->setTableFields(\@tableFields);
$table->setSortHeader('false');
$table->setData($data);
$table->setEditMode($context);
$table->setTitle('Products');

print "<form method=get>";

$table->htmlDisplay();

my $nextContext = $context eq 'view' ? 'edit' : 'view';

print "<input type=submit name=context value=$nextContext>";

print "</form>";

##################################

# calback which provides data to the table at runtime

sub cbTPSUid {
  
  # table data available to the callback
  my ($row, $colSpec, $editMode, $rowspanSubcounter) = shift @_; 

  return "<a href=example_1.cgi?context=view&id=$row->{tps_uid}>" . $row->{tps_uid} . "</a>";
}

