use strict;
use Test;

BEGIN { plan tests => 6 }

use lib '../lib';
use File::SortedSeek;

my $file = './test.file';
my ( $tell, $begin, $finish, $line, $got, $want, @data, @lines, @between );
File::SortedSeek::set_silent;

#################### find_time tests ####################

@data = ();
my $time;
for ( 0..3000 ) {
   # change time every 10 entries so we have 10 identical times
   $time = scalar gmtime($_) unless $_ % 10;
   push @data, $time;
}

write_file ( @data );
open TEST, "<$file" or die "Can't read from test file $!\n";

# basic seek on time string (exact match)
$tell = File::SortedSeek::find_time( *TEST, 'Thu Jan  1 00:42:00 1970' );
chomp ( $line = <TEST> );
ok( $line, 'Thu Jan  1 00:42:00 1970' );

# basic seek on time string (in between match)
$tell = File::SortedSeek::find_time( *TEST, 'Thu Jan  1 00:42:42 1970' );
chomp ( $line = <TEST> );
ok( $line, 'Thu Jan  1 00:42:50 1970' );

# basic seek on epoch time (exact match)
$tell = File::SortedSeek::find_time( *TEST, 40 );
chomp ( $line = <TEST> );
ok( $line, 'Thu Jan  1 00:00:40 1970' );

# basic seek on epoch time (in between match)
$tell = File::SortedSeek::find_time( *TEST, 42 );
chomp ( $line = <TEST> );
ok( $line, 'Thu Jan  1 00:00:50 1970' );

close TEST;

# write a new test file for between to keep data set returned small
@data = ();
for ( 0..1000 ) {
   push @data, scalar gmtime($_)
}

write_file ( @data );
open TEST, "<$file" or die "Can't read from test file $!\n";

# check between two inexact epoch times (not in file)
$begin  = $tell = File::SortedSeek::find_time( *TEST, 41.5 );
$finish = $tell = File::SortedSeek::find_time( *TEST, 52.5 );
@between = File::SortedSeek::get_between( *TEST, $begin, $finish );
$got = join "\n", @between;
$want = join "\n", @data[42..52];
ok( $got, $want );

# need to close and reopen FH now binmoded.
close TEST;
open TEST, "<$file" or die "Can't read from test file $!\n";

# look for date past EOF

$tell = File::SortedSeek::find_time( *TEST, 'Thu Jan  1 00:00:00 1971' );
ok( !defined $tell );

close TEST;

# write the test file with the data supplied in an array
# we use the default system line ending.
sub write_file {
    open TEST, ">$file" or die "Can't write test file $!\n";
    print TEST "$_\n" for @_;
    close TEST;
}
