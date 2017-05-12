use Test::More tests => 1;
use IO::BLOB::Pg;
use DBI;

SKIP:
{
  skip "No database information given", 1
    unless -f "db-info";

  require 'db-info';

  my $db;
  $db = DBI->connect("dbi:Pg:dbname=$My{dbname}", $My{user}, $My{pass},
		     {
		      RaiseError=>1, AutoCommit => 0});
  die $DBI::errstr if $DBI::err;
  my $tmp;
  eval {
    my $h = IO::BLOB::Pg->new($db);
    print $h "SuperCalifragilistic";
    my $id = $h->oid;
    $h->close;

    $h = IO::BLOB::Pg->open($db, $id);
    $h->seek(3,0);
    $h->read($tmp, 10);
    $h->close;
  };
  $db->disconnect
    if $db;
  ok($tmp eq "erCalifrag", "Seek works");
}
