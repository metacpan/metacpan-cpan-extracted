use strict;
use FileHandle::Unget;
use File::Spec::Functions qw(:ALL);
use Test::More tests => 1;
use File::Temp;

my $tmp = File::Temp->new();

{
  print $tmp "first line\n";
  print $tmp "second line\n";
  close $tmp;
}

# Test getline on the end of the file
{
  my $fh = new FileHandle::Unget($tmp->filename);

  binmode $fh;

  my $string;
  read($fh,$string,5);
  $fh->ungets($string);

  my $line;

  my $bytes_read = 0;
  
  while($line = <$fh>)
  {
    $bytes_read += length $line;

    last if $bytes_read > -s $tmp->filename;
  }

  # 1
  is($bytes_read,-s $tmp->filename, 'Loop bug');

  $fh->close;
}
