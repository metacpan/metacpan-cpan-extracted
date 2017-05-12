#! perl

use strict;
use warnings;
use Test::More tests => 6;
use File::Spec;
use Iterator::Diamond;

-d 't' && chdir 't';

my $id = "10-stdin";

open(my $f, '>', "$id.tmp")
  or die("$id.tmp: $!\n");
print { $f } "Hello, World1!\n";
print { $f } "Hello, World2!\n";
print { $f } "Hello, World3!\n";
close($f);

@ARGV = ( "$id.tmp", "-" );
close(STDIN);
open(STDIN, '<', "$id.tmp");
my $it = Iterator::Diamond->new( magic => "stdin" );

my @lines = ();
while ( <$it> ) {
    push(@lines, $_);
}

for my $i ( 0..1 ) {
    for my $j ( 1 .. 3 ) {
	is(shift(@lines), "Hello, World$j!\n", "line$j-$i");
    }
}

unlink( "$id.tmp" );
