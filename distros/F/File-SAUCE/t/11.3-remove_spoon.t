use Test::More tests => 11;

use strict;
use warnings;

use File::Copy;

BEGIN {
    use_ok( 'File::SAUCE' );
}

my $testfile = qw( t/data/remove.dat );
my $file     = qw( t/data/spoon.dat );
my $filesize = 128;

my $sauce = File::SAUCE->new;
isa_ok( $sauce, 'File::SAUCE' );

create_test_file( $file );

# remove from file
$sauce->read( file => $testfile );
is( $sauce->has_sauce, 1, 'Has Sauce' );

$sauce->remove( file => $testfile );
$sauce->read( file => $testfile );

is( $sauce->has_sauce, 0,         'Has Sauce' );
is( -s $testfile,      $filesize, 'Filesize' );

create_test_file( $file );

# remove from handle
open( my $fh, "+<$testfile" );

$sauce->read( handle => $fh );
is( $sauce->has_sauce, 1, 'Has Sauce' );

$sauce->remove( handle => $fh );
$sauce->read( handle => $fh );

is( $sauce->has_sauce, 0,         'Has Sauce' );
is( -s $testfile,      $filesize, 'Filesize' );

close( $fh );

create_test_file( $file );

# remove from string
my $string = do {
    open( my $data, $testfile );
    local $/;
    my $content = <$data>;
    close( $data );
    $content;
};

$sauce->read( string => $string );
is( $sauce->has_sauce, 1, 'Has Sauce' );

$string = $sauce->remove( string => $string );
$sauce->read( string => $string );

is( $sauce->has_sauce, 0,         'Has Sauce' );
is( length( $string ), $filesize, 'Filesize' );

# clean up
unlink( $testfile );

sub create_test_file {
    my $file = shift;

    unlink( $testfile );
    copy( $file, $testfile );
}
