use 5.20.0;            # because this is the first perl version with hash slices
package Excel::PowerPivot::Utils;
use utf8;
use Moose;
use Win32::OLE         qw/in/;
use Scalar::Does       qw/does/;
use List::Util         qw/all/;
use Log::Dispatch;
use POSIX              qw/strftime/;


#======================================================================
# GLOBALS
#======================================================================

our $VERSION = '0.1';

use constant {
  True                 => 1,
  False                => 0,
  xlCmdTableCollection => 6, # see https://learn.microsoft.com/en-us/office/vba/api/excel.xlcmdtype
};

my %ModelFormat_properties = ( # see https://learn.microsoft.com/en-us/office/vba/api/excel.model
  Currency             => [qw/Symbol DecimalPlaces/],
  Date                 => [qw/FormatString/],
  DecimalNumber        => [qw/UseThousandSeparator DecimalPlaces/],
  General              => [],
  PercentageNumber     => [qw/UseThousandSeparator DecimalPlaces/],
  ScientificNumber     => [qw/DecimalPlaces/],
  WholeNumber          => [qw/UseThousandSeparator/],
 );


my $YAML_separator_line = '#' . '='x70;

#======================================================================
# ATTRIBUTES AND THEIR BUILDERS
#======================================================================

has 'workbook' => (is => 'ro', lazy => True, builder => '_default_workbook');
has 'log'      => (is => 'ro', lazy => True, builder => '_default_logger');


sub _default_workbook  {
  my $xl  = Win32::OLE->GetActiveObject("Excel.Application")
    or die "cannot connect to an Excel instance";
  my $wb  = $xl->ActiveWorkbook
    or die "Excel application has no active workbook";
  return $wb;
}


sub _default_logger {
  Log::Dispatch->new(outputs   => [[ 'Screen', min_level => 'debug' ]],
                     callbacks => sub {
                       my %h = @_; 
                       my $now = strftime "%Y.%m.%d %H:%M:%S", localtime;
                       return "[$now $h{level}] $h{message}\n";
                     });
}




#======================================================================
# UTILS FOR POWER PIVOT DAX MEASURES
#======================================================================


sub measures {
  my ($self) = @_;

  my $excel_model = $self->workbook->Model;

  my @measures;
  for my $wb_measure (in $excel_model->ModelMeasures) {
    my %measure = (
      Name            => $wb_measure->Name,
      AssociatedTable => $wb_measure->AssociatedTable->Name,
      Formula         => $wb_measure->Formula,
      Description     => $wb_measure->Description,
     );

    if (my $format_obj  = $wb_measure->FormatInformation) {
      my $format_class = Win32::OLE->QueryObjectType($format_obj) =~ s/^ModelFormat//r;
      my @property_values;
      for my $format_property ($ModelFormat_properties{$format_class}->@*) {
        push @property_values, $format_obj->{$format_property};
      }
      $measure{FormatInformation} = [$format_class, @property_values];
    }
    push @measures, \%measure;
  }

  return @measures;
}

