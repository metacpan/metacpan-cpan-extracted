use strict;
use Test;

BEGIN { plan tests => 9 }

use lib '../lib';
use File::SortedSeek;

my $file = './test.file';
my ( $tell, $begin, $finish, $line, $got, $want, @data, @lines, @between );
File::SortedSeek::set_silent;

#################### numeric ascending tests ####################

@data = ( 0 .. 1000 );
write_file ( @data );
open TEST, "<$file" or die "Can't read from test file $!\n";

# basic seek
$tell = File::SortedSeek::numeric( *TEST, 42 );
chomp ( $line = <TEST> );
ok( $line, 42 );
ok( File::SortedSeek::was_exact(), 1 );

$tell = File::SortedSeek::numeric( *TEST, 41.5 );
chomp ( $line = <TEST> );
ok( $line, 42 );
ok( File::SortedSeek::was_exact(), 0 );

# cuddle
File::SortedSeek::set_cuddle;
$tell = File::SortedSeek::numeric( *TEST, 41.5 );
chomp ( $line = <TEST> );
ok( $line, 41 );
ok( File::SortedSeek::was_exact(), 0 );

File::SortedSeek::set_no_cuddle;

# check between
$begin  = File::SortedSeek::numeric( *TEST, 941.5 );
$finish = File::SortedSeek::numeric( *TEST, 943.5 );
@between = File::SortedSeek::get_between( *TEST, $begin, $finish );
$got = join " ", @between;
ok( $got, '942 943' );

# need to close and reopen FH now binmoded.
close TEST;
open TEST, "<$file" or die "Can't read from test file $!\n";

# should find first line
$tell = File::SortedSeek::numeric( *TEST, -1 );
chomp ( $line = <TEST> );
ok($line, 0 );

# generate not found error
$tell = File::SortedSeek::numeric( *TEST, 1001 );
ok( !defined $tell );

close TEST;

# write the test file with the data supplied in an array
# we use the default system line ending.
sub write_file {
    open TEST, ">$file" or die "Can't write test file $!\n";
    print TEST "$_\n" for @_;
    close TEST;
}
