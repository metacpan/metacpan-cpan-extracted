# -*- perl -*-

use strict;
use Test::More tests => 3;
BEGIN { use_ok( 'File::Shuffle' ); }
ok (testInternal(), 'File internal shuffle test.');
ok (testExternal(), 'File external shuffle test.');

sub testInternal
{
  use File::Temp qw(tempfile);
  use File::Shuffle qw(fileShuffle);
  my @numbers = (0..1000);
  @numbers = sort @numbers;
  my $lines = join("\n", @numbers, '');
  my ($handle, $inputFile) = tempfile();
  print $handle $lines;
  close $handle;
  fileShuffle (inputFile => $inputFile);
  open ($handle, '<', $inputFile);
  my @lines = <$handle>;
  close $handle;
  @lines = sort @lines;
  return $lines eq join ('', @lines);
}

sub testExternal
{
  use File::Temp qw(tempfile);
  use File::Shuffle qw(fileShuffle);
  my @numbers = (0..1000);
  @numbers = sort @numbers;
  my $lines = join("\n", @numbers, '');  my ($handle, $inputFile) = tempfile();
  print $handle $lines;
  close $handle;
  fileShuffle (inputFile => $inputFile, fileSizeBound => 1);
  open ($handle, '<', $inputFile);
  my @lines = <$handle>;
  close $handle;
  @lines = sort @lines;
  return $lines eq join ('', @lines);
}