sub measures_as_YAML {
  my ($self) = @_;

  # ad hoc YAML dump instead of YAML::Dump -- for a nicer formatting, easily readable by humans
  my $yaml = "";

  foreach my $measure ($self->measures) {

    # measure formats are expressed as : [$classname, @args]
    my $format_info   = $measure->{FormatInformation} // [];
    my $format_string = sprintf "[%s]", join ", ", map {$_ // '~'} @$format_info;

    $yaml .= "\n\n$YAML_separator_line\n"
          .  "- Name              : $measure->{Name}\n"
          .  "$YAML_separator_line\n"
          .  "  AssociatedTable   : $measure->{AssociatedTable}\n"
          .  "  Description       : $measure->{Description}\n"
          .  "  FormatInformation : $format_string\n"
          .  "  Formula           : |-\n"
          .  $measure->{Formula} =~ s/^/    /gmr;
  }

  return $yaml;
}


sub inject_measures {
  my ($self, $measures_to_inject, %options) = @_;

  # check options
  warn "->inject_measures(..) : option '$_' is invalid"
    foreach invalid_options(\%options, qw/delete_others dont_refresh_pivots/);

  # default options
  $options{dont_refresh_pivots} //= True;

  # check well-formedness of $measures_to_inject
  does $measures_to_inject, 'ARRAY'
    or die "parameter to inject_measures() is not an arrayref";
  all {has_nonempty_keys(qw/Name AssociatedTable Formula/)->($_)} @$measures_to_inject
    or die "missing mandatory properties in parameter to ->inject_measures()";

  # deactivate refresh in pivot caches
  my @refreshable_pivots;
  if ($options{dont_refresh_pivots}) {
    $self->log->debug("deactivate refresh in pivot caches");
    @refreshable_pivots = grep {$_->{EnableRefresh}} in $self->workbook->PivotCaches;
    $_->{EnableRefresh} = 0 foreach @refreshable_pivots;
  }

  # gather measures already existing in the Excel model
  $self->log->info("gathering measures from the existing Excel model");
  my %existing_measures = map {($_->Name => $_)} in $self->workbook->Model->ModelMeasures;

  # handle each measure to inject
  foreach my $measure (@$measures_to_inject) {

    # if that measure is alreay in the Excel model, update it
    if (my $existing = delete $existing_measures{$measure->{Name}}) {

      # check that the associated table has not changed
      my $table_name = $existing->AssociatedTable->Name;
      $measure->{AssociatedTable} eq $table_name
        or die "$measure->{Name} is already associated to table '$table_name'; "
             . "if you really want to change to '$measure->{AssociatedTable}', first delete "
             . "the existing measure";

      # update properties of the existing measure
      $self->log->info("updating measure $measure->{Name}");
      $existing->{FormatInformation} = $self->_build_model_format($measure);
      $existing->{Description}       = $measure->{Description};
      $existing->{Formula}           = $measure->{Formula};
    }

    # otherwise, create a new measure in the Excel model
    else {
      $self->log->info("creating measure $measure->{Name} in table $measure->{AssociatedTable}");

      # see https://learn.microsoft.com/en-us/office/vba/api/excel.modelmeasures.add
      $self->workbook->Model->ModelMeasures->Add(
        $measure->{Name},
        $self->workbook->Model->ModelTables($measure->{AssociatedTable}),
        $measure->{Formula},
        $self->_build_model_format($measure),
        $measure->{Description}
       );
    }
  }

  # if requested, delete remaining measures in model
  if ($options{delete_others}) {
    $self->log->info("deleting measure $_->{Name}"), $_->Delete
      foreach values %existing_measures;
  }

  # reactivate refresh in pivot caches
  $self->log->debug("reactivate refresh in pivot caches") if @refreshable_pivots;
  $_->{EnableRefresh} = 1 foreach @refreshable_pivots;

  $self->log->info("done injecting measures");
}


sub _build_model_format {
  my ($self, $measure) = @_;

  # get format information as specified in the $measure hash
  my $format_info = $measure->{FormatInformation} // [General => ()];

  # invoke proper OLE method to build the ModelFormat object
  my ($short_classname, @args) = @$format_info;
  my $model_method             = "ModelFormat$short_classname";
  my $model_format             = $self->workbook->Model->$model_method(@args);

  return $model_format;
}


#======================================================================
# UTILS FOR POWER QUERY
#======================================================================

sub queries {
  my ($self) = @_;

  my @wb_queries = in $self->workbook->Queries;
  my @queries    = map { { %$_{qw/Name Formula Description/} } } @wb_queries; # hash slice

  return @queries;
}


sub queries_as_YAML {
  my ($self) = @_;

  my $yaml = "";

  foreach my $query ($self->queries) {
    $yaml .= "\n\n$YAML_separator_line\n"
          .  "- Name        : $query->{Name}\n"
          .  "$YAML_separator_line\n"
          .  "  Description : $query->{Description}\n"
          .  "  Formula     : |-\n"
          .  $query->{Formula} =~ s/^/    /gmr;
  }

  return $yaml;
}


sub inject_queries {
  my ($self, $queries_to_inject, %options) = @_;

  # check options
  warn "->inject_queries(..) : option '$_' is invalid"
    foreach invalid_options(\%options, qw/delete_others fast_combine handle_connections/);

  # default options
  $options{fast_combine}       //= True;
  $options{handle_connections} //= True;

  # check well-formedness of $queries_to_inject
  does $queries_to_inject, 'ARRAY'
    or die "parameter to inject_measures() is not an arrayref";
  all {has_nonempty_keys(qw/Name Formula/)->($_)} @$queries_to_inject
    or die "missing mandatory properties in parameter to ->inject_queries()";

  # gather queries already existing in the workbook
  $self->log->info("gathering existing queries in workbook");
  my %existing_queries = map {($_->Name => $_)} grep {$_} in $self->workbook->Queries;

  # this is supposed to accelerate operations -- not sure it makes a difference, though
  # see https://learn.microsoft.com/en-us/office/vba/api/excel.queries.fastcombine
  $self->workbook->Queries->{FastCombine} = True if $options{fast_combine} && $self->workbook->Queries;

  # handle each query to inject
  foreach my $query (@$queries_to_inject) {

    my $q_name = $query->{Name};

    # if that query is alreay in the workbook, update it
    if (my $existing = delete $existing_queries{$q_name}) {
      $self->log->info("updating query $q_name");
      $existing->{Description} = $query->{Description};
      $existing->{Formula}     = $query->{Formula};
    }

    # otherwise, create a new query
    else {
      $self->log->info("creating query $q_name");
      $self->workbook->Queries->Add(@{$query}{qw/Name Formula Description/});

      if ($options{handle_connections}) {
        $self->log->info("creating connection to query $q_name");
        # see https://learn.microsoft.com/en-us/office/vba/api/excel.connections.add &
        # https://learn.microsoft.com/en-gb/dotnet/api/microsoft.office.interop.excel.connections.add2?view=excel-pia
        $self->workbook->Connections->Add2({
          Name                  => "Query - $q_name",
          Description           => "Connection to query '$q_name' in the workbook",
          ConnectionString      => "OLEDB;Provider=Microsoft.Mashup.OleDb.1;Data Source=\$Workbook\$;Location=$q_name",
          CommandText           => $q_name,
          lCmdType              => xlCmdTableCollection,
          CreateModelConnection => True,
          ImportRelationships   => False,
        });
      }
    }
  }

  if ($options{delete_others}) {
    foreach my $wb_query (values %existing_queries) {

      my $q_name = $wb_query->Name;

      # first delete the connection to the query -- and the associated table in the Excel model
      $self->delete_connection_for_query($q_name) if $options{handle_connections};

      # delete the Power Query
      $self->log->info("deleting query $q_name");
      $wb_query->Delete;
    }
  }

  $self->log->info("done injecting queries");
}


sub delete_connection_for_query {
  my ($self, $query_name) = @_;

  # find which connections in workbook refer to that query -- normally there is exactly 1
  my @connections = grep {my $OLEDBConn = $_->OLEDBConnection;
                          $OLEDBConn &&
                          $OLEDBConn->CommandType == xlCmdTableCollection &&
                          $OLEDBConn->CommandText eq qq{"$query_name"}} in $self->workbook->Connections
    or $self->log->warning("no OLEDB connection to delete for query '$query_name'");

  # delete these connections
  foreach my $connection (@connections) {
    $self->log->info("deleting connection $connection->{Name}");
    $connection->Delete;
  }
}


#======================================================================
# RELATIONSHIPS
#======================================================================

sub relationships {
  my ($self) = @_;

  my @relationships;

  foreach my $wb_rel (in $self->workbook->Model->ModelRelationships) {
    my $relationship = {
      ForeignKey => join('.', $wb_rel->ForeignKeyTable->Name, $wb_rel->ForeignKeyColumn->Name),
      PrimaryKey => join('.', $wb_rel->PrimaryKeyTable->Name, $wb_rel->PrimaryKeyColumn->Name),
      Active     => $wb_rel->Active,
     };
    push @relationships, $relationship;
  }

  return @relationships;
}


sub relationships_as_YAML {
  my ($self) = @_;

  my $yaml = "";

  foreach my $rel ($self->relationships) {
    $yaml .= "\n\n$YAML_separator_line\n"
          .  "- ForeignKey  : $rel->{ForeignKey}\n"
          .  "  PrimaryKey  : $rel->{PrimaryKey}\n"
          .  "  Active      : $rel->{Active}\n"
          .  "$YAML_separator_line\n";
  }

  return $yaml;
}


sub inject_relationships {
  my ($self, $relationships_to_inject, %options) = @_;

  # check options
  warn "->inject_relationships(..) : option '$_' is invalid"
    foreach invalid_options(\%options, qw/delete_others/);

  # gather relationships already existing in the model
  $self->log->info("gathering existing relationships in model");
  my %existing_relationships 
    = map {my $fk_pk = sprintf "%s.%s=>%s.%s",
                         $_->ForeignKeyTable->Name, $->ForeignKeyColumn->Name,
                         $_->PrimaryKeyTable->Name, $->PrimaryKeyColumn->Name;
           ($fk_pk => $_->Active)}
          in $self->workbook->Model->ModelRelationships;

  # handle each relationship to inject
  foreach my $rel (@$relationships_to_inject) {
    my $fk_pk = "$rel->{ForeignKey}=>$rel->{PrimaryKey}";

    # if that relationship is alreay in the model, update its activity status
    if (my $existing = delete $existing_relationships{$fk_pk}) {
      if ($existing->{Active} xor $rel->{Active}) {
        $self->log->info("updating relationship $fk_pk");
        $existing->{Active} = $rel->{Active};
      }
    }

    # otherwise, create a new relationship
    else {
      $self->log->info("creating relationship $fk_pk");
      $self->workbook->Model->ModelRelationships->Add(
        $self->_find_ModelTableColumn($rel->{ForeignKey}),
        $self->_find_ModelTableColumn($rel->{PrimaryKey}),
       )
    }
  }

  if ($options{delete_others}) {
    while (my ($fk_pk, $wb_rel) = each %existing_relationships) {
      $self->log->info("deleting relationship $fk_pk");
      $wb_rel->Delete;
    }
  }

  $self->log->info("done injecting relationships");
}


sub _find_ModelTableColumn {
  my ($self, $table_column) = @_;

  my ($table, $column) = split /\./, $table_column;
  my $wb_table = $self->workbook->Model->ModelTables($table)
    or die "could not find table '$table' in Excel model";
  my $wb_column = $wb_table->ModelTableColumns($column)
    or die "could not find column '$column' in table '$table'";

  return $wb_column;
}



#======================================================================
# WHOLE MODEL
#======================================================================


sub whole_model_as_YAML {
  my ($self) = @_;

  my $yaml = "";

 CHAPTER:
  for my $chapter (qw/QUERIES RELATIONSHIPS MEASURES/) {

    # produce YAML representation of this chapter
    my $method   = lc($chapter) . "_as_YAML";
    my $sub_yaml = $self->$method
      or next CHAPTER;
    $sub_yaml =~ s/^/  /mg; # indent all lines by 2 spaces

    # add this chapter to the global YAML
    $yaml .= "\n\n$YAML_separator_line\n"
          .  "$chapter :\n"
          .  "$YAML_separator_line\n"
          .  $sub_yaml;
  }

  return $yaml;
}


sub inject_whole_model {
  my ($self, $model_to_inject, %options) = @_;

 CHAPTER:
  for my $chapter (qw/QUERIES RELATIONSHIPS MEASURES/) {
    my $data_to_inject = $model_to_inject->{$chapter}
      or next CHAPTER;
    my $method   = "inject_" . lc($chapter);
    $self->$method($data_to_inject, %options);
  }

  $self->workbook->Model->Refresh();
}



#======================================================================
# HELPER FUNCTIONS
#======================================================================


sub has_nonempty_keys {
  my @keys = @_;
  return sub {my $hash = shift; all {$hash->{$_}} @keys};
}

sub invalid_options {
  my ($options, @valid_keys) = @_;
  my %is_valid = map {($_ => 1)} @valid_keys;
  return grep {!$is_valid{$_}} keys %$options;
}



1;

__END__

=encoding utf-8

=head1 NAME

Excel::PowerPivot::Utils - utilities for scripting Power Pivot models within Excel workbooks

=head1 SYNOPSIS

  use Excel::PowerPivot::Utils;
  my $ppu = Excel::PowerPivot::Utils->new; # will connect to the currently active workbook

  # operations on the whole model ...
  print $ppu->whole_model_as_YAML;
  $ppu->inject_whole_model({QUERIES       => ...,
                            RELATIONSHIPS => ...
                            MEASURES      => ...});

  # .. or specific operations on queries, relationships or measures
  print $ppu->queries_as_YAML;
  $ppu->inject_queries ([{Name => 'New_table', Formula => $M_formula_for_new_table}]);
  
  print $ppu->relationships_as_YAML;
  $ppu->inject_relationships([ {ForeignKey  => 'Album.ArtistId',
                                PrimaryKey  => 'Artist.ArtistId',
                                Active      => 1},
                               ...
                             ]);
  
  print $ppu->measures_as_YAML;
  $ppu->inject_measures([{Name              => 'Invoice Lines Total Amount',
                          AssociatedTable   => 'InvoiceLine',
                          Description       => 'sum of quantities multiplied by unit price',
                          FormatInformation => [qw/Currency  USD 2/],
                          Formula           => 'SUMX(InvoiceLine, InvoiceLine[UnitPrice] * InvoiceLine[Quantity]'
                         },
                         ...
                        ]);



=head1 DESCRIPTION

This module uses OLE automation to interact with an Excel Power Pivot model.
It can be used for example for

=over

=item * 

documenting existing models

=item *

scripting series of updates or inserts on measures or queries as batch operations -- useful
for propagating similar changes to a series of models.

=item *

use a version control system on textual exports of the model

=back


Obviously, this module only works on a Windows platform with a local installation of
Microsoft Office 2016 or greater.

The exposed interface hides details about the interaction with the Excel object model as documented in
L<https://learn.microsoft.com/en-us/office/vba/excel/concepts/about-the-powerpivot-model-object-in-excel>;
nevertheless, some knowledge of that model and of the L<Win32::OLE> module is recommended to fully understand
what is going on.

=head1 CONSTRUCTOR

  my $ppu = Excel::PowerPivot::Utils->new(%options);

Creates a new instance. Options are :

=over

=item workbook

An OLE object representing an Excel workbook. 
If none is supplied, it will default to the currently active workbook.

=item log

A logger object equipped with C<debug>, C<info> and C<warning> methods.
If none is supplied, a simple logger is automatically created from L<Log::Dispatch>.

=back

=head1 METHODS

=head2 Utilities for Power Query

=head3 queries

Returns information about queries in the Excel workbook. This is a list of hashrefs containing

=over

=item Name

the name of the query

=item Formula

the M formula (Power Query language)

=item Description

optional description text

=back


=head3 queries_as_YAML

Content of the L</queries> method as a L<YAML> string, nicely formatted
so that it is easily readable by humans.

=head3 inject_queries

  $ppu->inject_queries($queries, %options);

Takes an arrayref or query specifications. Each specification must be a hashref
with keys C<Name>, C<Formula> and optionally C<Description>.
For names corresponding to queries already in the workbook, this is an update operation;
other queries in the list are added to the workbook.

Options are :

=over

=item delete_others

If true, queries not mentioned in the list are deleted from the workbook. False by default.

=item handle_connections

If true, queries are automatically associated with workbook connections.
This is equivalent to manually checking "Add this data to the Data Model" in the
"Close and Load To" dialog of Power Query.
True by default.
When adding or deleting queries in the model, Excel recomputes the whole
model, so this operation may be quite slow.

=item fast_combine

Activates the C<FastCombine> property -- see
L<https://learn.microsoft.com/en-us/office/vba/api/excel.queries.fastcombine>.

=back

=head2 Utilities for relationships

=head3 relationships

Returns information about relationships in the Excel model.
Due to the inner constraints of Power Pivot, all relationships are many-to-one.
The returned structure is a list of hashrefs containing :

=item ForeignKey

A single string of form C<$table.$column>, describing the "many" side of the relationship.

=item PrimaryKey

A single string of form C<$table.$column>, describing the "one" side of the relationship.

=item Active

A boolean stating if the relationship is active or not.

=back

=head3 relationships_as_YAML

Content of the L</relationships> method as a L<YAML> string, nicely formatted
so that it is easily readable by humans.

=head3 inject_relationships

  $ppu->inject_relationships($relationships, %options);

Takes an arrayref or relationship specifications. Each specification must be a hashref
with keys C<ForeignKey>, C<PrimaryKey> and C<Active>.
For pairs (foreign key, primary key) corresponding to relationships already in the model,
this is an update operation on the C<Active> property; otherwise the relationships are added to the model.

Options are :

=over

=item delete_others

If true, relationships not mentioned in the list are deleted from the model. False by default.

=back


=head2 Utilities for DAX measures

=head3 measures

Returns information about measures in the Excel model. This is a list of hashrefs containing

=over

=item Name

the name of the measure

=item AssociatedTable

the name of the table to which this measure is associated

=item Formula

the DAX formula

=item Description

optional description text

=over

=head3 measures_as_YAML

Content of the L</measures> method as a L<YAML> string, nicely formatted
so that it is easily readable by humans.

=head3 inject_measures

  $ppu->inject_measures($measures, %options);

Takes an arrayref or measure specifications. Each specification must be a hashref
with keys C<Name>, C<AssociatedTable>, C<Formula> and optionally C<Description>.
For names corresponding to measures already in the model, this is an update operation;
other measures in the list are added to the model.

Options are :

=over

=item delete_others

If true, measures not mentioned in the list are deleted from the model. False by default.

=item dont_refresh_pivots

If true, the C<EnableRefresh> property in pivot caches is temporarily disabled, which allows
for much faster operations on measures in the model. True by default.

=back


=head2 Methods on the whole model

=head3 whole_model_as_YAML

Returns a single YAML string containing descriptions for queries, relationships and measures.

=head3 inject_whole_model

  my $model_to_inject = YAML::Load($whole_model_as_YAML);
  $ppu->inject_whole_model($model_to_inject, %options);

Takes as input a hashref with keys C<QUERIES>, C<RELATIONSHIPS> and C<MEASURES>, and
calls methods L</inject_queries>, L</inject_relationships> and L</inject_measures> on the 
corresponding subtrees.

=head1 NOTES

=over

=item *

Unfortunately this module cannot add DAX computed columns to a model table ... because
there is no available method for this task in the VBA interface for Excel.

=item *

In principle the OLE mechanism allows one to open a connection to an Excel workbook through

  my $workbook = Win32::OLE->GetObject($pathname);

However, launching Power Query or Power Pivot operations on such connections does not work
well -- I experienced several crashes or file corruptions. So the recommended way is
to connect to a running Excel instance, and use that connection to open the workbook.
The C<t/02_chinook.t> file in this distribution contains a full example; here is the 
excerpt doing the connection :

  my $xl  = Win32::OLE->GetActiveObject("Excel.Application")
    or skip "can't connect to an active Excel instance";
  my $workbook = $xl->Workbooks->Open($fullpath_xl_file)
    or skip "cannot open OLE connection to Excel file $fullpath_xl_file";


=back

=head1 FULL EXAMPLE

File C<t/02_chinook.t> this distribution is a full example dealing with the 
L<Chinook database|https://github.com/lerocha/chinook-database>,
an open source dataset. A diagram of the relational schema can be seen at
L<https://schemaspy.org/sample/relationships.html>.

The test script performs the following operations :

=over

=item 1.

download the sqlite database

=item 2.

generate an Excel file with an Excel table for each database table
(through the companion module L<Excel::ValueWriter::XLSX).

=item 3.

inject the model :

=over

=item a)

