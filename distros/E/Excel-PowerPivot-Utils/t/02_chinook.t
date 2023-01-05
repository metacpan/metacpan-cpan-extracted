use utf8;
use strict;
use warnings;
use Win32::OLE      qw/CP_UTF8/;
use YAML            qw/LoadFile/;
use Test::More;
use Excel::PowerPivot::Utils;
use Excel::ValueWriter::XLSX;
use LWP::UserAgent;
use DBI;
use Cwd;


#======================================================================
# GLOBALS
#======================================================================

# VBA constants
use constant {

  # https://learn.microsoft.com/en-us/office/vba/api/excel.xlpivotfieldorientation
  xlColumnField => 2,
  xlDataField 	=> 4,
  xlHidden 	=> 0,
  xlPageField 	=> 3,
  xlRowField 	=> 1,

  # https://learn.microsoft.com/en-us/office/vba/api/excel.xlpivottablesourcetype
  xlExternal    => 2,
};

# url and file names
my $db_URL  = "https://raw.githubusercontent.com/lerocha/chinook-database/master/"
            . "ChinookDatabase/DataSources/Chinook_Sqlite.sqlite";
my $db_file = "chinook.sqlite";
my $xl_file = "chinook.xlsx";

# Excel formula for testing the cube result.
# Can't add it through VBA because it would need to be expressed in
# localized language (e.g. 'VALEURCUBE' for a french version of
# Excel). So the trick is to include the formula directly in the XLSX
# file through Excel::ValueWriter::XLSX, before adding the pivot through VBA.
my $formula = 'CUBEVALUE("ThisWorkbookDataModel", '
            .            '"[Measures].[Invoice Lines Percentage Sales]", '
            .            '"[Genre].[Name].[Classical]", '
            .            '"[Customer].[Country].[Austria]")';


#======================================================================
# SETTING UP
#======================================================================

note "downloading $db_URL";
my $ua       = LWP::UserAgent->new(timeout => 5);
my $response = $ua->mirror($db_URL, $db_file);
$response->is_success
  or note "could not download Chinook sqlite database: ", $response->status_line;

SKIP : {
  skip "no sqlite database" if ! -f $db_file;

  note "connecting to the sqlite database";
  my $dbh    = DBI->connect("dbi:SQLite:dbname=$db_file","","", {sqlite_unicode => 1});

  note "generating Excel file $xl_file";
  my $writer = Excel::ValueWriter::XLSX->new();
  $writer->add_sheet(ComputedPivot => (undef) =>  [["=$formula"]]);
  $writer->add_sheets_from_database($dbh);
  $writer->save_as($xl_file);

  # connect to the generated file. Need to have an active Excel, because Pivot operations don't work
  # if we go through Win32::OLE->GetObject() -- don't know why :-(
  my $fullpath_xl_file = (getcwd . "/$xl_file") =~ tr[/][\\]r;
  my $xl  = Win32::OLE->GetActiveObject("Excel.Application")
    or skip "can't connect to an active Excel instance";
  my $workbook = $xl->Workbooks->Open($fullpath_xl_file)
    or skip "cannot open OLE connection to Excel file $fullpath_xl_file";

  # load Power Query and Power Pivot settings
  my $ppu = Excel::PowerPivot::Utils->new(workbook => $workbook);
  my $model_instructions = LoadFile *DATA;
  $ppu->inject_whole_model($model_instructions);

  # create a Pivot Table (percentage of sales per genre, for each customer country)
  my $pcache = $workbook->PivotCaches->Create(xlExternal,
                                              $workbook->Connections("ThisWorkbookDataModel"));
  my $ptable = $pcache->CreatePivotTable("ComputedPivot!R5C1",
                                         'Sales_by_genre_and_country');
  $ptable->CubeFields("[Measures].[Invoice Lines Percentage Sales]")->{Orientation} = xlDataField;
  $ptable->CubeFields("[Genre].[Name]")                             ->{Orientation} = xlColumnField;
  $ptable->CubeFields("[Customer].[Country]")                       ->{Orientation} = xlRowField;

  #======================================================================
  # TESTS
  #======================================================================

  sleep 3; # give time to Excel to recompute the formula
  my $cell = $workbook->Sheets("ComputedPivot")->Range("A1");
  my $val  = $cell->Value;
  ok $val > 0.04 && $val < 0.05, "Pivot correctly computed percentage of sales of Classical in Austria ($val)";

  # cleanup
  $workbook->Close(1); # 1 = true value for 'SaveChanges'
}

