use strict;
use FileHandle::Unget;
use File::Spec::Functions qw(:ALL);
use Test::More tests => 13;
use File::Temp;
use File::Slurper qw(read_text);

my $tmp = File::Temp->new();
close $tmp;

# Test "print" and "syswrite" to write/append a file, close $fh
{
  my $fh = new FileHandle::Unget(">" . $tmp->filename);
  print $fh "first line\n";
  close $fh;

  $fh = new FileHandle::Unget(">>" . $tmp->filename);
  syswrite $fh, "second line\n";
  FileHandle::Unget::close($fh);

  my $results = read_text($tmp->filename, undef, 1);

  # 1
  is($results, "first line\nsecond line\n",'No eol separator');
}

# Test input_line_number and scalar line reading, $fh->close
{
  my $fh = new FileHandle::Unget($tmp->filename);

  # 2
  is($fh->input_line_number(),0,'Input line number at start');

  my $line = <$fh>;
  # 3
  is($line,"first line\n",'First line');

  $line = <$fh>;
  # 4
  is($fh->input_line_number(),2,'Input line number at middle');

  $fh->close;
}

# Test array line reading, eof $fh
{
  my $fh = new FileHandle::Unget($tmp->filename);

  my @lines = <$fh>;
  # 5
  is($#lines,1,'Getlines size');
  # 6
  is($lines[0],"first line\n",'First line');
  # 7
  is($lines[1],"second line\n",'Second line');

  # 8
  ok(eof $fh,'EOF');

  $fh->close;
}

# Test byte reading
{
  my $fh = new FileHandle::Unget($tmp->filename);

  my $buf;
  my $result = read($fh, $buf, 8);

  # 9
  is($buf,'first li','read() function');
  # 10
  is($result,8,'Number of bytes read');

  $fh->close;
}

# Test byte ->reading
{
  my $fh = new FileHandle::Unget($tmp->filename);

  my $buf;
  my $result = $fh->read($buf, 8);

  # 11
  is($buf,'first li','read() method');
  # 12
  is($result,8,'Number of bytes read');

  $fh->close;
}

# Test new_from_fd
{
  open FILE, $tmp->filename;
  my $fh = FileHandle::Unget->new_from_fd(\*FILE,'r');

  my $line = <$fh>;
  # 13
  is($line,"first line\n",'new from fd');

  $fh->close;
}
