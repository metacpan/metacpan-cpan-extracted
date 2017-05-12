use strict;
use FileHandle::Unget;
use File::Spec::Functions qw(:ALL);
use Test::More tests => 3;
use File::Temp;

my $tmp = File::Temp->new();

{
  binmode $tmp;
  print $tmp "this is the first line\n";
  print $tmp "second line\n";
  close $tmp;
}

# Test seek($fh,###,0) and ungets
{
  my $fh = new FileHandle::Unget($tmp->filename);

  seek($fh,23,0);
  my $line = <$fh>;

  # 1
  is($line,"second line\n",'Seek absolute');

  $fh->ungets('1234567890');

  seek($fh,0,0);
  $line = <$fh>;

  # 2
  is($line,"this is the first line\n",'Seek to front');

  $fh->ungets("1234567890\n");

  seek($fh,-11,1);
  $line = <$fh>;

  # 3
  is($line,"first line\n",'Seek backward');

  $fh->close;
}
