use utf8;
use strict;
use warnings;
use Test::More;
use Excel::ValueWriter::XLSX;
use Archive::Zip;
use LWP::UserAgent;
use DBI;


# download the chinook database
my $db_URL = 'https://raw.githubusercontent.com/lerocha/chinook-database/master/ChinookDatabase/DataSources/Chinook_Sqlite.sqlite';
my $db_file = "chinook.sqlite";
my $xl_file = "chinook.xlsx";

note "downloading $db_URL";
my $ua       = LWP::UserAgent->new;
my $response = $ua->mirror($db_URL, $db_file);

SKIP : {
  skip "can't download Chinook sqlite database" if !$response->is_success;

  note "connecting to the sqlite database";
  my $dbh    = DBI->connect("dbi:SQLite:dbname=$db_file","","", {sqlite_unicode => 1});

  note "writing the Excel file";
  my $writer = Excel::ValueWriter::XLSX->new();
  $writer->add_sheets_from_database($dbh);
  $writer->save_as($xl_file);

  # some regex checks in various parts of the ZIP archive
  my $zip = Archive::Zip->new($xl_file);

  my $workbook = $zip->contents('xl/workbook.xml');
  like $workbook, qr[<sheet name="S.Album"], 'has a sheet S.Album';
  like $workbook, qr[<sheet name="S.Artist"], 'has a sheet S.Artist';

  my $strings = $zip->contents('xl/sharedStrings.xml');
  like $strings, qr[<si><t>AlbumId</t></si>], 'has a string "AlbumId"';
  like $strings, qr[<si><t>Great Opera Choruses</t></si>], 'has a string "Great Opera Choruses"';

  note "unlinking temporary files";
  unlink $xl_file, $db_file or note "could not unlink $xl_file, $db_file: $!";
}



# end of tests
done_testing;






