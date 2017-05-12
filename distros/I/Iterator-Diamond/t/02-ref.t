#! perl

use strict;
use warnings;
use Test::More tests => 26;
use File::Spec;
use Iterator::Diamond;

-d 't' && chdir 't';

my $id = "02-ref";

open(my $f, '>', "$id.tmp")
  or die("$id.tmp: $!\n");
print { $f } "Hello, World!\n";
close($f);

# @ARGV = ( "$id.tmp", File::Spec->devnull );
@ARGV = ( "$id.tmp" );

my $it = Iterator::Diamond->new;

# $ARGV will not be set until an IO op (either <> or eof(), not eof) is done.
ok(!defined $ARGV, "\$ARGV not set yet");
ok(@ARGV != 0, "\@ARGV pristine");

# Initially, eof is false, $ARGV and @ARGV untouched.
ok($it->is_eof, "eof at start");
ok(!defined $ARGV, "\$ARGV not set yet");
ok(@ARGV != 0, "\@ARGV pristine");

# Testing has_next will set things going.
ok($it->has_next, "has next at start");
is($ARGV, "$id.tmp", "\$ARGV");
ok(@ARGV == 0, "\@ARGV exhausted");

my $line = <$it>;
is($line, "Hello, World!\n", "line0");
is($ARGV, "$id.tmp", "\$ARGV");

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

@ARGV = ( "$id.tmp" );

$it = Iterator::Diamond->new;

$line = <$it>;
is($line, "Hello, World1!\n", "line1");
is($ARGV, "$id.tmp", "\$ARGV");
ok(@ARGV == 0, "\@ARGV exhausted");

ok(!$it->is_eof, "!eof");
ok($it->has_next, "has next");

# From overload.pm: Even in list context, the iterator is currently
# called only once and with scalar context.

my @lines = $it->readline;
is($lines[0], "Hello, World2!\n", "line2");
is($lines[1], "Hello, World3!\n", "line3");

# NOTE <> is reset, since all lines were read and the EOF was sensed
# once,
# Anything more will restart, and use STDIN as input...

@ARGV = ( "$id.tmp", "$id.tmp" );
$it = Iterator::Diamond->new;

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
