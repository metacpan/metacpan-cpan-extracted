use strict;
use Test;

BEGIN { plan tests => 2 }

use lib '../lib';
use File::SortedSeek;

my $file = './test.file';
my ( $tell, $begin, $finish, $line, $got, $want, @data, @lines, @between );
File::SortedSeek::set_silent;

#################### tests get_between ####################

@data = ();
my $time;
for ( 0..1000 ) {
   # change time every 10 entries so we have 10 identical times
   $time = scalar gmtime($_) unless $_ % 10;
   push @data, $time;
}

write_file ( @data );

# we have already tested it several times, now lets do edge cases
open TEST, "<$file" or die "Can't read from test file $!\n";

# get data at begining of file

$finish  = $tell = File::SortedSeek::find_time( *TEST, 10 );
@between = File::SortedSeek::get_between( *TEST, 0, $finish);
$got = join "\n", @between;
$want = join "\n", @data[0..9];
ok( $got, $want );

# get data at end of file

$begin = $tell = File::SortedSeek::find_time( *TEST, 990 );
@between = File::SortedSeek::get_between( *TEST, $begin, -s TEST );
$got = join "\n", @between;
$want = join "\n", @data[990..1000];
ok( $got, $want );

close TEST;

# write the test file with the data supplied in an array
# we use the default system line ending.
sub write_file {
    open TEST, ">$file" or die "Can't write test file $!\n";
    print TEST "$_\n" for @_;
    close TEST;
}
