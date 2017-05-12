use strict;
use Test;

BEGIN { plan tests => 4 }

use lib '../lib';
use File::SortedSeek;

my $file = './test.file';
my ( $tell, $begin, $finish, $line, $got, $want, @data, @lines, @between );
File::SortedSeek::set_silent;

#################### tests for get_last ####################

@data = ();
my $time;
for ( 0..1000 ) {
   # change time every 10 entries so we have 10 identical times
   $time = scalar gmtime($_) unless $_ % 10;
   push @data, $time;
}

write_file ( @data );

# continue to use or date file
open TEST, "<$file" or die "Can't read from test file $!\n";

# get a chunk of lines as array
@lines =  File::SortedSeek::get_last( *TEST, 101 );
$got = join "\n", @lines;
$want = join "\n", @data[900..1000];
ok( $got, $want );

# get a chunk of lines as reference
$line =  File::SortedSeek::get_last( *TEST, 101 );
$got = join "\n", @$line;
$want = join "\n", @data[900..1000];
ok( $got, $want );

# ask for more than entire file as array
@lines =  File::SortedSeek::get_last( *TEST, 1111 );
$got = join "\n", @lines;
$want = join "\n", @data[0..1000];
ok( $got, $want );

# ask for more than entire file as reference
$line =  File::SortedSeek::get_last( *TEST, 1111 );
$got = join "\n", @$line;
$want = join "\n", @data[0..1000];
ok( $got, $want );

close TEST;

# write the test file with the data supplied in an array
# we use the default system line ending.
sub write_file {
    open TEST, ">$file" or die "Can't write test file $!\n";
    print TEST "$_\n" for @_;
    close TEST;
}
