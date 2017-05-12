use strict;
use FileHandle::Unget;
use File::Spec::Functions qw(:ALL);
use Test::More tests => 12;
use File::Temp;
use File::Slurp ();

my $tmp = File::Temp->new();
close $tmp;

# Test "print" and "syswrite" to write/append a file, close $fh
{
#  my $fh1 = new FileHandle(">" . $tmp->filename);

  use Symbol;
  my $fh1 = gensym;
  open $fh1, ">" . $tmp->filename;

  my $fh = new FileHandle::Unget($fh1);
  print $fh "first line\n";
  close $fh;

  $fh1 = new FileHandle(">>" . $tmp->filename);
  $fh = new FileHandle::Unget($fh1);
  syswrite $fh, "second line\n";
  FileHandle::Unget::close($fh);

  my $results = File::Slurp::read_file($tmp->filename);

  # 1
  is($results, "first line\nsecond line\n",'syswrite()');
}

# Test input_line_number and scalar line reading, $fh->close
{
#  my $fh1 = new FileHandle($tmp->filename);

  use Symbol;
  my $fh1 = gensym;
  open $fh1, "<" . $tmp->filename;

  my $fh = new FileHandle::Unget($fh1);

  # 2
  is($fh->input_line_number(),0,'input_line_number()');

  my $line = <$fh>;
  # 3
  is($line,"first line\n",'getline()');

  $line = <$fh>;
  # 4
  is($fh->input_line_number(),2,'input_line_number() after reading');

  $fh->close;
}

# Test array line reading, eof $fh
{
#  my $fh1 = new FileHandle($tmp->filename);

  use Symbol;
  my $fh1 = gensym;
  open $fh1, "<" . $tmp->filename;

  my $fh = new FileHandle::Unget($fh1);

  my @lines = <$fh>;
  # 5
  is($#lines,1,'getlines() size');
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
#  my $fh1 = new FileHandle($tmp->filename);

  use Symbol;
  my $fh1 = gensym;
  open $fh1, "<" . $tmp->filename;

  my $fh = new FileHandle::Unget($fh1);

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
#  my $fh1 = new FileHandle($tmp->filename);

  use Symbol;
  my $fh1 = gensym;
  open $fh1, "<" . $tmp->filename;

  my $fh = new FileHandle::Unget($fh1);

  my $buf;
  my $result = $fh->read($buf, 8);

  # 11
  is($buf,'first li','read() method');
  # 12
  is($result,8,'Number of bytes read');

  $fh->close;
}
