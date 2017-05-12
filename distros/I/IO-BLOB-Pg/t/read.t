use Test::More tests => 13;

# Tests borrowed from IO::String.

$str = <<EOT;
This is an example
of a paragraph

and a single line.

EOT

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
  print $io $str;
  my $id = $io->oid;
  $io->close;

  $io = IO::BLOB::Pg->open($db, $id);

  @lines = <$io>;

  ok(@lines == 5 && 
     $lines[1] eq "of a paragraph\n" && 
     $io->input_line_number == 5);

  use vars qw(@tmp);

  ok(!(defined($io->getline)  ||
       (@tmp = $io->getlines) ||
       defined(<$io>)         ||
       defined($io->getc)     ||
       read($io, $buf, 100)   != 0 ||
       $io->getpos != length($str)));

  {
    local $/;  # slurp mode
    $io->setpos(0);
    @lines = $io->getlines;

    ok(@lines == 1 && $lines[0] eq $str);

    $io->setpos(index($str, "and"));
    $line = <$io>;

    ok($line eq "and a single line.\n\n");
  }

  {
    local $/ = "";  # paragraph mode
    $io->setpos(0);
    @lines = <$io>;
    ok(@lines == 2 && $lines[1] eq "and a single line.\n\n");
  }

  {
    local $/ = "is";
    $io->setpos(0);
    @lines = ();
    my $no = 0;
    my $err;
    while (<$io>) {
	push(@lines, $_);
	$err++ if $. != ++$no;
    }

    ok(!$err);

    ok(@lines == 3 && join("-", @lines) eq
       "This- is- an example\n" .
       "of a paragraph\n\n" .
       "and a single line.\n\n");
  }


  # Test read

  $io->setpos(0);

  ok(read($io, $buf, 3) == 3 && $buf eq "Thi");

  ok(sysread($io, $buf, 3, 2) == 3 && $buf eq "Ths i");

  $io->seek(-4, 2);

  ok(!$io->eof);

  ok(read($io, $buf, 20) == 4 && $buf eq "e.\n\n");

  ok(read($io, $buf, 20) == 0 && $buf eq "");

  ok($io->eof);
}
