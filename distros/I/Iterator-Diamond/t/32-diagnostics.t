#! perl

use strict;
use warnings;
use Test::More tests => 12;
use Iterator::Diamond;

-d 't' && chdir 't';

my $id = "32-diagnostics";

unlink( "$id.tmp", "$id-empty.tmp", "$id-nil.tmp" );

open(my $f, '>', "$id.tmp")
  or die("$id.tmp: $!\n");
print { $f } "Line 1\n";
print { $f } "Line 2\n";
print { $f } "Line 3\n";
ok(close($f), "creating $id.tmp");

undef $f;
open($f, '>', "$id-empty.tmp")
  or die("$id-empty.tmp: $!\n");
ok(close($f), "creating $id-empty.tmp");

@ARGV = ( "$id-nil.tmp" );
my $it = Iterator::Diamond->new;
my $first = eval { <$it> };
is($first, undef, 'nonexistent file not opened');
like($@, qr/^\Q$id-nil.tmp: /, 'error message');

@ARGV = ( "$id-empty.tmp", "$id.tmp", "$id-empty.tmp", "$id-nil.tmp" );
$it = Iterator::Diamond->new;
foreach my $nr ( 1 .. 3 ) {
    my $line = eval { <$it> };
    is($line, "Line $nr\n", "file content ($nr/3)");
}
my $nothing = eval { <$it> };
is($nothing, undef, 'nonexistent file not opened');
like($@, qr/^\Q$id-nil.tmp: /, 'error message');

@ARGV = ( "$id-empty.tmp", "$id-empty.tmp" );
$it = Iterator::Diamond->new;
my $result = eval { [scalar <$it>] };
is_deeply($result, [undef], 'empty files only');

@ARGV = ( "$id.tmp" );
$it = eval { Iterator::Diamond->new( _x_x_x_ => '_y_y_y_' ) };
is($it, undef, 'unknown options rejected');
like($@, qr/^Iterator::Diamond::new: Unhandled options: _x_x_x_/,
    'error message');

unlink( "$id.tmp", "$id-empty.tmp", "$id-nil.tmp" );
