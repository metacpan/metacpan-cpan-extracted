use Test::More tests => 1;

# Tests borrowed from IO::String.

use IO::BLOB::Pg;
use DBI;

SKIP:
{
  skip "No database information given", 13
    unless -f "db-info";

  require 'db-info';

  $db = DBI->connect("dbi:Pg:dbname=$My{dbname}", $My{user}, $My{pass},
		     {RaiseError=>1, AutoCommit => 0});

  $io = IO::BLOB::Pg->new($db);	# pre-filln.

  print $io "Heisan\n";
  $io->print("a", "b", "c");

  {
    local($\) = "\n";
    print $io "d", "e";
    local($,) = ",";
    print $io "f", "g", "h";
  }

  $foo = "1234567890";

  syswrite($io, $foo, length($foo));
  $io->syswrite($foo);
  $io->syswrite($foo, length($foo));
  $io->write($foo, length($foo), 5);
  $io->write("xxx\n", 100, -1);

  for (1..3) {
    printf $io "i(%d)", $_;
    $io->printf("[%d]\n", $_);
  }
  select $io;
  print "\n";

  $io->setpos(0);
  print "h";
  $io->setpos(0);

  local $/;
  $str = <$io>;

  ok($str eq "heisan\nabcde\nf,g,h\n" .
     ("1234567890" x 3) . "67890\n" .
     "i(1)[1]\ni(2)[2]\ni(3)[3]\n\n");
}
