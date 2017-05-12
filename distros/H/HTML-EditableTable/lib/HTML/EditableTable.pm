package HTML::EditableTable;

use warnings;
use strict;
use Carp qw(confess);
use CGI qw(:standard);

use HTML::EditableTable::Javascript;

=head1 NAME

HTML::EditableTable - Classes for html presentation of tabular data with view and edit modes.

=head1 VERSION

Version 0.21

=cut

our $VERSION = '0.21';

=head1 SYNOPSIS

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

 ######## CGI Controller ##########

 my $t = CGI->new();
 print $t->header();

 my $context = $t->param('context') || 'view';

 my $table = HTML::EditableTable::Horizontal->new
    (
     {
       'tableFields' => \@tableFields,
       'width' => '100%',
       'jsAddData' => 1,
       'editMode' => $context,
       'data' => \@tableData,
       'jsSortHeader' => 1,
     }
    );

 print "<form method=post>";
 
 $table->htmlDisplay();
 
 my $nextContext = $context eq 'view' ? 'edit' : 'view';

 print "<input type=submit name=context value=$nextContext>";
 print "</form>";


=head1 DESCRIPTION

This module was developed to simplify the manipuation of complex tabular data in engineering and business-process web applications.  The motivation was a rapid-prototype software development flow where the requirements gathering phase goes something like "I have this big complicated spreadsheet that I want to make a website out of..., can you help?".  The EditableTable class is an 'abstract' base class and EditableTable::Horizontal and EditableTable::Vertical are the implementations for two commonly used table types.  Key features of these classes are as follows:

- toggling of the table between view and edit modes with support for common html widgets

- uniquification of form element data to support processing of html form submissions of table data

- support for rowspanning

- methods to generate javascript for dynamic addition and remove of rows and commonly needed features such as 'click-to-expand' text display, calendar widget date entry, and sorting

- support for callbacks when data need to be pre-processed prior to display

For the Horizontal table, data are provided to tables in an array-of-hashes (most common case) or a hash-of-hashes.  For the Vertical table, a single hash of data produces a single column of data while a hash-of-hashes supports muliple data columns.

=head1 TABLE METHODS AND PARAMETERS

The class methods are designed along 'public' and 'private' lines.  The intended use model is indicated in the method descriptions.

=cut

my $globalTableUid = 1;

# valid table parameters

my %validTableFieldKeys =
    (
     'dbfield' => 1,
     'label' => 1,
     'formElement' => 1,
     'callback' => 1,
     'selectionList' => 1,
     'selectionLabels' => 1,
     'subBr' => 1,
     'subCommaForBr' => 1,
     'style' => 1,
     'editOnly' => 1,
     'viewOnly' => 1,
     'suppressCallbackOnEdit' => 1,
     'align' => 1,
     'width' => 1,
     'size' => 1,
     'minimalEditSize' => 1,
     'maxLength' => 1,
     'bgcolor' => 1,
     'rowspanArrayKey' => 1,
     'rowspanArrayUniquifier' => 1,
     'rowspanArrayKeyForUniquification' => 1,
     'masterCounterUniquify' => 1,
     'styleHandler' => 1,
     'default' => 1,
     'modeModifier' => 1,
     'tooltip' => 1,
     'editOnlyOnNegativeValue' => 1,
     'selectionListCallback' => 1,
     'htmlSub' => 1,
     'linkifyContentOnView' => 1,
     'drillDownTruncate' => 1,
     'uniquifierField' => 1,
     'jsClearColumnOnEdit' => 1,
     'checkBehavior' => 1,
    );

=head2 new (public)

Common constructor for EditableTable-derived classes.  Providing the required initialization data to new() can be done either by a hashref to table-level parameters or by calling the required set*() methods prior to rendering the table with htmlDisplay().  The following examples detail the minimum requirements for configuring an EditableTable.

 my $table = EditableTable::Horizontal->new
   (
     {
       'tableFields' => \@tableFields;
       'data' => \@data,
       'editMode' => 'edit'
     }
   );

or

 my $table = EditableTable::Horizontal->new()
 $table->setTableFields(\@tableFields);
 $table->setData(\@data);
 $table->setEditMode('edit'); 

=cut

sub new {

    my $type = shift @_;
    my $class = ref($type) || $type;

    my $self = {};

    #### public data which needs to be intitialized

    $self->{'tableFields'} = [];
    $self->{'data'} = undef;
    $self->{'editMode'} = undef;

    #### data which is intended to be private

    # used for certain column options for name uniquification
    $self->{'masterCounter'} = 1;


    # default unique table id.  Setting this is important if you have more than one table
    $self->{'tableId'} = $globalTableUid++;

    # used for uniquification of elements in embedded javascript
    # since multiple tables may be in play, ensure initial value is unique
    # note each table should embed its own javascript.  Do this after 4.0 release

    $self->{'elementUid'} = $self->{'tableId'} + int(rand(1000000)); # BFBA terrible hack

    # flag to auto-display javascript if required
    $self->{javascriptDisplayed} = 0;

    # default directory for jsCaldendar when this feature is used
    $self->{calendarDir} = 'jscalendar';

    # table field parameter validation is on by default
    $self->{validateTableFieldKeys} = 1;

    # flag set when stdout is rerouted to avoid multiple acts of this
    $self->{stdoutRerouted} = 0;
    
    my $initData = shift @_;

    bless $self, $class;

    if ($initData) {
	if (ref($initData) ne 'HASH') { confess "expecting hash reference to initialization data for $class, got a " . ref($initData); }
	$self->initialize($initData);
    }

    return $self;
}

=head2 initialize (private)

Peforms validation of data provided to the constuctor and makes set*() calls.

=cut

sub initialize {
  
    my $self = shift @_;
    my $initData = shift @_;

    if (exists $initData->{'data'}) { $self->setData(delete $initData->{'data'});  }
    if (exists $initData->{'tableFields'}) { $self->setTableFields(delete $initData->{'tableFields'}); }
    if (exists $initData->{'editMode'}) { $self->setEditMode(delete $initData->{'editMode'}); }
    if (exists $initData->{'sortHeader'}) { $self->setSortHeader(delete $initData->{'sortHeader'}); }
    if (exists $initData->{'jsSortHeader'}) { $self->setJsSortHeader(delete $initData->{'jsSortHeader'}); }
    if (exists $initData->{'sortData'}) { $self->setSortData(delete $initData->{'sortData'}); }
    if (exists $initData->{'tabindex'}) { $self->setTabindex(delete $initData->{'tabindex'}); }
    if (exists $initData->{'title'}) { $self->setTitle(delete $initData->{'title'}); }
    if (exists $initData->{'tableId'}) { $self->setTableId(delete $initData->{'tableId'}); }
    if (exists $initData->{'width'}) { $self->setWidth(delete $initData->{'width'}); }
    if (exists $initData->{'style'}) { $self->setStyle(delete $initData->{'style'}); }
    if (exists $initData->{'jsAddData'}) { $self->setJsAddData(delete $initData->{'jsAddData'}); }
    if (exists $initData->{'noheader'}) { $self->setNoheader(delete $initData->{'noheader'}); }
    if (exists $initData->{'rowspannedEdit'}) { $self->setRowspannedEdit(delete $initData->{'rowspannedEdit'}); }
    if (exists $initData->{'sortOrder'}) { $self->setSortOrder(delete $initData->{'sortOrder'}); }
    if (exists $initData->{'border'}) { $self->setBorder(delete $initData->{'border'}); }
    if (exists $initData->{'suppressUndefinedFields'}) {$self->setSuppressUndefinedFields(delete $initData->{'setSuppressUndefinedFields'}); }
    if (exists $initData->{'calendarDir'}) {$self->setCalendarDir(delete $initData->{'calendarDir'}); }
    if (exists $initData->{'validateTableFieldKeys'}) {$self->setValidateTableFieldKeys(delete $initData->{'validateTableFieldKeys'}); }
    if (exists $initData->{'stringOutput'}) { $self->setStringOutput(delete $initData->{'stringOutput'}); }
    
    my @remainingInitKeys = keys %$initData;
    
    if (scalar(@remainingInitKeys)) {
	confess "one or more table parameters are not understood (@remainingInitKeys)";
    }

    # further validation

    # sorting options check - since there are three general ways to sort table data, ensure only one of them is used

    if (exists($self->{sortOrder}) + exists($self->{sortHeader}) + exists($self->{jsSortHeader}) > 1) {
      confess "Conflicting sort options have been specified.  Only one of 'sortOrder', 'sortHeader', and 'jsSortHeader' may be specified";
    }    
}

=head2 setValidateTableFieldKeys (public)

Toggles validation of field-level parameters.  Enabled by default.  Disable only if validation is a performance issue.

 $table->setValidateTableFieldKeys(0)

=cut

# validation of table field parameters

sub setValidateTableFieldKeys {
  my $self = shift;
  my $val = shift;
  $self->{validateTableFieldKeys} = $self->checkBool($val);
}

=head2 isvalidTableFieldKey (private)

Called for each field-level key parameer if validateTableFieldKeys is enabled (the default).

=cut

sub isValidTableFieldKey {
  my $self = shift;
  my $key = shift;
  if ($validTableFieldKeys{$key}) { return 1; }
  else { return 0; }
}

=head2 getConfigParams (private)

this is used by the Javascript Object to determine which javascript code to write for the table

=cut

# this is used by the Javascript Object to determine which javascript code to write for the table

sub getConfigParams {
  my $self = shift;
  my @params = keys %$self;
  return \@params
}

=head2 isParamSet (private)

this is used by the Javascript Object to determine which javascript code to write for the table

=cut

sub isParamSet {
  my $self = shift;
  my $paramName = shift;
  if ($self->{$paramName}) { return 1; }
  else { return 0; }
}

