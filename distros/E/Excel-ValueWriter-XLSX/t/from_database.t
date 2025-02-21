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

if (!-f $db_file) {
  note "downloading $db_URL";
  my $ua       = LWP::UserAgent->new;
  my $response = $ua->mirror($db_URL, $db_file);
  note $response->message if !$response->is_success;
}


SKIP : {
  skip "couldn't download Chinook sqlite database" if !-f $db_file;

  note "connecting to the sqlite database";
  my $dbh    = DBI->connect("dbi:SQLite:dbname=$db_file","","", {sqlite_unicode => 1, RaiseError => 1});

  my $writer = Excel::ValueWriter::XLSX->new();
  $writer->add_sheets_from_database($dbh);

  my $test_DBIDM = eval "use DBIx::DataModel 3.0; 1";
  if ($test_DBIDM) {
    DBIx::DataModel
        ->Schema('Chinook')
        ->Table(qw/Album          Album           AlbumId     /)
        ->Table(qw/Artist         Artist          ArtistId    /)
        ->Table(qw/Track          Track           TrackId     /)
        ->Table(qw/Genre          Genre           GenreId     /)
        ->Association(
          [qw/Artist         artist          1    ArtistId    /],
          [qw/Album          albums          *    ArtistId    /])
        ->Association(
          [qw/Album          album           1    AlbumId     /],
          [qw/Track          tracks          *    AlbumId     /])
        ->Association(
          [qw/Genre          genre           1    GenreId     /],
          [qw/Track          tracks          *    GenreId     /]);
    Chinook->dbh($dbh);
    my $stmt = Chinook->join(qw/Artist albums tracks genre/)->select(
      -columns   => ["Artist.Name || ':' || Title || '(' || Composer || ')'|full_title"],
      -where     => {'Genre.Name' => 'Classical'},
      -result_as => 'statement',
     );
    $writer->add_sheet('F.Classical', Classical => $stmt);
  }

  note "writing the Excel file";
  $writer->save_as($xl_file);


  # some regex checks in various parts of the ZIP archive
  my $zip = Archive::Zip->new($xl_file);

  my $workbook = $zip->contents('xl/workbook.xml');
  like $workbook, qr[<sheet name="S.Album"], 'has a sheet S.Album';
  like $workbook, qr[<sheet name="S.Artist"], 'has a sheet S.Artist';

  my $strings = $zip->contents('xl/sharedStrings.xml');
  like $strings, qr[<si><t>AlbumId</t></si>], 'has a string "AlbumId"';
  like $strings, qr[<si><t>Great Opera Choruses</t></si>], 'has a string "Great Opera Choruses"';
  if ($test_DBIDM) {
    like $strings, qr[L'Orfeo\(Claudio Monteverdi\)</t></si>], q{has a string "L'Orfeo(Claudio Monteverdi)"};
  }

  note "unlinking temporary files";

  unlink $xl_file, $db_file or note "could not unlink $xl_file, $db_file: $!";
}



# end of tests
done_testing;






