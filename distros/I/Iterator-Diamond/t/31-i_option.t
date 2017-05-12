#! perl

use strict;
use warnings;
use Test::More tests => 9;
use File::Spec;
use Iterator::Diamond;

-d 't' && chdir 't';

my $id = "31-i_option";

unlink( "$id.tmp", "$id.tmp~" );

open(my $f, '>', "$id.tmp")
  or die("$id.tmp: $!\n");
print { $f } "Hello, World1!\n";
print { $f } "Hello, World2!\n";
print { $f } "Hello, World3!\n";
ok(close($f), "creating $id.tmp");

@ARGV = ( "$id.tmp" );
$^I = '~';
my $it = Iterator::Diamond->new( use_i_option => 1 );
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

@ARGV = ( "$id.tmp" );
$^I = '';
my $msg = q{Value for 'edit' option (backup suffix) may not be empty};
my $r = eval { Iterator::Diamond->new( use_i_option => 1 ) };
is($r, undef, 'empty suffix rejected');
like($@, qr/ \Q$msg\E /, 'diagnostics');

unlink( "$id.tmp", "$id.tmp~" );
