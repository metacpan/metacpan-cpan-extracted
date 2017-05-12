use Test::More tests => 1;

# Tests borrowed from IO::String.

use IO::BLOB::Pg;
use DBI;

SKIP:
{
  skip "No database info"
    unless -f "db-info";
  require 'db-info';

  $db = DBI->connect("dbi:Pg:dbname=$My{dbname}", $My{user}, $My{pass},
		     {RaiseError=>1, AutoCommit => 0});

  $io = IO::BLOB::Pg->new($db);

  $io->truncate(10);
  ok($io->_length == 10);

}
