use strict;
use Test;

BEGIN { plan tests => 6 }

use lib '../lib';
use File::SortedSeek;

my $file = './test.file';
my ( $tell, $begin, $finish, $line, $got, $want, @data, @lines, @between );
File::SortedSeek::set_silent;

#################### alphabetic descending tests ####################

@data =  reverse ( 'AAA' .. 'ZZZ' );
write_file ( @data );
open TEST, "<$file" or die "Can't read from test file $!\n";

File::SortedSeek::set_descending; # set mode to descending

# basic seek
$tell = File::SortedSeek::alphabetic( *TEST, 'BBB' );
chomp ( $line = <TEST> );
ok( $line, 'BBB' );

# check default no cuddle
$tell = File::SortedSeek::alphabetic( *TEST, 'TTTTest' );
chomp ( $line = <TEST> );
ok( $line, 'TTT' );

# cuddle
File::SortedSeek::set_cuddle;
$tell = File::SortedSeek::alphabetic( *TEST, 'TTTTest' );
chomp ( $line = <TEST> );
ok( $line, 'TTU' );

File::SortedSeek::set_no_cuddle;

# check between
$begin  = File::SortedSeek::alphabetic( *TEST, 'ABD' );
$finish = File::SortedSeek::alphabetic( *TEST, 'ABA' );
@between = File::SortedSeek::get_between( *TEST, $begin, $finish );
$got = join " ", @between;
ok( $got, 'ABD ABC ABB' );

# need to close and reopen FH now binmoded.
close TEST;
open TEST, "<$file" or die "Can't read from test file $!\n";

# should retrun first line
$tell = File::SortedSeek::alphabetic( *TEST, 'ZZZZ' );
chomp ( $line = <TEST> );
ok( $line, 'ZZZ' );

# past EOF, should return undefined
$tell = File::SortedSeek::alphabetic( *TEST, 'A' );
ok( !defined $tell );

close TEST;

# write the test file with the data supplied in an array
# we use the default system line ending.
sub write_file {
    open TEST, ">$file" or die "Can't write test file $!\n";
    print TEST "$_\n" for @_;
    close TEST;
}