done_testing;



__DATA__
#======================================================================
QUERIES :
#======================================================================


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

  #======================================================================
  - Name        : Artist
  #======================================================================
    Description : 
    Formula     : |-
      let
          Artist_Table = Excel.CurrentWorkbook(){[Name="Artist"]}[Content],
          #"Modified type" = Table.TransformColumnTypes(Artist_Table,{
              {"ArtistId", Int64.Type},
              {"Name", type text}})
      in
          #"Modified type"

  #======================================================================
  - Name        : Customer
  #======================================================================
    Description : 
    Formula     : |-
      let
          Customer_Table = Excel.CurrentWorkbook(){[Name="Customer"]}[Content],
          #"Modified type" = Table.TransformColumnTypes(Customer_Table,{
              {"CustomerId", Int64.Type},
              {"FirstName", type text},
              {"LastName", type text},
              {"Company", type text},
              {"Address", type text},
              {"City", type text},
              {"State", type text},
              {"Country", type text},
              {"PostalCode", type any},
              {"Phone", type text},
              {"Fax", type text},
              {"Email", type text},
              {"SupportRepId", Int64.Type}})
      in
          #"Modified type"

  #======================================================================
  - Name        : Employee
  #======================================================================
    Description : 
    Formula     : |-
      let
          Employee_Table = Excel.CurrentWorkbook(){[Name="Employee"]}[Content],
          #"Modified type" = Table.TransformColumnTypes(Employee_Table,{
              {"EmployeeId", Int64.Type},
              {"LastName", type text},
              {"FirstName", type text},
              {"Title", type text},
              {"ReportsTo", Int64.Type},
              {"BirthDate", type datetime},
              {"HireDate", type datetime},
              {"Address", type text},
              {"City", type text},
              {"State", type text},
              {"Country", type text},
              {"PostalCode", type text},
              {"Phone", type text},
              {"Fax", type text},
              {"Email", type text}})
      in
          #"Modified type"

  #======================================================================
  - Name        : Genre
  #======================================================================
    Description : 
    Formula     : |-
      let
          Genre_Table = Excel.CurrentWorkbook(){[Name="Genre"]}[Content],
          #"Modified type" = Table.TransformColumnTypes(Genre_Table,{
              {"GenreId", Int64.Type},
              {"Name", type text}})
      in
          #"Modified type"

  #======================================================================
  - Name        : Invoice
  #======================================================================
    Description : 
    Formula     : |-
      let
          Invoice_Table = Excel.CurrentWorkbook(){[Name="Invoice"]}[Content],
          #"Modified type" = Table.TransformColumnTypes(Invoice_Table,{
              {"InvoiceId", Int64.Type},
              {"CustomerId", Int64.Type},
              {"InvoiceDate", type datetime},
              {"BillingAddress", type text},
              {"BillingCity", type text},
              {"BillingState", type text},
              {"BillingCountry", type text},
              {"BillingPostalCode", type any},
              {"Total", type number}})
      in
          #"Modified type"

  #======================================================================
  - Name        : InvoiceLine
  #======================================================================
    Description : 
    Formula     : |-
      let
          InvoiceLine_Table = Excel.CurrentWorkbook(){[Name="InvoiceLine"]}[Content],
          #"Modified type" = Table.TransformColumnTypes(InvoiceLine_Table,{
              {"InvoiceLineId", Int64.Type},
              {"InvoiceId", Int64.Type},
              {"TrackId", Int64.Type},
              {"UnitPrice", type number},
              {"Quantity", Int64.Type}})
      in
          #"Modified type"

  #======================================================================
  - Name        : MediaType
  #======================================================================
    Description : 
    Formula     : |-
      let
          MediaType_Table = Excel.CurrentWorkbook(){[Name="MediaType"]}[Content],
          #"Modified type" = Table.TransformColumnTypes(MediaType_Table,{
              {"MediaTypeId", Int64.Type},
              {"Name", type text}})
      in
          #"Modified type"

  #======================================================================
  - Name        : Playlist
  #======================================================================
    Description : 
    Formula     : |-
      let
          Playlist_Table = Excel.CurrentWorkbook(){[Name="Playlist"]}[Content],
          #"Modified type" = Table.TransformColumnTypes(Playlist_Table,{
              {"PlaylistId", Int64.Type},
              {"Name", type text}})
      in
          #"Modified type"

  #======================================================================
  - Name        : PlaylistTrack
  #======================================================================
    Description : 
    Formula     : |-
      let
          PlaylistTrack_Table = Excel.CurrentWorkbook(){[Name="PlaylistTrack"]}[Content],
          #"Modified type" = Table.TransformColumnTypes(PlaylistTrack_Table,{
              {"PlaylistId", Int64.Type},
              {"TrackId", Int64.Type}})
      in
          #"Modified type"

  #======================================================================
  - Name        : Track
  #======================================================================
    Description : 
    Formula     : |-
      let
          Track_Table = Excel.CurrentWorkbook(){[Name="Track"]}[Content],
          #"Modified type" = Table.TransformColumnTypes(Track_Table,{
              {"TrackId", Int64.Type},
              {"Name", type text},
              {"AlbumId", Int64.Type},
              {"MediaTypeId", Int64.Type},
              {"GenreId", Int64.Type},
              {"Composer", type text},
              {"Milliseconds", Int64.Type},
              {"Bytes", Int64.Type},
              {"UnitPrice", type number}})
      in
          #"Modified type"

