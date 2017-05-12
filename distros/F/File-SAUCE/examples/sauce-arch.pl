#!/usr/bin/perl

use File::SAUCE;
use Archive::Zip;
use strict;
use warnings;

my $file = $ARGV[ 0 ] || die 'No file specified';
my $zip = Archive::Zip->new( $file ) || die "$file is not a zip file";
my $sauce = File::SAUCE->new;

# setup the template and print a header
my $tmpl = "%12s %15s %35s %14s\n";
printf( $tmpl, 'FILE',   'AUTHOR', 'TITLE',  'GROUP' );
printf( $tmpl, '-' x 12, '-' x 15, '-' x 35, '-' x 14 );

for ( $zip->members ) {

    # skip directories
    next if $_->isDirectory;

    # get SAUCE data from file contents
    $sauce->read( string => scalar $_->contents );

    # print the result
    printf( $tmpl,
        $_->fileName, $sauce->author, $sauce->title, $sauce->group );
}
