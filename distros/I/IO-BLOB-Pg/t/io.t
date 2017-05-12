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

  my $tmp;
  my $h = IO::BLOB::Pg->new($db);
  print $h "\n";
  foreach (1..10) {
    print $h "$_\n";
  }
  my $id = $h->oid;
  $h->close;

  $h = IO::BLOB::Pg->open($db, $id);
  $tmp = $_ while(<$h>);

  $h->close;

  $db->disconnect
    if $db;
  ok($tmp eq "10\n", "<> works");
}