#======================================================================
RELATIONSHIPS :
#======================================================================
  
  
  #======================================================================
  - ForeignKey  : Album.ArtistId
    PrimaryKey  : Artist.ArtistId
    Active      : 1
  #======================================================================
  
  
  #======================================================================
  - ForeignKey  : Invoice.CustomerId
    PrimaryKey  : Customer.CustomerId
    Active      : 1
  #======================================================================
  
  
  #======================================================================
  - ForeignKey  : InvoiceLine.InvoiceId
    PrimaryKey  : Invoice.InvoiceId
    Active      : 1
  #======================================================================
  
  
  #======================================================================
  - ForeignKey  : InvoiceLine.TrackId
    PrimaryKey  : Track.TrackId
    Active      : 1
  #======================================================================
  
  
  #======================================================================
  - ForeignKey  : PlaylistTrack.TrackId
    PrimaryKey  : Track.TrackId
    Active      : 1
  #======================================================================
  
  
  #======================================================================
  - ForeignKey  : PlaylistTrack.PlaylistId
    PrimaryKey  : Playlist.PlaylistId
    Active      : 1
  #======================================================================
  
  
  #======================================================================
  - ForeignKey  : Track.AlbumId
    PrimaryKey  : Album.AlbumId
    Active      : 1
  #======================================================================
  
  
  #======================================================================
  - ForeignKey  : Track.GenreId
    PrimaryKey  : Genre.GenreId
    Active      : 1
  #======================================================================
  
  
  #======================================================================
  - ForeignKey  : Track.MediaTypeId
    PrimaryKey  : MediaType.MediaTypeId
    Active      : 1
  #======================================================================


  #======================================================================
  - ForeignKey  : Customer.SupportRepId
    PrimaryKey  : Employee.EmployeeId
    Active      : 1
  #======================================================================

#======================================================================
MEASURES :
#======================================================================
  
  
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