Power Queries to connect the Excel tables to the Power Pivot model.
Here is an example of the YAML description :


  #======================================================================
  - Name        : Album
  #======================================================================
    Description : 
    Formula     : |-
      let
          Album_Table = Excel.CurrentWorkbook(){[Name="Album"]}[Content],
          #"Modified type" = Table.TransformColumnTypes(Album_Table,{
              {"AlbumId", Int64.Type},
              {"Title", type text},
              {"ArtistId", Int64.Type}})
      in
          #"Modified type"

=item b)

Power Pivot relationships between tables loaded into the model.
Here is an example of the YAML description :

  #======================================================================
  - ForeignKey  : Album.ArtistId
    PrimaryKey  : Artist.ArtistId
    Active      : 1
  #======================================================================

=item c)

Power Pivot measures.Since this is just for demonstration purposes, only 3 measures are defined.
Here is the YAML description :


  #======================================================================
  - Name              : Invoice Lines Total Amount
  #======================================================================
    AssociatedTable   : InvoiceLine
    Description       : 
    FormatInformation : [Currency, USD, 2]
    Formula           : |-
      SUMX(InvoiceLine, InvoiceLine[UnitPrice] * InvoiceLine[Quantity])
  
  #======================================================================
  - Name              : Invoice Total Amount
  #======================================================================
    AssociatedTable   : Invoice
    Description       : 
    FormatInformation : [Currency, USD, 2]
    Formula           : |-
      SUM(Invoice[Total])


  #======================================================================
  - Name              : Invoice Lines Percentage Sales
  #======================================================================
    AssociatedTable   : InvoiceLine
    Description       : 
    FormatInformation : [PercentageNumber, 1, 0]
    Formula           : |-
      DIVIDE([Invoice Lines Total Amount], [Invoice Total Amount])

