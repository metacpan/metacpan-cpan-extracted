#!perl

use warnings;
use strict;
use 5.010;
use lib 't';
use Test::More;
use Lab::Test import => ['file_ok'];
use File::Temp qw/tempdir/;
use Test::File;
use Test::Fatal;
use File::Spec::Functions qw/catfile/;
use Lab::Moose;
use Module::Load 'autoload';
use IO::Uncompress::Bunzip2 qw(bunzip2 $Bunzip2Error);

my $dir = tempdir( CLEANUP => 1 );
my $folder = datafolder( path => catfile( $dir, 'gnuplot' ) );

my $path;

{
    my $file = datafile(
        type     => 'Gnuplot::Compressed',
        folder   => $folder,
        filename => 'file.dat',
        columns  => [qw/A B C/],
    );
    $path = $file->path();
    $file->log( A => 0.7, B => 2, C => 3 );
    $file->new_block();
    $file->log_comment( comment => 'YOLO' );
    $file->log( A => 2, B => 3, C => 4 );
}

# need to make sure the file is closed here

my $expected = <<"EOF";
# A\tB\tC
0.7\t2\t3

#YOLO
2\t3\t4
EOF

bunzip2( $path => $path . '.raw', BinModeOut => 1 )
    or die "error $Bunzip2Error\n";

file_ok(
    $path . '.raw', $expected,
    "gnuplot file log method, bzip2 compressed"
);

done_testing();
