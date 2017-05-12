use strict;
use FileHandle::Unget;
use File::Spec::Functions qw(:ALL);
use Test::More tests => 1;
use File::Temp;

my $tmp = File::Temp->new();
close $tmp;

# Test "print" and "syswrite" to write/append a file, close $fh
{
  my $fh = new FileHandle::Unget(">" . $tmp->filename);
  print $fh "first line\n";

  # 1
  like(fileno($fh), qr/^\d+$/, 'fileno()');

  close $fh;
}

