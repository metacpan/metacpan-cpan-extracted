# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl File-GetLineMaxLength.t'

#########################

use Test::More tests => 39 + 768 + 64;
BEGIN { use_ok('File::GetLineMaxLength') };
use File::Temp qw(tempfile);

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use strict;

my $Fh = tempfile();
select($Fh); $/ = "\r\n";
my ($FGL, $Line, $Long);

sub newfile {
  seek($Fh, 0, 0);
  truncate($Fh, 0);
  print $Fh $_[0];
  seek($Fh, 0, 0);
  return File::GetLineMaxLength->new($Fh, 64);
}

$FGL = newfile("a line\r\n");
$Line = $FGL->getline();
ok($Line eq "a line\r\n", "basic 1.1");
$Line = $FGL->getline();
ok($Line eq "", "basic 1.2");

$FGL = newfile("a line\r\n");
$Line = $FGL->getline(16, $Long);
ok($Line eq "a line\r\n", "basic 2.1");
ok($Long == 0, "basic 2.2");
$Line = $FGL->getline(16, $Long);
ok($Line eq "", "basic 2.3");
ok($Long == 0, "basic 2.4");

$FGL = newfile("a line\r\n");
$Line = $FGL->getline(6, $Long);
ok($Line eq "a line\r\n", "basic 3.1");
ok($Long == 0, "basic 3.2");
$Line = $FGL->getline(6, $Long);
ok($Line eq "", "basic 3.3");
ok($Long == 0, "basic 3.4");

$FGL = newfile("a line\r\n");
$Line = $FGL->getline(5, $Long);
ok($Line eq "a lin", "basic 4.1");
ok($Long == 1, "basic 4.2");
$Line = $FGL->getline(5, $Long);
ok($Line eq "e\r\n", "basic 4.3");
ok($Long == 0, "basic 4.4");
$Line = $FGL->getline(5, $Long);
ok($Line eq "", "basic 4.5");
ok($Long == 0, "basic 4.6");

$FGL = newfile("a line\r\nline 2\r\n");
$Line = $FGL->getline(6, $Long);
ok($Line eq "a line\r\n", "basic 5.1");
ok($Long == 0, "basic 5.2");
$Line = $FGL->getline(6, $Long);
ok($Line eq "line 2\r\n", "basic 5.3");
ok($Long == 0, "basic 5.4");
$Line = $FGL->getline(6, $Long);
ok($Line eq "", "basic 5.5");
ok($Long == 0, "basic 5.6");

$FGL = newfile("a line\r\nline 2\r\n");
$Line = $FGL->getline(5, $Long);
ok($Line eq "a lin", "basic 6.1");
ok($Long == 1, "basic 6.2");
$Line = $FGL->getline(5, $Long);
ok($Line eq "e\r\n", "basic 6.3");
ok($Long == 0, "basic 6.4");
$Line = $FGL->getline(6, $Long);
ok($Line eq "line 2\r\n", "basic 6.5");
ok($Long == 0, "basic 6.6");
$Line = $FGL->getline(6, $Long);
ok($Line eq "", "basic 6.7");
ok($Long == 0, "basic 6.8");

$FGL = newfile("a line\r\n" x 64);
for (1 .. 64) {
  $Line = $FGL->getline(5, $Long);
  ok($Line eq "a lin", "basic 7.1");
  ok($Long == 1, "basic 7.2");
  $Line = $FGL->getline(5, $Long);
  ok($Line eq "e\r\n", "basic 7.3");
  ok($Long == 0, "basic 7.4");
}
$Line = $FGL->getline(5, $Long);
ok($Line eq "", "basic 7.5");
ok($Long == 0, "basic 7.6");

$FGL = newfile("a line2\r\n" x 64);
for (1 .. 64) {
  $Line = $FGL->getline(5, $Long);
  ok($Line eq "a lin", "basic 8.1");
  ok($Long == 1, "basic 8.2");
  $Line = $FGL->getline(5, $Long);
  ok($Line eq "e2\r\n", "basic 8.3");
  ok($Long == 0, "basic 8.4");
}
$Line = $FGL->getline(5, $Long);
ok($Line eq "", "basic 8.5");
ok($Long == 0, "basic 8.6");

$FGL = newfile("a line longer than the buffer size to test buffer crossings line blah blah \r\n" x 64);
for (1 .. 64) {
  $Line = $FGL->getline();
  ok($Line eq "a line longer than the buffer size to test buffer crossings line blah blah \r\n", "basic 9.1");
}
$Line = $FGL->getline();
ok($Line eq "", "basic 9.2");

$FGL = newfile("a line longer than the buffer size to test buffer crossings line blah blah \r\n" x 64);
for (1 .. 64) {
  $Line = $FGL->getline(69, $Long);
  ok($Line eq "a line longer than the buffer size to test buffer crossings line blah", "basic 10.1");
  ok($Long == 1, "basic 10.2");
  $Line = $FGL->getline(69, $Long);
  ok($Line eq " blah \r\n", "basic 10.3");
  ok($Long == 0, "basic 10.4");
}
$Line = $FGL->getline();
ok($Line eq "", "basic 10.5");

$FGL = newfile("a line with no EOL");
$Line = $FGL->getline();
ok($Line eq "a line with no EOL", "basic 11.1");
$Line = $FGL->getline();
ok($Line eq "", "basic 11.2");

