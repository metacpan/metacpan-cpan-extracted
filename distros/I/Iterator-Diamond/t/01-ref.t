#! perl

use strict;
use warnings;
use Test::More tests => 21;

-d 't' && chdir 't';

my $id = "01-ref";

open(my $f, '>', "$id.tmp")
  or die("$id.tmp: $!\n");
print { $f } "Hello, World!\n";
close($f);

@ARGV = ( "$id.tmp" );
# @ARGV = ( "$id.tmp", "/dev/null" );

# $ARGV will not be set until an IO op (either <> or eof(), not eof) is done.
ok(!defined $ARGV, "\$ARGV not set yet");
ok(@ARGV != 0, "\@ARGV pristine");

# Initially, eof is false, $ARGV and @ARGV untouched.
SKIP: {
    skip( "Unreliable test", 1 );
    ok(eof, "eof at start");
}
ok(!defined $ARGV, "\$ARGV not set yet");
ok(@ARGV != 0, "\@ARGV pristine");

# Testing eof() will set things going.
ok(!eof(), "has next at start");
is($ARGV, "$id.tmp", "\$ARGV");
ok(@ARGV == 0, "\@ARGV exhausted");

my $line = <>;
is($line, "Hello, World!\n", "line1");
is($ARGV, "$id.tmp", "\$ARGV");

ok(eof, "eof");
ok(eof(), "no next");

$line = <>;
ok(!defined $line, "nothing left");

undef $f;
open($f, '>', "$id.tmp")
  or die("$id.tmp: $!\n");
print { $f } "Hello, World1!\n";
print { $f } "Hello, World2!\n";
print { $f } "Hello, World3!\n";
close($f);

@ARGV = ( "$id.tmp" );

$line = <>;
is($line, "Hello, World1!\n", "line1");
is($ARGV, "$id.tmp", "\$ARGV");
ok(@ARGV == 0, "\@ARGV exhausted");

ok(!eof, "!eof");
ok(!eof(), "has next");

my @lines = <>;
is($lines[0], "Hello, World2!\n", "line2");
is($lines[1], "Hello, World3!\n", "line3");

# NOTE <> is reset, since all lines were read and the EOF was sensed
# once,

ok(eof, "eof");

# Anything more will restart, and use STDIN as input...

unlink( "$id.tmp" );
