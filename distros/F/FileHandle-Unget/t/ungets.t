use strict;
use FileHandle::Unget;
use File::Spec::Functions qw(:ALL);
use Test::More tests => 9;
use File::Temp;

my $tmp = File::Temp->new();

{
  print $tmp "first line\n";
  print $tmp "second line\n";
  close $tmp;
}

# Test ungets'ing and reading a line of data
{
  my $fh = new FileHandle::Unget($tmp->filename);

  my $line = <$fh>;

  $fh->ungets("inserted\n");

  $line = <$fh>;

  # 1
  is($line, "inserted\n", 'ungets() 1');

  $line = <$fh>;
  # 2
  is($line, "second line\n", 'getline()');

  $fh->close;
}

# Test ungets'ing and read'in some bytes of data
{
  my $fh = new FileHandle::Unget($tmp->filename);

  my $line = <$fh>;

  $fh->ungets("inserted\n");

  read($fh, $line, 6);
  # 3
  is($line, "insert", 'ungets() 2');

  $line = <$fh>;
  # 4
  is($line, "ed\n", 'getline()');

  $line = <$fh>;
  # 5
  is($line, "second line\n", 'getline() 2');

  $fh->close;
}


# Test ungets'ing and reading multiple lines of data
{
  my $fh = new FileHandle::Unget($tmp->filename);

  my $line = <$fh>;

  $fh->ungets("inserted1\ninserted2\n");

  read($fh, $line, 6);
  # 6
  is($line, "insert", 'ungets()');

  $line = <$fh>;
  # 7
  is($line, "ed1\n", 'getline() 1');

  $line = <$fh>;
  # 8
  is($line, "inserted2\n", 'getline() 2');

  $line = <$fh>;
  # 9
  is($line, "second line\n", 'getline() 3');

  $fh->close;
}

