#!perl -T
use 5.006;
use strict;
use warnings;

use File::Temp;
use Test::More;
use IO::ReadHandle::Chain;

my $skipped = 0;

# reading from nothing

my $cfh = IO::ReadHandle::Chain->new();

my @lines = ();
push @lines, $_ while <$cfh>;
$cfh->close;

is_deeply(\@lines, [], 'no data');

# reading from scalars

my $source1 = "foo is better\nthan bar is\nby far!";
my $source2 = "text3\ntext4";
my $source3 = "text5\ntext6";

$cfh = IO::ReadHandle::Chain->new(\$source1);

@lines = ();
push @lines, $_ while <$cfh>;
$cfh->close;

is_deeply(\@lines, ["foo is better\n",
                    "than bar is\n",
                    "by far!"], 'source 1, separated by newline');

# in list context

$cfh = IO::ReadHandle::Chain->new(\$source1);
@lines = <$cfh>;
$cfh->close;

is_deeply(\@lines, ["foo is better\n",
                    "than bar is\n",
                    "by far!"], 'list context');

# change record separator to 'is'
$/ = 'is';

$cfh = IO::ReadHandle::Chain->new(\$source1);
@lines = <$cfh>;
$cfh->close;

is_deeply(\@lines, ["foo is",
                    " better\nthan bar is",
                    "\nby far!"], 'source 1, separated by "is"');

# change record separator to back to newline
$/ = "\n";

$cfh = IO::ReadHandle::Chain->new(\$source1, \$source2, \$source3);
@lines = $cfh->getlines;
$cfh->close;

is_deeply(\@lines, ["foo is better\n",
                    "than bar is\n",
                    "by far!text3\n",
                    "text4text5\n",
                    "text6"], 'source 1, 2, 3');

# reading from files

my $tmp = File::Temp->new();
print $tmp $source1;
$tmp->flush;
$tmp->seek(0, 0);               # rewind

# read from a file through a file handle

$cfh = IO::ReadHandle::Chain->new(\$source2, $tmp, \$source3);
@lines = <$cfh>;
$cfh->close;

is_deeply(\@lines, ["text3\n",
                    "text4foo is better\n",
                    "than bar is\n",
                    "by far!text5\n",
                    "text6"], 'file handle');

is($tmp->tell, 0, 'file handle position at the start unchanged');

# read from file handle that isn't at the beginning

<$tmp>;

my $pos = $tmp->tell;

$cfh = IO::ReadHandle::Chain->new($tmp);
@lines = <$cfh>;
$cfh->close;

is_deeply(\@lines, ["than bar is\n",
                    "by far!"],
          'file handle in the middle');
is($tmp->tell, $pos, 'file handle position in the middle unchanged');

# read from the file through the file name

my $filename = "$tmp";
$cfh = IO::ReadHandle::Chain->new(\$source2, $filename, \$source3);
@lines = ();
while (my $line = $cfh->getline) {
  push @lines, $line;
}
$cfh->close;

is_deeply(\@lines, ["text3\n",
                    "text4foo is better\n",
                    "than bar is\n",
                    "by far!text5\n",
                    "text6"], 'file name');

# read from the file twice through the file name

$cfh = IO::ReadHandle::Chain->new($filename, \$source2, $filename);
@lines = ();
while (my $line = $cfh->getline) {
  push @lines, $line;
}
$cfh->close;

is_deeply(\@lines, ["foo is better\n",
                    "than bar is\n",
                    "by far!text3\n",
                    "text4foo is better\n",
                    "than bar is\n",
                    "by far!"], 'file name twice');

# reading bytes

$cfh = IO::ReadHandle::Chain->new(\$source2);
my $buffer = '';

is($cfh->getc, 't', 'getc');

my $n = read($cfh, $buffer, 9);

is($n, 9, 'read 9 bytes');
is($buffer, "ext3\ntext", 'bytes');

$pos = $n;
$n = $cfh->read($buffer, 10, $pos);

is($n, 1, 'read next byte');
is($buffer, "ext3\ntext4", 'next bytes');

$n = $cfh->read($buffer, 100);
is($n, 0, 'end of data');
is($buffer, '', 'means empty buffer');

$cfh->close;

$cfh = IO::ReadHandle::Chain->new(\$source2, "$tmp");
$buffer = '';
@lines = ();
while ($n = read($cfh, $buffer, 10)) {
  push @lines, $buffer;
}
$cfh->close;

is_deeply(\@lines, ["text3\ntext",
                    '4foo is be',
                    "tter\nthan ",
                    "bar is\nby ",
                    'far!'
                   ], 'bytes from scalar and file handle');

# sysread

$tmp->seek(0, 0);               # back to the beginning

$cfh = IO::ReadHandle::Chain->new($tmp);
$buffer = '';
$n = sysread($cfh, $buffer, 10);

is($n, 10, 'sysread 10 bytes');
is($buffer, "foo is bet", 'bytes');

# writing fails

$cfh = IO::ReadHandle::Chain->new($tmp);
$@ = '';
eval { print $cfh "Oh, no!\n"; };
like($@, qr/^Cannot print via a IO::ReadHandle::Chain/, 'print fails');

$@ = '';
eval { printf $cfh '%s', 'foo'; };
like($@, qr/^Cannot printf via a IO::ReadHandle::Chain/, 'printf fails');

$@ = '';
eval { $cfh->syswrite($buffer, 5) };
like($@, qr/^Cannot syswrite via a IO::ReadHandle::Chain/, 'printf fails');

# seeking fails

$@ = '';
eval { $cfh->seek(0, 0) };
like($@, qr/^Cannot seek via a IO::ReadHandle::Chain/, 'printf fails');

# reading from hash fails

$@ = '';
eval { $cfh = IO::ReadHandle::Chain->new({}) };
like($@, qr/^Sources must be scalar, scalar reference, or file handle/,
     'hash ref fails');

# reading from a write-only file handle yields nothing

my $fname = 'IO-functionality-temp.txt';
if (open my $ofh, '>', $fname) {
  print $ofh "Some text\n";
  seek($ofh, 0, 0);
  $@ = '';
  $cfh = IO::ReadHandle::Chain->new($ofh);
  @lines = <$cfh>;
  close $ofh;
  unlink $fname;
  is_deeply(\@lines, [], 'read nothing from write-only file handle');
} else {
  diag("Cannot open $fname for writing: $!");
  ++$skipped;
}

done_testing(27 - $skipped);
