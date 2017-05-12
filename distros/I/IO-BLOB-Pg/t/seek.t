use Test::More tests => 9;

# Tests borrowed from IO::String.

$str = "abcd";

use IO::BLOB::Pg;
use DBI;
require IO::Handle;
$SEEK_CUR = &IO::Handle::SEEK_CUR;
SKIP:
{
  skip "No database information given", 9
    unless -f "db-info";

  require 'db-info';

  $db = DBI->connect("dbi:Pg:dbname=$My{dbname}", $My{user}, $My{pass},
		     {
		      RaiseError=>1, AutoCommit => 0});

  $io = IO::BLOB::Pg->new($db);	# pre-fill.
  print $io $str;
  my $id = $io->oid;
  $io->close;

  $io = IO::BLOB::Pg->open($db, $id);

  sub all_pos {
    my($io, $expect) = @_;

    $io->getpos == $expect &&
      $io->tell   == $expect &&
	$io->seek(0, $SEEK_CUR) &&
	  $io->sysseek(0, $SEEK_CUR) &&
	    $io->pos    == $expect &&
	      1;
  }

  ok(all_pos($io,0));

  $io->setpos(2);
  ok(all_pos($io, 2));


  $io->setpos(10);
  ok(all_pos($io, 4));

  $io->seek(10, 0);
  ok(all_pos($io, 10));

  $io->print("זרו");
  ok(all_pos($io, 13));

  $io->seek(-4, 2);
  ok(all_pos($io, 9));

  ok($io->read($buf, 20) == 4 && $buf eq "\0זרו");

  $io->seek(-10,1);
  ok(all_pos($io, 3));

  $io->seek(0,0);
  ok(all_pos($io,0));
}