=head2 setTableId (public)

Sets the html 'id' attribute for the top level <table> tab

 $table->setTableId('catalog_table_2')

=cut

sub setTableId {
  my $self = shift;
  my $tableId = shift;
  if(!defined($tableId)) { confess "table id is not specified"; }
  $self->{tableId} = $tableId;
}

=head2 getTableId (public)

Returns the 'tableId', which represents the <table> id attribute

 $table->getTableId()

=cut

sub getTableId {
  my $self = shift;
  return $self->{tableId};
}

=head2 setData (public)

Required parameter.  The data structure provided to an EditableTable can take the following forms:

array of hashrefs (most common for Horizontal Table)

 $table->setData(
    [
      {
        'id' => 1001,
        'name' => 'wiring harness'
      },
      {
        'id' => 1002,
        'name' => 'wiring harness (new style)'
      }
    ]
 )

a hashref of hashrefs - this allows sorting the rows by hash key.  This structure is allowable for EditableTable::Horizontal and multi-column Editable::Vertical.  See L</"SORTING"> for details.

 $table->setData(
    {
      '1001' => {
                  'id' => 1001,
                  'name' => 'wiring harness'
                },
      '1002' => {
                  'id' => 1002,
                  'name' => 'wiring harness (new style)'
                }
    }

a hashref - used for single column EditableTable::Vertical

 $table->setData( 
                  {
                    'id' => 1001,
                    'name' => 'wiring harness',
                  }
                )

=cut   

sub setData {
  my $self = shift @_;
  my $data = shift @_;

    unless (ref($data) eq 'ARRAY' || ref($data) eq 'HASH') { confess "data must be an array ref or hash ref, this is a " . ref($data); }

    $self->{'data'} = $data;
}

=head2 getData (public)

returns the reference to the 'data' parameter

=cut

sub getData {
    my $self = shift @_;

    return $self->{'data'};
}

=head2 setTableFields (public)

Required parameter.  An arrayref of hashrefs to parameters for each table field.  Fields are presented left-to-right in array order for Horizontal tables and top-to-bottom for Vertical Tables.  See L</"TABLE FIELD PARAMETERS"> for documentation of the field parameters.

 $table->setTableFields (
   [
     {
       'dbfield' => id,
       'label' => 'ID#'
    },
    {
       'dbfield' => name,
       'label' => 'Name'
    }
   ];

=cut

sub setTableFields {
    my $self = shift @_;
    my $tableFields = shift @_;

    unless (ref($tableFields) eq 'ARRAY') { confess "the table field specification must have the form of an array ref of hash refs"; }

    # if the table array is not empty, make sure it looks like an array of hashes
    if (scalar @$tableFields) {
	unless (ref($tableFields->[0]) eq 'HASH') { confess "the table field specification must have the form of an array ref of hash refs"; }
    }

    # basic validation of each field's options.  mistyping a field key is a common error in programming EditableTable.    
    # also auto-identify rowspanning data structures

    if ($self->{validateTableFieldKeys}) {   
      foreach my $field (@$tableFields) {    
	foreach my $key (keys %$field) {
	  if (!$self->isValidTableFieldKey($key)) {
	    confess "$key is not a valid table field parameter.";
	  }
	}	
      }
    }
    
    $self->{'tableFields'} = $tableFields;
}

=head2 getTableFields (public)

Returns an arrayref to the 'tableFields' table parameter.

=cut

sub getTableFields {
    my $self = shift @_;
    return $self->{tableFields};
}

=head2 setEditMode (public)

Required parameter.  Set the table mode to 'view' or 'edit'.  In 'view' mode, a table field is reprsented by text. In 'edit' mode, the a field is represented by 'its formElement' parameter.

 $table->setEditMode('edit');

=cut

sub setEditMode {
    my $self = shift @_;
    my $editMode = shift @_;

    unless ($editMode eq 'edit' || $editMode eq 'view') { confess "edit mode must be 'edit' or 'view'"; }

    $self->{'editMode'} = $editMode;
}

=head2 setStringOutput (public)

By default, EditableTable's htmlDisplay and htmlJavascriptDisplay method will output to STDOUT.  If stringOutput is set to 1 or 'true', then htmlDisplay will return a string with the table html.

 $table->setStringOutput(1);
 my $tableHtml = $table->htmlDisplay();

=cut

sub setStringOutput {
   my $self = shift @_;
   my $val = shift @_;
   $self->{'stringOutput'} = $self->checkBool($val);
}

=head2 setSortHeader (public)

Set a base url for server-side sorting.  See L</"SORTING"> for details on the sorting options for EditableTable.

 $table->setSortHeader("http://yoururl.com?session=ruggs98888&");

=cut

# print a clickable header which sorts by that column

sub setSortHeader {
    my $self = shift @_;
    my $sortHeader = shift @_;

    if (ref($sortHeader)) { confess "the sort header is a string with the url leading up to the name of the column you wish to sort by, this is a " . ref($sortHeader); }

    # need a check here

    $self->{'sortHeader'} = $sortHeader;
}

=head2 setSortData (public)

When set, EditableTable will sort the $self->{data} server-side.  Often this is unecessary as the data will have been presorted using SQL, but for small tables this is less work and is self-contained to the EditableTable class.

 $table->setSortData(1);

=cut

sub setSortData {
  my $self = shift @_;
  my $sortData = shift @_;
  $self->{'sortData'} = $self->checkBool($sortData);   
}

=head2 setJsSortHeader (public)

When set, implements javascript for client-side table sorting.  See L</"SORTING"> for details on EditableTable sorting.

 $table->setSortData(1)

=cut

# javascript dynamic sort header

sub setJsSortHeader {
    my $self = shift @_;
    my $jsSortHeader = shift @_;
    $self->{'jsSortHeader'} = $self->checkBool($jsSortHeader);    
}

=head2 setTabindex (public)

Use when the EditableTable needs to be integrated with other form elements and the tabindex isn't desirable.  This sets all the tabindex values for formElemnts to the specified number, which will result in the browser default behavior being applied to the table but in the correct order with other form elements.  An reference is used in case the behavior of this method is changed in the future.

 my $tabindex = 100;

 $table->setTabindex(\$tabindex);

=cut

# reference to tab index to integrate table with the form

sub setTabindex {
    my $self = shift @_;
    my $tabindex = shift @_;
    if (ref($tabindex) ne 'SCALAR') { confess "the tabindex must be a reference to the tabindex"; }
    $self->{'tabindex'} = $tabindex;
}

=head2 setTitle (public)

Sets table title using colspanned <th> tag.  Note that this method only works on Vertical tables as it conflicts with the javascript client-side sorting.

 $self->setTitle("Table Title")

=cut

# title for top of table in a single rowspan

sub setTitle {
    my $self = shift @_;
    my $title = shift @_;
    if (ref($title)) { confess "the title is a string with the table title"; }
    $self->{'title'} = $title;
}

# table width

=head2 setWidth (public)

sets the <table> 'width' parameter in pixels.  Alternatively, use setStyle.

 $table->setWidth(1024);

=cut

sub setWidth {
    my $self = shift @_;
    my $width = shift @_;
    if (ref($width) || $width !~ /\d+/) { confess "not a number!"; }
    $self->{'width'} = $width;
}

=head2 setBorder (public)

sets the <table> 'border' param.  Alternatively, use setStyle.

 $table->setBorder(1);

=cut

# table border

sub setBorder {
  my $self = shift @_;
  my $border = shift @_;
  if (ref($border) || $border !~ /\d+/) { confess "not a number!"; }
  $self->{'border'} = $border;
}

=head2 setStyle (public)

sets <table> 'style' attribute.
 
 $table->setStyle("border-width:1px;");

=cut

sub setStyle {
  my $self = shift @_;
  my $style = shift @_;
  if (ref($style)) { confess "style is not a string"; }
  $self->{'style'} = $style;
}
  
=head2 setJsAddData (public)

For Horizontal tables.  Use to activate javascript to support addition of new table rows.  See L</"JAVASCRIPT INTEGRATION"> for details.

 $table->setJsAddData(1);

=cut

# indicates that a button to insert a row of data into the table is to be provided when in edit mode

sub setJsAddData {
   my $self = shift @_;
   my $jsAddData = shift @_;
   $self->{'jsAddData'} = $self->checkBool($jsAddData);
}

=head2 setNoHeader (public)

For Horizontal Tables.  Suppresses the table header row.

 $self->setNoHeader(1);

=cut

# suppresses column headings

sub setNoHeader {

   my $self = shift @_;
   my $noheader = shift @_;
   $self->{'noheader'} = $self->checkBool($noheader);
}

=head2 setRowspannedEdit (public)

By default, a rowspanned table will flatten in 'edit' mode, with the rowspanning column repeated for each of the spanned rows.  This is done to enable editing of the relationship betwen the fields and to preserve unique ids.  If this is not the desired behavior, use this method to preserve the rowspanning in 'edit' mode.

 $table->setRowspannedEdit(1);

=cut

sub setRowspannedEdit {

   my $self = shift @_;
   my $rowspannedEdit = shift @_;
   $self->{'rowspannedEdit'} = $self->checkBool($rowspannedEdit);

}

=head2 setSortOrder (public);

For Horizontal tables with a hash of hashes data structure, this sorts the rows per the provided arrayref.  For Vertical tables with multiple data columns, sorts the columns left-to-right per the provided arrayref.

 $table->setSortOrder(['UX34IG' , 'UX45ZZ', 'RG01IG']);\

=cut

# horizontal tables provided with hash of hashes: an array ref to key list used to sort hash of hashes

sub setSortOrder {

    my $self = shift @_;
    my $sortOrder = shift @_;
    if (ref($sortOrder ne 'ARRAY')) { confess "the sort order must be a reference to an array of the dataset keys which will used to determine the row order"; }

    $self->{'sortOrder'} = $sortOrder;
}

=head2 setSuppressUndefinedFields (public)

For Vertical tables.  Avoids displaying a row if the data value for that row is undefined.  Useful for using a single key set with partial data.

 $table->setSuppressUndefinedFields(1)

=cut

# block display of undefined fields - vertical table only

sub setSuppressUndefinedFields {
    my $self = shift @_;
    my $suppressUndefinedFields = shift @_;
    $self->{'suppressUndefinedFields'} = $self->checkBool($suppressUndefinedFields);
}

=head2 getCalendarDir (public)

Returns the directory for installation of www.dynarch.com jscalendar-1.0, which is supported in the 'calendar' formElement.  Defaults to 'jscalendar'  if not set.
 
 $self->getCalendarDir();

=cut

sub getCalendarDir {
  my $self = shift @_;
  return $self->{calendarDir};
}

=head2 setCalendarDir (public)

Directory for installation of www.dynarch.com jscalendar-1.0, which is supported in the 'calendar' formElement.  Defaults to 'jscalendar'  if not set.
 
 $self->setCalendarDir('jscal_10');

=cut

sub setCalendarDir {
  my $self = shift @_;
  my $calendarDir = shift @_ || confess "missing calendar directory";
  $self->{calendarDir} = $calendarDir;
}

=head2 htmlDisplay (public)

This method renders the html to STDOUT.  If table requirements are not met, an exception will occur when this method is called.

 $table->htmlDisplay()

=cut

sub htmlDisplay {

    my $self = shift @_;

    # re-route STDOUT to string if called for
    
    my $stdout = undef;

    if ($self->{stringOutput} && !$self->{stdoutRerouted}) {

      open(TMPOUT, '>&', \*STDOUT) || confess "failed to save STDOUT";
      close STDOUT;
      open(STDOUT, '>', \$stdout) || confess "failed to reroute STDOUT to string";
      
      # set flag nested calls don't redo this
      $self->{stdoutRerouted} = 1;
    }
    
    # display javascript - this method will return immediately if the javascriptDispalyed flag is set.

    $self->htmlJavascriptDisplay();

    # ensure we have all the required parameters populated before attempting to create the table html

    if (!$self->{'data'}) { confess "table parameters are incompelete - missing data!"; }
    if (!$self->{'tableFields'}) { confess "table parameters are incompelete - missing table view specification!"; }
    if (!$self->{'editMode'}) { confess "table parameters are incompelete - missing edit mode!"; }

    # print a hidden template row if the jsAddData feature is being used

    if ($self->{jsAddData}) {
	$self->htmlAddDataSetup();
    }

     # sort the data server-side if this option is used
     # many times this is the best approach, but sometimes the calling server code will have the data
     # already sorted via SQL

     if (CGI::param('orderByAsc') && $self->{sortData}) {

       my @sortedTableData = sort {$a->{CGI::param('orderByAsc')} cmp $b->{CGI::param('orderByAsc')}} @{$self->{data}};
       $self->{data} = \@sortedTableData;
     }
     elsif (CGI::param('orderByDesc') && $self->{sortData}) {

       my @sortedTableData = sort {$b->{CGI::param('orderByDesc')} cmp $a->{CGI::param('orderByDesc')}} @{$self->{data}};
       $self->{data} = \@sortedTableData;
     }

    # virtual method which must be inherited for core table drawing

    $self->makeTable();

    # if stdout rerouted
     if ($self->{stringOutput}) {
      open STDOUT, '>&', \*TMPOUT;
      close TMPOUT;

      $self->{stdoutRerouted} = 0;

      return $stdout;
    }
}

=head2 removeField (public)

Use to elminate a member of the 'tableFields'. Returns the table field hashref.  Requires the key and the value to identify the field to remove

 $table->removeField('dbfield', 'partId');
 $table->removeField('label', 'Part Id#');  

=cut

sub removeField {

    my $self = shift @_;
    my $colSpecField = shift @_;
    my $colSpecValue = shift @_ || confess "must provide key/value for colspec column to remove";

    my $tableFields = $self->{tableFields};

    for (my $i=0; $i<scalar(@{$tableFields}); $i++) {
        my $colSpec = $tableFields->[$i];
        if ($colSpec->{$colSpecField} eq $colSpecValue) {
            splice @{$tableFields},$i,1;
            return $colSpec; # return it in case user wants to reuse it
        }
    }

    return undef;
}

=head2 setColumnLabel (public)

Given a 'dbfield' table field value, replaces the 'label' parameter with the supplied value.

 $table->setColumnLabel('partId', 'Part Id#');

=cut

sub setColumnLabel {

   my $self = shift @_;
   my $dbfield = shift @_;
   my $newLabel = shift @_;

    my $tableFields = $self->{tableFields};

    for (my $i=0; $i<scalar(@{$tableFields}); $i++) {
        my $colSpec = $tableFields->[$i];
        if ($colSpec->{dbfield} eq $dbfield) {
	    $colSpec->{label} = $newLabel;
            return;
        }
    }

    return undef;

}

=head2 shiftField (public)

shifts and returns a 'tableField'

 my $field = $table->shiftField();

=cut

sub shiftField {

    my $self = shift @_;
    my $fieldRef =shift @{$self->{'tableFields'}};

    return $fieldRef;
}

=head2 unshiftField (public)

unshifts the 'tableFields' with the provided tableField hashref.

 my $field = { 'dbfield' => 'partId', 'label' => 'Part Id#' };
 $table->unshiftField($field);

=cut

sub unshiftField {

    my $self = shift @_;
    my $colSpec = shift @_;
    if (ref($colSpec) ne 'HASH') { confess "field spec is not in the correct format - expecting a hash reference"; }

    unshift @{$self->{'tableFields'}}, $colSpec;
}

=head2 setJavascript (public)

This method can be used to override the default javascript object.  Inherit from HTML::EditableTable::Javascript and provide an object reference to your table prior to calling htmlJavascriptDisplay().  If this method is not used, the default class will be used to create a javascript object.  See L</"JAVASCRIPT INTEGRATION"> for more details.

 my $javascript = MyJavascript->new();
 $table->setJavascript($javascript);

=cut

sub setJavascript {
  my $self = shift;
  my $javascript = shift;
  
  if (!$javascript->isa('HTML::EditableTable::Javascript')) { confess 'reference provided is not a derivative of HTML::EditableTable::Javascript'; }
  
  $self->{javascript} = $javascript;
}

=head2 htmlJavascriptDisplay (public, but normally called automatically)

Call it only if there is a need to control where javascript code is placed in the html.  Prints the <script> javascript code needed for the table.  The Javascript object determines the code required for the table.  Normally, this method is called automatically by EditableTable.  If a HTML::EditableTable::Javascript object does not exist at the time of execution, one will be created.  

 $table->htmlJavascriptDisplay();

=cut

sub htmlJavascriptDisplay {

  my $self = shift;

  # block repeated printing of javascript
  if (!$self->{javascriptDisplayed}) {
      
    # re-route STDOUT if called for
    my $stdout = undef;
    
    if ($self->{stringOutput} && !$self->{stdoutRerouted}) {
      
      open(TMPOUT, '>&', \*STDOUT) || confess "failed to save STDOUT";
      close STDOUT;
      open(STDOUT, '>', \$stdout) || confess "failed to reroute STDOUT to string";
      
      # set flag nested calls don't redo this
      $self->{stdoutRerouted} = 1;
    }
     
    # create a javascript object if one has not been provided by the user
    if (!$self->{javascript}) { 
      $self->{javascript} = HTML::EditableTable::Javascript->new($self);
    }
          
    $self->{javascript}->htmlDisplay();       
    $self->{javascriptDisplayed} = 1;
    
    # if stdout re-routed  
    if ($self->{stringOutput}) {
      open STDOUT, '>&', \*TMPOUT;
      close TMPOUT;
      
      $self->{stdoutRerouted} = 0;
    
      return $stdout;
    }
  }
}  

=head2 resetJavascriptDisplayed (public) {

Resets both the table javascriptDisplayed and Javascript javascriptDisplayCount flag to 0.  Use when you have a persistent server and blow away an html document with the generated code.

 $table->resetJavascriptDisplayed();

=cut

sub resetJavascriptDisplayed {

  my $self = shift @_;

  if ($self->{javascript}) {
    $self->{javascript}->resetJavascriptDisplayCount();
  }
  
  $self->{javacriptDisplayed} = 0;
}

=head2 checkBool (private)

Used to validate flag inputs.  1 and 'true' are accepted as positive inputs. 0 and 'false' for negative inputs.

=cut

sub checkBool {
  my $self = shift;
  my $val = shift;

  if ($val !~ /^1|true|0|false$/) { confess "value ($val) is a flag which must be set to 0, 1, 'true', or 'false'"; }
  if ($val eq 'false') { $val = 0; }
  elsif ($val eq 'true') { $val = 1; }
  
  return $val;
}
    
=head2 htmlAddDataSetup (private)

Used outside the table to create a <div> for the insertion of new table rows with javascript

=cut

sub htmlAddDataSetup {

  my $self = shift @_;
  my $tableFields = $self->{'tableFields'} || confess "missing table fields";
  
  my $tableId = $self->getTableId();
  
  print "<div name=readroot_$tableId id=readroot_$tableId style=\"display:none\">";

  foreach my $colSpec (@$tableFields) {

    next if (exists $colSpec->{'viewOnly'});

    # limited callback support

    if (exists $colSpec->{'callback'} && !$colSpec->{'dbfield'}) {

      my $fp = $colSpec->{'callback'};

      if (!$fp) { confess "no callback exists for $colSpec->{label}!"; }
      my $html = &$fp(undef, $colSpec);
      print "$html";
    }

    elsif (!exists $colSpec->{'formElement'}) {
      print "<input type=text disabled>";
    }

    my $formElm = $colSpec->{'formElement'};

    my $name = $colSpec->{'dbfield'};
    my $id = $colSpec->{'dbfield'};
    
    if (exists $colSpec->{'rowspanArrayKey'}) {
      $name = $colSpec->{'rowspanArrayKey'};
      $id = $colSpec->{'rowspanArrayKey'};	  
    }
    
    if (defined $formElm) {
      
      if ($formElm eq 'textfield') {
	print "<input type=textfield name='$name' id='$id'>";
	
      }
      elsif ($formElm eq 'textarea') {
	print "<textarea rows=3 cols=60 name='$name' id='$id'></textarea>";
      }
      elsif ($formElm eq 'popup') {
	
	if (exists $colSpec->{'selectionLabels'}) {
	  print popup_menu(-id=>$name, -name=>$name, -id=>$id, -values=>$colSpec->{'selectionList'}, -labels=>$colSpec->{'selectionLabels'}, -override=>1);
	}
	else {
	  print popup_menu(-id=>$name, -name=>$name, -id=>$id, -values=>$colSpec->{'selectionList'}, -override=>1);
	}
      }
      elsif ($formElm eq 'scrollingList') {
	
	my $selectionCount = scalar(@{$colSpec->{'selectionList'}});
	if ($selectionCount > 8) { $selectionCount = 8; }
	
	if (exists $colSpec->{'selectionLabels'}) {
	  print scrolling_list(-name=>$name, -id=>$id, -values=>$colSpec->{'selectionList'}, -labels=>$colSpec->{'selectionLabels'}, -override=>1, -size=>$selectionCount, -multiple=>'true');
	}
	else {
	  print scrolling_list(-name=>$name, -id=>$id, -values=>$colSpec->{'selectionList'}, -size=>$selectionCount, -multiple=>'true', -override=>1);
	}
      }
      elsif ($formElm eq 'deleteRowButton') {
	print "<input name='remove' id=remove type='button' value='remove' onClick=\"this.parentNode.parentNode.parentNode.removeChild(this.parentNode.parentNode);\">";
      }
      elsif($colSpec->{'formElement'} eq 'html5Calendar') {
	print "<input id='$id' name='$name' type=date/>";
      }
      elsif($colSpec->{'formElement'} eq 'checkbox') {

	my $checked = '';
	if ($colSpec->{'checkBehavior'} eq 'checked' ) { $checked = 'checked' }	
	print "<input type=checkbox name='$name' id='$id'  $checked/>";
      }
      
      # dynarch jscalendar-1.0 support
      
      elsif($colSpec->{'formElement'} eq 'calendar') {
	
	# script credit to www.dynarch.com
	
	my $spanText = 'Click here to add date';
	
	print "<div id=jscalsetup_$self->{tableId}>";
	print "<input type=\"hidden\" name=\"$name\" id=\"$id\"/>\n";
	print "<span style=\"background-color: \#fff; cursor: default;\"\n";
	
	print "onmouseover=\"this.style.backgroundColor='#eee';\"\n";
	print "onmouseout=\"this.style.backgroundColor='#fff';\"\n";
	print "id=\"showD_$name\"\n";
	print "><b>$spanText</b></span>";
	
	print "</div>";
      }
    }
  }    
  print "</div>";
}

##########################################################################
#  These methods are intended to be protected
##########################################################################

=head2 makeTable (abstract protected)

Method which must be provided by a class dervied from EditableTable. 

=cut

sub makeTable {

    my $self = shift @_;

    confess "cannot use the base class here - must use a derived class";
}

##########################################################################
#  These methods are intended to be private
##########################################################################

# used for the horizontal table case and vertical table case

=head2 getTableTagAttributes (private)

processes and returns a string of attributes for the top-level <table> tag

=cut

sub getTableTagAttributes {

    my $self = shift @_;

    my @tableAttributes = ();

    if (exists $self->{'border'}) {
	push @tableAttributes, "border='" . $self->{'border'} . "'";
    }
    else {
	push @tableAttributes, "border=1";
    }

    if (exists $self->{'width'}) {
	push @tableAttributes, "width='" . $self->{'width'} . "'";
    }

    if (exists $self->{'style'}) {
	push @tableAttributes, "style='" . $self->{'style'} . "'";
    }

    if (exists $self->{'jsAddData'}) {
	push @tableAttributes, "id=addData";
    }

    # 'sortable' is the class created by the embedded javascript
    if (exists $self->{'jsSortHeader'}) {
      push @tableAttributes, "class=sortable";
    }

    my $tableAttributes = join ' ', @tableAttributes;

    return $tableAttributes;
}

=head2 staticTableRow (private);

Generates an html table row.  Called by makeTable().

=cut

sub staticTableRow {

  my $self = shift @_;
  my $row = shift @_;
  my $spec = shift @_;  # this is passed in as vertical tables break up the spec to call this method
  my $rowspanSubcount = shift @_ || 0;   #Total number of subrows
  my $rowspanSubcounter = shift @_ || 0; #Current row index (0...N)

  if (ref($row) ne 'HASH') { confess "row is not a hash reference - are you calling Horizontal when data is set up for Vertical? (row = $row)"; }

  my $editMode = $self->{'editMode'};

  my $tabindex = undef;

  if (exists $self->{'tabindex'}) {
    $tabindex = ${$self->{'tabindex'}};
  }

  foreach my $colSpec (@$spec) {
    
    # skip if called for

    next if (exists $colSpec->{'viewOnly'} && $editMode eq 'edit');
    next if (exists $colSpec->{'editOnly'} && $editMode eq 'view');

    # basic cell value

    my $cellValue = undef;

    # calback case - value is determined dynamically from the row data, column params, and mode
    # note sometimes you want to suppress the callback in edit mode - ie, view mode callback is making link html

    if (exists $colSpec->{'callback'} && !($editMode eq 'edit' && exists $colSpec->{'suppressCallbackOnEdit'})) {

      my $fp = $colSpec->{'callback'};
      if (!$fp) { confess "no callback exists for $colSpec->{label}!"; }
      $cellValue = &$fp($row, $colSpec, $editMode, $rowspanSubcounter);

    }
    else {

      if (exists $colSpec->{'dbfield'}) {

	$cellValue = $row->{$colSpec->{'dbfield'}};
      }
      else {
	$cellValue = "<i>no value</i>";
      }

    }

    my @tdFormat;

    if (exists $colSpec->{'align'}) {
      push @tdFormat, "align=" . "'" . $colSpec=>{'align'} . "'";
    }
    if (exists $colSpec->{'width'}) {
      push @tdFormat, "width=" . "'" . $colSpec->{'width'} . "'";
    }

    if ($colSpec->{bgcolor}) {
      push @tdFormat, "bgcolor=" . "'" . $colSpec->{'bgcolor'} . "'";
    }

    # handle row spanning

    # write rowspan attribute on spanning tags if this is the first row
    # the suppress rowspan case is used when you have a table which has rowspanning on view but on edit provides edits for each row
    if ($editMode eq 'edit' && !$self->{'rowspannedEdit'} && $rowspanSubcount && exists($colSpec->{'rowspanArrayKey'})) {
      my $nestedData = $row->{$colSpec->{'dbfield'}}->[$rowspanSubcounter];

      # need to define a cell value here to avoid skipping a <td>
      $cellValue = $nestedData->{$colSpec->{'rowspanArrayKey'}} || "";
    }
    elsif ($editMode eq 'edit' && !$self->{'rowspannedEdit'} && $rowspanSubcount > 1) {

      # prevent the next;
    }

    elsif ($rowspanSubcount > 1 && $rowspanSubcounter == 0 && !exists($colSpec->{'rowspanArrayKey'})) {
      push @tdFormat, "rowspan='$rowspanSubcount'";
    }

    # else skip the <td> tags if this is a spanned over cell

    elsif ($rowspanSubcount > 1 && !exists($colSpec->{'rowspanArrayKey'})) {
      next;
    }

    elsif ($rowspanSubcount && exists($colSpec->{'rowspanArrayKey'})) {

      # callback may have already generated a cell value

      unless (exists $colSpec->{callback} && defined $cellValue) {
	# S.K.: Subrow i.e. nested row, for example, attributes of a tool, belonging to a flow
	# (that is 'row' in this notation)
	my $nestedData = $row->{$colSpec->{'dbfield'}}->[$rowspanSubcounter];
	# need to define a cell value here to avoid skipping a <td>
	$cellValue = $nestedData->{$colSpec->{'rowspanArrayKey'}} || "";

	# S.K. Additional useful possibilities to operate styles
	if (exists $colSpec->{'styleHandler'}) {
	  my $handler= $colSpec->{'styleHandler'};
	  if (!$handler) { confess join " : ", __FILE__, __LINE__, "Style handler does not exists"; }
	  my $styleAttribs= &$handler($nestedData);
	  push @tdFormat, "style=" . "\"" . $styleAttribs . "\"";
	} elsif (exists $colSpec->{'style'}) {
	  push @tdFormat, "style=" . "\"" . $colSpec->{'style'} . "\"";
	}
      }
    }
    elsif (!exists($colSpec->{'rowspanArrayKey'})) {
      # S.K. NOT FOR NESTED SUBROWS: Additional useful possibilities to operate styles
      if (exists $colSpec->{'styleHandler'}) {
	my $handler= $colSpec->{'styleHandler'};
	if (!$handler) { confess join " : ", __FILE__, __LINE__, "Style handler does not exists"; }
	my $styleAttribs= &$handler($row);
	push @tdFormat, "style=" . "\"" . $styleAttribs . "\"";
      } elsif (exists $colSpec->{'style'}) {
	push @tdFormat, "style=" . "\"" . $colSpec->{'style'} . "\"";
      }
    }
    
    # if now value, check for hardwired default	

    if (!defined($cellValue)) {
      if(exists($colSpec->{'default'})) {
	$cellValue = $colSpec->{'default'};
      }
    }
    
    my $tdFormat = join ' ', @tdFormat;

    # determine if mode will be changed for this column

    if (exists $colSpec->{'modeModifier'}) {
      my $fp = $colSpec->{'modeModifier'};
      if (!$fp) { confess join " : ", __FILE__, __LINE__, "mode modifier callback does not exists."; }
      $editMode = &$fp($editMode, $row);
    }

    if ($self->{'vtableFirstColumn'}) {

      if (!exists($colSpec->{'label'})) {
	print "<td>" . "<i>label missing</i>" . "</td>";
      }
      else {
	
	my $requiredMarker = '';
	
	if($editMode eq 'edit' && (exists($colSpec->{required}) && $colSpec->{required})) {
	  $requiredMarker = "<font color=#ff0000>*</font>";
	}
	
	if ($colSpec->{'tooltip'}) {

	  my $width = '';

	  if($colSpec->{sidebarWidth}) {		  
	    $width = "width=$colSpec->{sidebarWidth}'";
	  }

	  print "<td $width tooltip=\"" . $colSpec->{'tooltip'} . "\" onmouseover=\"Tooltip.schedule(this, event);\"><b>" . $requiredMarker . $colSpec->{'label'} . "</b>" . "<sup style='font-size:70%'><i>&#160;i</i></sup>" . "</td>";

	}
	else {
	  my $width = '';
	  
	  if($colSpec->{sidebarWidth}) {		  
	    $width = "width='$colSpec->{sidebarWidth}'";
	  }
	  
	  my $label = '';
	  if ($colSpec->{label}) { $label = $colSpec->{label}; }
	  
	  print "<td $width><b>" . $requiredMarker . $label . "</b></td>";
	}
      }

      # reset the flag
      $self->{'vtableFirstColumn'} = undef;
    }

    # we must have a cell value defined at this point

    if ($editMode eq 'edit' && exists $colSpec->{'formElement'}) {

      # sometimes we swap form elements if there is no value
      if (!$cellValue && exists ($colSpec->{formElementOnNull})) { $colSpec->{formElement} = $colSpec->{formElementOnNull}; }

      my $name = $colSpec->{'dbfield'};

      if (exists $colSpec->{'rowspanArrayKey'}) {
	$name = $colSpec->{'rowspanArrayKey'}
      }

      if (exists $colSpec->{'uniquifierField'}) {

	# maybe an array of unquifiers

	if (ref($colSpec->{'uniquifierField'})) {
	  foreach my $uniquifier (@{$colSpec->{'uniquifierField'}}) {
	    if (!exists $row->{$uniquifier}) { confess join ":", "field '$uniquifier' called for as a uniquifier but no value exists", __FILE__, __LINE__; }
	    $name .= '_' . $row->{$uniquifier};
	  }
	}
	else {
	  if (!exists $row->{$colSpec->{'uniquifierField'}}) { confess join ":", "field '$colSpec->{'uniquifierField'}' called for as a uniquifier but no value exists", __FILE__, __LINE__; }
	  $name .= '_' . $row->{$colSpec->{'uniquifierField'}};
	}

	# S.K.: Improvement
	if (ref($colSpec->{'rowspanArrayUniquifier'})) {
	  foreach my $rowspan_uniquifier (@{$colSpec->{'rowspanArrayUniquifier'}}) {
	    if (exists $colSpec->{'rowspanArrayKeyForUniquification'}) {
	      $name .= '_' . $row->{$colSpec->{'rowspanArrayKeyForUniquification'}}->[$rowspanSubcounter]->{$rowspan_uniquifier};
	    }
	    elsif (exists $colSpec->{'dbfield'}) {
	      $name .= '_' . $row->{$colSpec->{'dbfield'}}->[$rowspanSubcounter]->{$rowspan_uniquifier};
	    }
	    else {
	      confess join ":", "field '$rowspan_uniquifier' called for as a uniquifier but no value exists", __FILE__, __LINE__;
	    }
	  }
	}
	else {
	  if (exists $colSpec->{'rowspanArrayUniquifier'} && exists $colSpec->{'rowspanArrayKeyForUniquification'}) {
	    $name .= '_' . $row->{$colSpec->{'rowspanArrayKeyForUniquification'}}->[$rowspanSubcounter]->{$colSpec->{'rowspanArrayUniquifier'}};
	  }
	  elsif (exists $colSpec->{'rowspanArrayUniquifier'}) {
	    $name .= '_' . $row->{$colSpec->{'dbfield'}}->[$rowspanSubcounter]->{$colSpec->{'rowspanArrayUniquifier'}};
	  }
	}
      }

      if (exists $colSpec->{'masterCounterUniquify'}) {
	$name .= '_' . $self->{'masterCounter'}++;
      }

      if ($colSpec->{'formElement'} eq 'popup') {

	# we typically use a negative id for new data - sometimes we need to prevent edits on existing rows

	my $disabled = undef;

	if (exists $colSpec->{'editOnlyOnNegativeValue'} && $cellValue > 0) {
	  $disabled = 'DISABLED';
	}

	if (exists $colSpec->{'selectionListCallback'}) {
	  my $fp = $colSpec->{'selectionListCallback'};
	  my $selectionList = &$fp($row);
	  print "<td $tdFormat>" . popup_menu(-tabindex=>$tabindex, -id=>$name, -name=>$name, -values=>$selectionList, -default=>$cellValue, -override=>1) . "</td>";
	}
	elsif (exists $colSpec->{'selectionLabels'}) {
	  print "<td $tdFormat>";

	  # new version of firefox maybe? - undef disabled flag now results in disabled field??
	  if ($disabled) {
	    print popup_menu(-tabindex=>$tabindex, -disabled=>$disabled, -id=>$name, -name=>$name, -values=>$colSpec->{'selectionList'}, -labels=>$colSpec->{'selectionLabels'}, -default=>$cellValue, -override=>1);
	  }
	  else {
	    print popup_menu(-tabindex=>$tabindex, -id=>$name, -name=>$name, -values=>$colSpec->{'selectionList'}, -labels=>$colSpec->{'selectionLabels'}, -default=>$cellValue, -override=>1);
	  }
	  # disabled field will not submit

	  if ($disabled) {
	    print "<input type=hidden name=\"$name\" value=\"$cellValue\">";
	  }
	  print "</td>";
	}
	else {
	  print "<td $tdFormat>" . popup_menu(-tabindex=>$tabindex, -id=>$name, -name=>$name, -values=>$colSpec->{'selectionList'}, -default=>$cellValue, -override=>1) . "</td>";
	}
      }
      elsif ($colSpec->{'formElement'} eq 'scrollingList') {

	my $selectionCount = scalar(@{$colSpec->{'selectionList'}});
	if ($selectionCount > 8) { $selectionCount = 8; }

	# split apart a comma delmited list
	my @cellValues = split ',', $cellValue;

	if (exists $colSpec->{'selectionLabels'}) {

	  print "<td $tdFormat>", scrolling_list(-tabindex=>$tabindex, -id=>$name, -name=>$name, -values=>$colSpec->{'selectionList'}, -labels=>$colSpec->{'selectionLabels'}, -override=>1, -size=>$selectionCount, -multiple=>'true', -default=>[@cellValues]), "</td>";
	}
	else {
	  print "<td $tdFormat>", scrolling_list(-tabindex=>$tabindex, -id=>$name, -name=>$name, -values=>$colSpec->{'selectionList'}, -size=>$selectionCount, -multiple=>'true', -override=>1, -default=>[@cellValues]), "</td>";
	}
      }
      elsif ($colSpec->{'formElement'} eq 'textfield') {

	my $default = $cellValue || '';

	if ($colSpec->{'subBr'}) {
	  $default =~ s/\n/\<br\>/g;
	}
	elsif ($colSpec->{'subCommaForBr'}) {
	  $default =~ s/\<br\>/,/g;
	}

	my $size;

	if (exists $colSpec->{'size'}) {
	  $size = $colSpec->{'size'};
	}
	elsif (exists $colSpec->{'minimalEditSize'}) {
	  $size = length($default) * 1.2;
	  if ($size < 10) { $size = 15; }
	}
	else {
	  $size = length($default) * 2;
	  if ($size < 60) { $size = 40; }
	}
	my $maxlength = 255; # danger really need to check db metadata.
	if ($colSpec->{'maxlength'}) { $maxlength = $colSpec->{'maxlength'}; }
	print "<td $tdFormat>" . textfield(-tabindex=>$tabindex, -id=>$name, -name=>$name, -value=>"$default", -size=>$size, -maxlength=>$maxlength, -override=>1) . "</td>";
      }
      elsif ($colSpec->{'formElement'} eq 'textarea') {
	my $default = $cellValue;
	my $size = length($default) * 2;	      
	my $cols = 80;
	if ($colSpec->{minimalEditSize}) { $cols = 40; }
	my $rows = sprintf("%i", $size/80);
	if ($rows < 4) { $rows = 4; }
	print "<td $tdFormat>" . textarea(-tabindex=>$tabindex, -id=>$name, -name=>$name, -cols=>$cols, -rows=>$rows, -value=>$default, -override=>1) . "</td>";
      }
      elsif ($colSpec->{'formElement'} eq 'checkbox') {
	my $default = $cellValue;

	my $checked = '';
	
	if ($colSpec->{checkBehavior} eq 'checkedOnVal') {
	  if ($default) { $checked = 'checked' }
	}
	elsif($colSpec->{checkBehavior} eq 'checkedOnTrue') {
	  if ($default =~ /^1|yes|true$/i) { $checked = 'checked' }
	}
	elsif ($colSpec->{checkBehavior} eq 'checked') {
	  $checked = 'checked';
	}
	elsif($colSpec->{checkBehavior}) {
	  confess ("$colSpec->{checkBehavior} is not a valid value (checkedOnVal, checkedOnTrue, checked)");
	}

	if ($default) {
	  print "<td $tdFormat>" . "<input type=checkbox name=\"$name\" id=\"$name\" value=\"$default\" $checked>" . "</td>";
	}
	else {
	  print "<td $tdFormat>" . "<input type=checkbox name=\"$name\" id=\"$name\" value=\"$name\" $checked>" . "</td>";
	}

      }
      elsif($colSpec->{'formElement'} eq 'hidden') {

	print "<td $tdFormat>";
	print hidden(-id=>$name, -name=>$name, -id=>$name, -value=>$cellValue);
	print $cellValue;
	print "</td>";
      }

      # depends on the calendar being loaded in the header

      elsif($colSpec->{'formElement'} eq 'html5Calendar') {
	print "<td $tdFormat>";
	print "<input id=\"$name\" name=\"$name\" type=date value=\"$cellValue\"/>";
	print "</td>";
      }

      # dynarch jscalendar-1.0 support

      elsif($colSpec->{'formElement'} eq 'calendar') {

	# script credit to www.dynarch.com

	my $spanText;

	if ($cellValue) {
	  $spanText = $cellValue;
	}
	else {
	  $cellValue = '';
	  $spanText = 'Click here to add date';
	}

	print "<td $tdFormat>";

	print "<input type=\"hidden\" name=\"$name\" id=\"$name\" value=\"$cellValue\"/>\n";
	print "<span style=\"background-color: \#fff; cursor: default;\"\n";

	print "onmouseover=\"this.style.backgroundColor='#eee';\"\n";
	print "onmouseout=\"this.style.backgroundColor='#fff';\"\n";
	print "id=\"showD_$name\"\n";
	print "><b>$spanText</b></span>\n";

	print "<script type=\"text/javascript\">\n";
	print "Calendar.setup({\n";
	print "inputField     :    \"$name\",\n";
	print "ifFormat       :    \"%Y-%m-%d\",\n";
	print "displayArea    :    \"showD_$name\",\n";
	print "daFormat       :    \"%Y-%m-%d\",\n";
	print "cache          :    true\n";
	print "});\n";
	print "</script>\n";

	print "</td>";

      }
      elsif ($colSpec->{'formElement'} eq 'deleteRowButton') {
	print "<td $tdFormat>";
	print "<input name='remove' id=remove type='button' value='remove' onClick=\"this.parentNode.parentNode.parentNode.removeChild(this.parentNode.parentNode);\">";
	print "</td>";
      }
      else {
	confess join ":", "Unknown form element ($colSpec->{'formElement'})!", __FILE__, __LINE__;
      }
    }
    elsif (exists $colSpec->{'htmlSub'}) {
      my $html = $colSpec->{'htmlSub'};
      $html =~ s/<$colSpec->{'dbfield'}>/$cellValue/g;
      print "<td $tdFormat>" . $html . "</td>";
    }
    else {

      my $name;
      # if we have a list and labels for a popup, assume the provided value is an index to the label;

      if (exists $colSpec->{'selectionList'} && exists $colSpec->{'selectionLabels'}) {

	print "<td $tdFormat>" . $colSpec->{'selectionLabels'}->{$cellValue} . "</td>";
      }
      else {

	# sometimes we want to substitue <br> for newlines

	my $content = $cellValue;

	if ($colSpec->{'subBr'}) {
	  $content =~ s/\n/\<br\>/g;
	}

	# if the content is short is short enough an contains thinks that looks like links, convert them to links

	if ($colSpec->{'linkifyContentOnView'}) {

	  (my @links) = $content =~ /(http\:\/\/\S+)/g;
	  foreach my $link (@links) { 
	    
	    # escape $link
	    $link =~ s/\//\\\//g;
	    $link =~ s/\?/\\\?/g;
	    
	    $content =~ s/($link)/\<a href=\"$1\"\>$1\<\/a\>/;
	  }
	}
	
	# sometimes we want to substitue <br> for newlines
	if ($colSpec->{'subBr'}) {
	  $content =~ s/\n/\<br\>/g;
	}

	# some large text displays are truncated or provided with expandable links

	if ($colSpec->{'drillDownTruncate'} && length($content) > $colSpec->{'drillDownTruncate'}) {

	  (my $truncatedContent) = $content =~ /(.{0,$colSpec->{'drillDownTruncate'}})/;
	  $truncatedContent .= "...<input type=button style=\"font-size:65%;\" value=more>";

	  my $tdUid = $self->{'elementUid'}++;
	  my $divUid = $self->{'elementUid'}++;
	  my $truncatedDivUid = $self->{'elementUid'}++;
	  my $aUid = $self->{'elementUid'}++;

	  print "<td $tdFormat id=$tdUid>" . "<div style=text-decoration:none id=$aUid href=\"javascript:void(0)\" onclick=\"expandText($aUid, $divUid, $truncatedDivUid);\">" . $truncatedContent . "</div>" . "<div id=$divUid style=display:none>$content</div><div id=$truncatedDivUid style=display:none>$truncatedContent</div>" . "</td>";
	}

	else {
	  
	  if (!defined($content)) { $content = ''; }
	  
	  print "<td $tdFormat>" . $content . "</td>";
	}
      }
    }    
  }
}

=head1 TABLE FIELD PARAMETERS

=head2 dbfield (frequent)

Specifies the data hash key for provided data for the table element.  Also Specifies the form element base name that will be used.  Typically, this is also a database field name.

 'dbfield' => part_id

=head2 label (frequent)

Specifies the table column header for horizontal tables and the first colum for vertical tables.
 
 'label' => 'Part Id#'   


=head2 formElement (frequent)

formElement specifies the html input field that will be used when the table is in 'edit' mode.  Valid values are

=over

=item *

calendar - Implements popup calendar using www.dynarch.com jscalendar 1.0.  Requires this javascript library to be accessible.  See L</"JAVASCRIPT INTEGRATION"> for details.

=item *

checkbox - Implements checkbox html element

=item *

deleteRowButton - Combine with jsAddRow Table-level feature.  Provides button to delete a table row.

=item *

html5Calendar - Alternative to calendar.  Implements HTML5 'date' input type.  Tested with Opera, which is the only browser supporting this HTML5 input as of this writing. 

=item *

hidden - Implements hidden element type.

=item *

popup - implements CGI "poup"

=item *

scrollingList - implments CGI "scrolling_list"

=item *

textarea - implements textarea HTML element

=item *

textfield - implements html input of type 'text'

=back

 'formElement' => 'checkbox'

=head2 selectionList (frequent)

An array reference to a list of values to display in a popup or scrollingList

 'selectionList' => [ '34GXT', '35TTG', '56YUG' ]

=head2 selectionLabels (frequent)

A hash reference to labels and values to present in a popup or scrollingList.  The keys are displayed while the values are provided in the form.

 'selectionLabels' => { '34GXT' => 'Big Widget', '35TTG' => 'Medium Widget', '56YUG' => 'Small Widget' }

=head2 editOnly (frequent)

Don't display this field when the table is in 'view' mode.    

 'editOnly' => 1

=head2 viewOnly (frequent)

Don't display this field when the table is in 'edit' mode.

 'viewOnly' => 1

=head2 default (frequent)

Provides default value for form elements when no value is present in the data 

 'default' => 'UX56SG'

=head2 uniquifierField (frequent)

Sets the field whose 'dbfield' value is used to provide a unique name and id to other form elements in the same array (row or column, depending on the implementation) of data.  This is done by appending an '_' and then the value of the specified dbfield. Typically, the 'dbfield' is a database table's unique 'id' field.

 my @tableFields = (
 {
  'dbfield' => 'part_id'
 }
 {
  'dbfield' => 'description',  
  'uniquifierField' => 'part_id'
  'formElement' => 'textfield',  
 }
 );

with data
  
 my @data = (
 'part_id' => 1234
  )

will produce
 
 <input type=text id='description_1234' name='description_1234'> 

This field can also be an arrayref to a list of fields.  The values of each will be joined with '_' characters to create the field name and id.

=head2 drillDownTruncate (occasional)

Implements a javascript which truncates the text and provides a toggle to switch between full and truncated text.  The value sets the number of characters which are displayed in 'truncated' mode.

 'drillDownTruncate' => 100

=head2 callback (occasional)

Provides a mechanism to process data with a custom function or method prior to display.  Typically used for custom formatting, setting table values based on other values, or 'child' database queries.

 'callback' => &callbackFunction

 sub callbackFunction {}

or

 'callback' => $self->callbackClosure()

 sub callbackClosure {

   my $fp = function {
     # need the object to do something at callback time
     $self->doSomething()
   };

   return $fp;
 }

The callback interface is as follows
  
 &$fp(
      $row, # hashref to the current row of data
      $fieldParams, # hashref to the current field parameters
      $editMode,  # table mode - 'view' or 'edit'
      $rowspanSubcounter # used only for tables using rowspanning, provides rowspan count for current rowspan instance 
     );


=head2 checkBehavior (occasional)

Determines how checkboxes will behave when toggling between view and edit modes.  Valid values are 'checked', 'checkedOnVal', and checkedOnTrue'.  The later value will result in the checkbox being checked if the data value matches the pattern /^1|true|yes$/i

 'checkBehavior' => 'checkedOnTrue'

=head2 suppressCallbackOnEdit (occasional)

Prevents the call to the callback when the table is in 'edit' mode

 'suppressCallbackOnEdit' => 1

=head2 subBr (occasional)

Sometimes used to sub <br> tags for \n when presenting text data.  Common use case is when a user cut and pastes an email into a textarea.  In 'view' mode, 'subBr' will keep the email's formatting

=head2 style (occasional)

Used to provide a css style to the <td> element used to present a data value.  This parameter can be used in lieu of several others - align, bgcolor

 'style' => "font-family:'Times New Roman';font-size:20px;"

=head2 align (occasional)

Sets the horizontal 'align' <td> html parameter.  Valid values are 'left', 'right', and 'center'.

 'align' => 'center'

=head2 width (occasional)

Sets the desired column width in pixels. Sets the <td> 'width' parameter.

 'width' => 70

=head2 size (occasional)

Sets a textfield input tags 'size' parameter for the number of displayed characters.  Applicable only in 'edit' mode.  See also maxLength.

 'size' => 60

=head2 maxLength (occasional)

For a textfield input tag, sets the maximum number of characters which can be input.  Sets the 'maxLength' html tag parameter.  This defaults to 255 if no value is provided, the reasoning being the most textfields are mapped to a VARCHAR database datatype with a 255 char limit.

 'maxLength' => 64

=head2 tooltip (occasional)

Implements javascript to provide mouseover tooltips.  The value sets the text to be displayed.  See the L</"JAVASCRIPT INTEGRATION"> section for details.

 'tooltip' => 'The master PDM part number'

=head2 linkifyContentOnView (occasional)

For text data, this feature creates matching hyperlinks out of any text beginning with "http://".  This is not done in 'edit' mode.

 'linkifyContentOnView' => 1

=head2 subCommaForBr (rare)

For'poorly' normalized data presentation where a <br> tag is preferable to a ',' in text display

 'subCommaForBr' => 1

=head2 jsClearColumnOnEdit (rare)

For horizontal tables only. Provides a 'clear column' button in the column header to clear text from all fields in the column when the table is in 'edit' mode. 

   'jsClearColumnOnEdit' => 1,

=head2 minimalEditSize (rare)

In table 'edit' mode, the default textfield width is 2X the value with a minimum value of 60 char.  If 'minimalEditSize' is set, this reduces to 1.2X the value with a minium value of 15.  In large tables, minimalEditSize helps keep the presentation clean.

 'minimalEditSize' => 1

=head2 bgcolor (rare)

Sets the background color of cell be setting the 'bgcolor' <td> parameter

 'bgcolor' => '#ff0000'

=head2 rowspanArrayKey (rare)

Rowspanning is sometimes done by creators of spreadsheets that are to be converted to web applications.  The data for these cases is a hierarchical array of hashrefs.  This parameter provides the name of the second level hash key which contains the nested data to be rowspanned.  The 'dbfield' parameter is used to specify the top level key to the second level of data to be rowspanned.

 @rowspannedData = (
     {
       'part_id' => 'UX34GT',
       'sub_data' => [
                       {
                        'sub_assembly_name' => '34R',
                       },
                       {
                        'sub_assembly_name' => '23D',
                       }
                     ]
     },
     {
       'part_id' => 'RT67IV',
       'sub_data' => [
                       {
                        'sub_assembly_name' => '14G',
                       },
                       {
                        'sub_assembly_name' => '13R',
                       }
                     ]
      }
 );

 @tableFields = (
   {
    'dbfield' => 'part_id',
    'label' => 'Part ID#'
   },
   {
    'dbfield' => 'sub_data',
    'rowspanArrayKey' => 'sub_assembly_name',
    'label' => 'Part Sub-Assembly',
   }
 );

 will produce at table like this

 ---------------------------------
 | Part ID#  | Part Sub-Assembly |
 |-------------------------------|
 |           |        34R        |
 | UX34GT    |-------------------|
 |           |        23D        |
 |-------------------------------|
 |           |        14G        |
 | RT67IV    |-------------------|
 |           |        13R        |
 ---------------------------------

In 'edit' mode, the table is flattened to support row addition and deletion.

=head2 rowspanArrayUniquifier (rare)

For rowspanning tables. In 'edit' mode, it is critical to produce a traceable field id for elements that are rowspanned.  The most simple way to do this is by specifing this parameter to be a member of the nested rowspanned data.  Working from the previous example:

 @tableFields = (
   {
    'dbfield' => 'part_id',
    'label' => 'Part ID#'
   },
   {
    'dbfield' => 'sub_data',
    'rowspanArrayKey' => 'sub_assembly_name',
    'label' => 'Part Sub-Assembly',
    'rowspanArrayUniquifier' => 'sub_assembly_name'
   }
 );

 produces a table with the following unique id's in 'edit' mode.  Note the flattening of the table in 'edit' mode.  If this is not desired set the table-level flag 'rowspannedEdit'.

 -------------------------------------------------------
 | Part ID# |             Part Sub-Assembly            |
 |----------|------------------------------------------|
 |  UX34GT  |        34R (sub_assembly_name_34R)       |
 |----------|------------------------------------------|
 |  UX34GT  |        23D (sub_assembly_name_23D)       |
 |----------|------------------------------------------|
 |  RT67IV  |        14G (sub_assembly_name_14G        |
 |----------|------------------------------------------|
 |  RT67IV  |        13R (sub_assembly_name_13R)       |
 -------------------------------------------------------

This parameter can be combined with uniquifierField to produce a expanded unique id.  This is handy when the rowspanned data cannot produce a unique field id or a binding relationship needs to be maintained. 

 @tableFields = (
   {
    'dbfield' => 'part_id',
    'label' => 'Part ID#'
    'uniquifierField' => 'part_id'
   },
   {
    'dbfield' => 'sub_data',
    'rowspanArrayKey' => 'sub_assembly_name',
    'label' => 'Part Sub-Assembly',
    'uniquifierField' => part_id,
    'rowspanArrayUniquifier' => 'sub_assembly_name'
   }
 );

 produces a table with the following unique id's in 'edit' mode.  Note the flattening of the table in 'edit' mode.  If this is not desired set the table-level param 'rowspannedEdit'.

 -----------------------------------------------------------------------------
 | Part ID#                |                Part Sub-Assembly                |
 |-------------------------|-------------------------------------------------|
 | UX34GT (part_id_UX34GT) |        34R (sub_assembly_name_UX34G_34R)        |
 |-------------------------|-------------------------------------------------|
 | UX34GT (part_id_UX34GT) |        23D (sub_assembly_name_UX34GT_23D)       |
 |-------------------------|-------------------------------------------------|
 | RT67IV (part_id_RT67IV) |        14G (sub_assembly_name_RT67IV_14G)       |
 |-------------------------|-------------------------------------------------|
 | RT67IV (part_id_RT67IV) |        13R (sub_assembly_name_RT67IV_13R)       |
 -----------------------------------------------------------------------------


This parameter can also be arrayref to a list of second-level data keys if additional keys are required to acheive a unique name.  For example


=head2 rowspanArrayKeyForUniquification (rare)

When rowspanned tables are switched to 'edit' mode, the table is flattened to provide the ability to change the relationships which create the spanning.  To provide traceability for the fields which span, combine this parameter with rowspanArrayUniquifier (described above) to specify the first and second level keys of the data hierarchy to used for field name and id construction.

given data

 @tableFields = (
   {
    'dbfield' => 'part_id',
    'label' => 'Part ID#'
    'uniquifierField' => 'part_id',
    'rowspanArrayKeyforUniquification' => 'sub_data',
    'rowspanArrayUniquifier' => 'sub_assembly_name'
   },
   {
    'dbfield' => 'sub_data',
    'rowspanArrayKey' => 'sub_assembly_name',
    'label' => 'Part Sub-Assembly',
    'uniquifierField' => part_id,
    'rowspanArrayUniquifier' => 'sub_assembly_name'
   }
 );

 produces a table with the following unique id's in 'edit' mode.  Note the flattening of the table in 'edit' mode.  If this is not desired set the table-level param 'rowspannedEdit'.

 ---------------------------------------------------------------------------------
 | Part ID#                    |                Part Sub-Assembly                |
 |-----------------------------|-------------------------------------------------|
 | UX34GT (part_id_UX34GT_34R) |        34R (sub_assembly_name_UX34G_34R)        |
 |-----------------------------|-------------------------------------------------|
 | UX34GT (part_id_UX34GT_23D) |        23D (sub_assembly_name_UX34GT_23D)       |
 |-----------------------------|-------------------------------------------------|
 | RT67IV (part_id_RT67IV_14G) |        14G (sub_assembly_name_RT67IV_14G)       |
 |-----------------------------|-------------------------------------------------|
 | RT67IV (part_id_RT67IV_13R) |        13R (sub_assembly_name_RT67IV_13R)       |
 ---------------------------------------------------------------------------------

=head2 masterCounterUniquify (rare)

The final field name and id generation parameter.  If specified, uses the 'class static' field counter to append a final id to the field name.  Useful when adding rows of new data to a table where this is needed to ensure a unique id is created.

given data

 @tableFields = (
   {
    'dbfield' => 'part_id',
    'label' => 'Part ID#'
   },
   {
    'dbfield' => 'sub_data',
    'rowspanArrayKey' => 'sub_assembly_name',
    'label' => 'Part Sub-Assembly',
    'masterCounterUniquify' => 1
   }
 );

 produces a table with the following unique id's in 'edit' mode.  Note the flattening of the table in 'edit' mode.  If this is not desired set the table-level param 'rowspannedEdit'.

 ------------------------------------------------------
 | Part ID# |                Part Sub-Assembly        |
 |----------|-----------------------------------------|
 | UX34GT   |        34R (sub_assembly_name_1)        |
 |----------|-----------------------------------------|
 | UX34GT   |        23D (sub_assembly_name_2)        |
 |----------|-----------------------------------------|
 | RT67IV   |        14G (sub_assembly_name_3)        |
 |----------|-----------------------------------------|
 | RT67IV   |        13R (sub_assembly_name_4)        |
 ------------------------------------------------------

=head2 styleHandler (rare)

Callback mechanism to provide a style for the <td> tag.

 'styleHandler' => &getStyle

The interface for the callback is

 &getStyle(
   $row # hashref to the current data set 
 ) 

=head2 modeModifier (rare)

Provides a callback mechanism to determine if the mode ('view' or 'edit') should be changed for this field only

 'modeModifer' => &getMode

The interface for this callback is as follows:

 &getMode (
    $editMode, # 'view' or 'edit'
    $data # hashref to the current dataset (row or column, depending on table type)
 )

The callback must return 'view' or 'edit'.

=head2 editOnlyOnNegativeValue (rare)
 
Use this feature when it is desired to prevent editing on existing data and only allow edting of new data where the value is <0

 'editOnlyOnNegativeValue' => 1,

=head2 selectionListCallback (rare)

Specifies a callback to produce a value list for a popup or scrollingList element.  Useful when a dynamic query or calculation must be made.

 'selectionListCallback' => &getListValues

The interface for this call back is as follows:

 &getListValues (
   $dataSet # current row or column data hashref
 );

The callback must provide an arrayref of values. 

=head2 htmlSub (rare)

provides a simple mechanism to substitute the current field's value into a string template

 'htmlSub' => "http://www.site.com?value=<dbfield>"

The '<dbfield>' text will be replaced by the current dataset's $data->{dbfield}

=head1 JAVASCRIPT INTEGRATION

=head2 Overview

The javascript features are encapsulated in HTML::EditableTable::Javascript.  Each method provided by this class provides a distinct javascript feature, allowing for clean override or extension. The intent is to provide all javascript functionality "under the hood" via table and table-field parameter setting.  If not specified by the user, the Javascript object is created by the table.  This leads to the the javascript <script> tags being inserted with the table.  Only the code needed for the specified table functionality is generated.

To use a custom javascript class, call setJavascript() prior to htmlDisplay() or  htmlJavascriptDisplay().  Note that the Javascript object requires a reference to the parent table so it must be created after the table.

Inherit from the HTML::EditableTable::Javascript class to extend or override javascript code generation.
                                                                                                                                                                   
 package MyNewJavascript {                                                                                                                                          
 @ISA = qw(HTML::EditableTable::Javascript);                                                                                                                        
   # new code
 }
 1;                                                                                                                                                                 

 my $table = HTML::EditableTable::Vertical->new(); 

 my $customJavascript = MyNewJavascript->new($table);                                                                                                               
 $table->setJavascript($customJavascript);                                                                                                                          

The functionality provided through javascript are described below:

=head2 Table Sorting

Client-side table sorting is implemented using Stuart Langridge's SortTable Version 2: http://www.kryogenix.org/code/browser/sorttable/  See L</"SORTING"> for more details on this and other table sorting options.  To use this feature set the 'jsSortHeader' table level parameter:

 $table->setJsSortHeader(1);

=head2 Click-to-Expand Text

This feature truncates text to the specified number of characters by default and provides a "more" button to display the full text.  A click on the full text returns the cell to its truncated state.  This feature is useful when the full text consumes a lot of screen real estate.  To use this feature, set the 'drillDownTruncate' table field parameter to the number of characters to display in truncated mode:

 my $tableField = 
      {
       'dbfield' => 'description',
       'label' => 'Part Description',
       'drillDownTruncate' => 60,
     };

=head2 Mousover Tooltips

The mouseover tooltip feature is provided using javascript from David Flanagan's Javascript, The Definitive Guide.  To use this feature set the table field 'tooltip' parameter:

 my $tableField = 
      {
       'dbfield' => 'description',
       'label' => 'Part Description',
       'tooltip' => 'Description to be displayed in catalog.'
     };


=head2 Add and Delete Table Rows

Client-side row addition and deletion is provided by javascript.  When this feature is used, a <div> tag with a row template is written when htmlDisplay() is called.  For row additions, sequential negative integers are used to provide unique identifiers to new form elements.  For the following table field specification:

  @tableFields = (
   {
    'dbfield' => 'part_id',
    'label' => 'Part ID#'
    'formElement' => 'textField'
   },
   {
    'dbfield' => 'sub_data',
    'label' => 'Part Sub-Assembly',
    'formElement' => 'textField'
   }
 );

The first dynamically added row will have input field ids as follows:

 <input id="part_id_-1" type="textfield"/>
 <input id="sub_data_-1" type="textfield"/>

To use this feature, set the table-level parameter 'jsAddData':

 $table->jsAddData(1);

To provide a means to delete an added row, specify a table field with the following parameters:

 my $tableField = {
    'editOnly' => 1,
    'formElement' => 'deleteRowButton'
 }

=head2 Calendar Input Widget

Date entry is very common in the target applications of EditableTable.  A formElement of type 'calendar' is provided by impementing dynarch.com's jscalendar-1.0 widget.  The jscalendar library must be available to the webserver.  The default directory is "./jscalendar", though this can be changed by setting the table-level parameter setCalendarDir.   The calendar UI is implemented as clickable text which pops up the calendar widget.  If no data value is present, "Click here to add date" is displayed.  The Calendar setup is called with the following settings.

 Calendar.setup(
   inputField     :    $name,
   ifFormat       :    "%Y-%m-%d",
   displayArea    :    "showD_$name",
   daFormat       :    "%Y-%m-%d",
   cache          :    true
 )

To provide a jscalendar input, use the formElement type 'calendar',

 my $tablField = {
  'dbfield' => 'addition_date',
  'label' => 'Available From',
  'formElement' => 'calendar',
 },

Note also that html5 provides a (much appreciated) date entry input type.  This is supported by using the formElement type 'html5calendar'.  As of this writing only Opera supported this html5 feature, however, so the jscalendar integration will be useful for some time. 

=head1 SORTING

There are four techniques available to sort HTML::EditableTable::Horizontal tables and one for multi-column HTML::EditableTable::Vertical.  Each is described below along with examples.

=head2 Server-side by user

Typically used when the data for the table are presorted by SQL or in pre-processing.  In this case, set the sortHeader url, which will call the cgi script with the appropriate column field value.  The user is responsible for interpreting the cgi parameters and providing sorted data.  Server side sorting is suitable for situations where the size of the html document and it's DOM challenge the browser's available RAM.

EditableTable appends 'orderByAsc=<dbfield>' or 'orderByDesc=<dbfield>' to the url set in the call to sortHeader(), so the url must be constructed by the user in anticipation of this.  When the table is first displayed, the parameter 'orderByAsc' is appended.  Subsequent clicks on the header toggle the appended paramter between 'orderbyDesc' and 'orderByAsc', providing for a reversible sort.

 $table->sortHeader("http://myscript.cgi?context=edit&");

An examle url attached to each column header by EditableTable is "http://myscript.cgi?context=edit&sortby=partId".

a simplified example of the server cgi code implementing the sort:

 my $t = CGI->new();
 my $sortby = $t->param('orderByAsc');
 my $sql = "select * from table order by $sortby";

=head2 Server-side by EditableTable

Reversible data sorting is handled by the EditableTable object.  The user only needs to provide a value for sortHeader and set sortData to 1 - no additional server-side work is needed.  This technique will sort rowspanned tables.

 $table->sortHeader("http://myscript.cgi?context=edit&");
 $table->sortData(1);

=head2 Server-side by setting sortKeys

This technique is appropriate for hash-of-hashes data structures in both Horizontal and multi-column Vertical tables.  In this case, the user provides an arrayref to the sorted keys.   Horizontal tables are sorted top-to-bottom in array order and multi-column Vertical tables left-to-right.  For other types of tables the sortOrder is ignored.

 $table->setSortOrder( ['UX45TG', 'HU78OO', 'UV01TT'] );

=head2 Client-side by javascript

This technique implements client-side javascript to provide reversible sorting without calling the cgi.  It does not currently work with rowspanning tables.  The user need only set jsSortHeader to enable this functionality.

 $table->setJsSortHeader(1);

=head1 OTHER EXAMPLES

There are several examples provided in the 'example' directory in the module distribution.  These examples also comprise the test case suite for this module.

=head1 AUTHOR

This code is provided courtesy of Freescale Semicondutor.  The developers are

Andy Espenscheid C<< <espenshovel@gmail.com> >>

Sergei Kondratiev

Vishesh Kumar

Vijay Yadav

Mike Boatright

=head1 BUGS & POTENTIAL ISSUES

=over

=item *

The table method setTitle does not work with Horizontal tables.  It conflicts with the javascript client-side sorting implmentation so it was disabled.

=item * 

The javascript-based sorting with rowspanned tables does not work well

=item * 

No development or testing was done with mod-perl.  There are a few class static variables which may cause trouble.

=item *

There are places where Carp's confess() is used where carp() may be more appropriate.  We tended to err on the side of 'throw exception first deal with the support calls later'

=item *

Combining 'rowspannedEdit' with a 'deleteRowButton' column doesn't work.  This may be fixed in a future patch.

=back

Please report any bugs or feature requests to C<bug-html-editabletable at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-EditableTable>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTML::EditableTable


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-EditableTable>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTML-EditableTable>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTML-EditableTable>

=item * Search CPAN

L<http://search.cpan.org/dist/HTML-EditableTable/>

=back

=head1 ACKNOWLEDGEMENTS

The authors would like to acknowledge Dave Benoit, David Corley, Lydia Hultquist, and Patti Rankin at Freescale Semicondutor.

=head1 COPYRIGHT & LICENSE

Copyright 2010 Freescale Semiconductor, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of HTML::EditableTable
