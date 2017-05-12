#! perl

use strict;
use warnings;
use Test::More tests => 24;
use File::Spec;
use Iterator::Files;

-d 't' && chdir 't';

my $id = "20-user";

open(my $f, '>', "$id.tmp")
  or die("$id.tmp: $!\n");
print { $f } "Hello, World!\n";
close($f);

@ARGV = qw( foo bar );
$ARGV = "foobar";

my @files = ( "$id.tmp" );

my $it = Iterator::Files->new( files => \@files );

ok(@ARGV == 2, "\@ARGV untouched");
is($ARGV, "foobar", "\$ARGV untouched");

# Initially, eof is false.
ok($it->is_eof, "eof at start");

# Testing has_next will set things going.
ok($it->has_next, "has next at start");
is($it->current_file, "$id.tmp", "current file");
ok(@files == 0, "file list exhausted");

my $line = <$it>;
is($line, "Hello, World!\n", "line1");
is($it->current_file, "$id.tmp", "current file");

ok($it->is_eof, "eof");
ok(!$it->has_next, "no next");

$line = <$it>;
ok(!defined $line, "nothing left");

undef $f;
open($f, '>', "$id.tmp")
  or die("$id.tmp: $!\n");
print { $f } "Hello, World1!\n";
print { $f } "Hello, World2!\n";
print { $f } "Hello, World3!\n";
close($f);

@files = ( "$id.tmp" );

$it = Iterator::Files->new( files => \@files );

$line = <$it>;
is($line, "Hello, World1!\n", "line1");
is($it->current_file, "$id.tmp", "current file");
ok(@files == 0, "file list exhausted");

ok(!$it->is_eof, "!eof");
ok($it->has_next, "has next");

# From overload.pm: Even in list context, the iterator is currently
# called only once and with scalar context.

my @lines = $it->readline;
is($lines[0], "Hello, World2!\n", "line2");
is($lines[1], "Hello, World3!\n", "line3");

@files = ( "$id.tmp", "$id.tmp" );
$it = Iterator::Files->new( files => \@files );

@lines = ();
while ( <$it> ) {
    push(@lines, $_);
}

for my $i ( 0..1 ) {
    for my $j ( 1 .. 3 ) {
	is(shift(@lines), "Hello, World$j!\n", "line$j-$i");
    }
}

unlink( "$id.tmp" );
