use strict;
use FileHandle::Unget;
use File::Spec::Functions qw(:ALL);
use Test::More tests => 5;
use File::Temp;

my $tmp = File::Temp->new();

{
  binmode $tmp;
  print $tmp "first line\n";
  print $tmp "second line\n";
  close $tmp;
}

# Test tell($fh) and scalar line reading
{
  my $fh = new FileHandle::Unget($tmp->filename);

  my $line = <$fh>;
  # 1
  is(tell($fh),11,'Tell 1');

  $line = <$fh>;
  # 2
  is(tell($fh),23,'Tell 2');

  $fh->close;
}

# Test tell($fh) and ungets
{
  my $fh = new FileHandle::Unget($tmp->filename);

  my $line = <$fh>;
  # 3
  is(tell($fh),11,'Tell 3');

  $fh->ungets('12345');
  # 4
  is(tell($fh),6,'Tell 4');

  $fh->ungets('1234567890');
  # 5
  is(tell($fh),-4,'Tell 5');

  $fh->close;
}