=item d)

Once the Power Pivot model is in place, we can start building pivot tables
based on the DAX measures. For this task the Perl module has no added
value, it is done through standard OLE automation :

  # create a Pivot Table (percentage of sales per genre, for each customer country)
  my $pcache = $workbook->PivotCaches->Create(xlExternal,
                                              $workbook->Connections("ThisWorkbookDataModel"));
  my $ptable = $pcache->CreatePivotTable("ComputedPivot!R5C1",
                                         'Sales_by_genre_and_country');
  $ptable->CubeFields("[Measures].[Invoice Lines Percentage Sales]")->{Orientation} = xlDataField;
  $ptable->CubeFields("[Genre].[Name]")                             ->{Orientation} = xlColumnField;
  $ptable->CubeFields("[Customer].[Country]")                       ->{Orientation} = xlRowField;

=item e)

Then it is possible to write Excel formulas that extract values from the pivot cache.
So for example here is the formula that retrieves the percentage of sales for the "Classical"
genre in Austria :

  = CUBEVALUE("ThisWorkbookDataModel", 
             "[Measures].[Invoice Lines Percentage Sales]",
             "[Genre].[Name].[Classical]",
             "[Customer].[Country].[Austria]")

=back

=back


=head1 AUTHOR

Laurent Dami, E<lt>dami at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2023 by Laurent Dami.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

