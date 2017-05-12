use strict;
use FileHandle;
use FileHandle::Unget;
use File::Spec::Functions qw(:ALL);
use Test::More tests => 3;
use File::Temp;

my $tmp = File::Temp->new();

{
  print $tmp "first line\n";
  print $tmp "second line\n";
  close $tmp;
}

# Test ungetc'ing and reading a line of data
{
  my $fh = new FileHandle::Unget($tmp->filename);

  my $line = <$fh>;

  $fh->ungetc(ord("\n"));
  $fh->ungetc(ord("d"));
  $fh->ungetc(ord("e"));
  $fh->ungetc(ord("t"));
  $fh->ungetc(ord("r"));
  $fh->buffer("inse" . $fh->buffer);

  # 1
  is($fh->buffer, "inserted\n");

  $line = <$fh>;

  # 2
  is($line, "inserted\n");

  $line = <$fh>;
  # 3
  is($line, "second line\n");

  $fh->close;
}

