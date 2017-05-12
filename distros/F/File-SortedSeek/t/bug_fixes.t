use strict;
use Test;

BEGIN { plan tests => 3 }

use lib '../lib';
use File::SortedSeek;

my $file = './test.file';
my ( $tell, $begin, $finish, $line, $got, $want, @data, @lines, @between );
File::SortedSeek::set_silent;

#################### tests for get_last ####################

open TESTOUT, '>',$file or die "Can't write test file $!\n";
# write 10 of each of the numbers from 0 to 9
for my $item (0..9) {
    for ( 1..20000 ) {
        print TESTOUT "$item\n";
    }
}
close TESTOUT;

open TESTIN, '<',$file or die "Can't read from test file $!\n";
$tell = File::SortedSeek::numeric( *TESTIN, '7' );
my $num_of_sevens=0;
while ( $line = <TESTIN> ){
    if($line =~ m/7/){
        $num_of_sevens++;
    } else {
        last;
    }
}

ok($num_of_sevens,20000);

File::SortedSeek::set_cuddle;
$tell = File::SortedSeek::numeric( *TESTIN, 6.5 );
chomp($line = <TESTIN>);
ok($line, 6);
chomp($line = <TESTIN>);
ok($line, 7);

close TESTIN;

unlink $file;


# write the test file with the data supplied in an array
# we use the default system line ending.
sub write_file {
    open TEST, ">$file" or die "Can't write test file $!\n";
    print TEST "$_\n" for @_;
    close TEST;
}
