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
		     {RaiseError=>1, AutoCommit => 0});
  die $DBI::errstr if $DBI::err;
  my $h = IO::BLOB::Pg->new($db);
  local $/ = "x";
  print $h "\n";
  foreach (1..10) {
    print $h "$_", $/;
  }
  my $id = $h->oid;
  $h->close;

  $/ = "\n";
  $h = IO::BLOB::Pg->open($db, $id);
  while (<$h>) {
    $line = $_;
  }
  $h->close;

  $db->disconnect
    if $db;

  ok($line eq "1x2x3x4x5x6x7x8x9x10x", "EOL character works");
}
