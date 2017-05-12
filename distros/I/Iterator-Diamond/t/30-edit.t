#! perl

use strict;
use warnings;
use Test::More tests => 7;
use File::Spec;
use Iterator::Diamond;

-d 't' && chdir 't';

my $id = "30-edit";

unlink( "$id.tmp", "$id.tmp~" );

open(my $f, '>', "$id.tmp")
  or die("$id.tmp: $!\n");
print { $f } "Hello, World1!\n";
print { $f } "Hello, World2!\n";
print { $f } "Hello, World3!\n";
ok(close($f), "creating $id.tmp");

@ARGV = ( "$id.tmp" );
my $it = Iterator::Diamond->new( edit => '~' );
my @lines = ();
while ( <$it> ) {
    s/ll/xx/g;
    print;
}

@ARGV = ( "$id.tmp" );
$it = Iterator::Diamond->new;
@lines = ();
while ( <$it> ) {
    push(@lines, $_);
}

for my $j ( 1 .. 3 ) {
    is(shift(@lines), "Hexxo, World$j!\n", "line$j");
}

@ARGV = ( "$id.tmp~" );
$it = Iterator::Diamond->new;
@lines = ();
while ( <$it> ) {
    push(@lines, $_);
}

for my $j ( 1 .. 3 ) {
    is(shift(@lines), "Hello, World$j!\n", "line$j");
}

unlink( "$id.tmp", "$id.tmp~" );
