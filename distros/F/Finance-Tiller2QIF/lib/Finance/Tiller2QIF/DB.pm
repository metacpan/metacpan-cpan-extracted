package Finance::Tiller2QIF::DB;
# ABSTRACT: SQLite connection helper
$Finance::Tiller2QIF::DB::VERSION = '1.09';
use v5.34;

use DBI;
use Exporter 'import';
use feature qw/signatures/;

our @EXPORT_OK = qw( connect_db );

sub connect_db ($db_path) {
  return DBI->connect(
    "dbi:SQLite:dbname=$db_path",
    '',
    '',
    {
      RaiseError     => 1,
      PrintError     => 0,
      AutoCommit     => 1,
      sqlite_unicode => 1,
    }
  );
}

1;
