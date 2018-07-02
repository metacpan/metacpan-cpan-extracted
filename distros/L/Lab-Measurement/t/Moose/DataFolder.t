#!perl

use warnings;
use strict;
use 5.010;
use lib 't';
use Test::More;
use Lab::Test import => ['file_ok'];
use File::Temp qw/tempdir/;
use Test::File;
use File::Path 'remove_tree';
use Lab::Moose::Catfile qw/our_catfile/;
use YAML::XS 'LoadFile';
use POSIX 'strftime';
use Lab::Moose;

my $dir = tempdir( CLEANUP => 1 );

# Check numbering
my $name = our_catfile( $dir, 'abc def' );
{
    for ( 1 .. 9 ) {
        datafolder( path => $name, date_prefix => 0, time_prefix => 0 );
    }

    # Check transistion 999 => 1000

    mkdir( our_catfile( $dir, 'abc def_990' ) )
        or die "mkdir failed";

    for ( 1 .. 19 ) {
        datafolder( path => $name, date_prefix => 0, time_prefix => 0 );
    }

    my @entries = get_dir_entries($dir);

    is( @entries, 29, "created 28 folders" );
    for my $entry (@entries) {
        like(
            $entry, qr/^abc def_(00[1-9]|99[0-9]|100[0-9])$/,
            "correct numbering"
        );
    }
}

# Check date prefix
$dir = tempdir( CLEANUP => 1 );
$name = our_catfile( $dir, 'abc def' );
{
    for ( 1 .. 9 ) {
        datafolder( path => $name, time_prefix => 0 );
    }
    my @entries = get_dir_entries($dir);
    is( @entries, 9, "created 9 folders with date prefix" );
    my $date_prefix = strftime( '%Y-%m-%d', localtime() );
    for my $entry (@entries) {

        # make sure that $date_prefix is actually a date
        like(
            $entry, qr/[0-9]{4}-[0-9]{2}-[0-9]{2}/,
            "date in foldername"
        );
        like(
            $entry, qr/^${date_prefix}_abc def_00[1-9]$/,
            "correct date in folder name"
        );

    }
}

# Check time prefix
$dir = tempdir( CLEANUP => 1 );
$name = our_catfile( $dir, 'abc def' );
{
    for ( 1 .. 9 ) {
        datafolder( path => $name, date_prefix => 0 );
    }
    my @entries = get_dir_entries($dir);
    is( @entries, 9, "created 9 folders with time prefix" );

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    my $ti = $hour*60*60 + $min*60 + $sec;

    for my $entry (@entries) {

        # make sure that $time_prefix is actually a time
        like(
            $entry, qr/[0-2][0-9]-[0-5][0-9]-[0-6][0-9]/,
            "time in foldername"
        );

        $entry =~ s/_abc def_00[1-9]//;
        my ($h,$m,$s) = split '-', $entry;
        my $dev = $ti-($h*60*60+$m*60+$s);
        ok (abs($dev)<5, "correct time in folder name");

    }
}

# Check combined date/time prefix
$dir = tempdir( CLEANUP => 1 );
$name = our_catfile( $dir, 'abc def' );
{
    for ( 1 .. 9 ) {
        datafolder( path => $name );
    }
    my @entries = get_dir_entries($dir);
    is( @entries, 9, "created 9 folders with date_time prefix" );

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    my $ti = $hour*60*60 + $min*60 + $sec;
    my $date_prefix = strftime( '%Y-%m-%d', localtime() );

    for my $entry (@entries) {

        # make sure that prefix is actually a date_time
        like(
            $entry,
            qr/[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-2][0-9]-[0-5][0-9]-[0-6][0-9]/,
            "date_time in foldername"
        );

        $entry =~ s/_abc def_00[1-9]//;  # remove remaining text
        my ($d,$t)=split '_', $entry;    # date and time

        ok ($d eq $date_prefix, 'correct date in folder name');

        my ($h,$m,$s)=split '-', $t; # split up time
        my $dev = $ti - ($h*60*60+$m*60+$s);
        ok (abs($dev)<5, "correct time in folder name");

    }
}

# Check meta file and copy of script.
{
    my $folder = datafolder( path => $name,
                             date_prefix => 0, time_prefix => 0 );
    say "path: ", $folder->path();
    my $folder_name = 'abc def_001';
    is( $folder->path(), our_catfile( $dir, $folder_name ) );
    isa_ok( $folder->meta_file, 'Lab::Moose::DataFile::Meta' );

    my $meta_file = $folder->meta_file();
    my $meta      = $meta_file->path();
    is( $meta, our_catfile( $dir, $folder_name, 'META.yml' ) );

    my $contents = LoadFile($meta);

    my @expected = qw/argv user host date timestamp version/;
    hashref_contains( $contents, @expected );

    # Log some more.
    $meta_file->log( meta => { abc => '123', def => '345' } );
    $contents = LoadFile($meta);
    hashref_contains( $contents, @expected, qw/abc def/ );

    file_exists_ok( our_catfile( $folder->path, 'DataFolder.t' ) );
}

# Create folder in working directory.
{
    # Set script_name, so that the copy does not end with '.t' and is confused
    # as a test.
    my $folder = datafolder( script_name => 'script',
                             date_prefix => 0, time_prefix => 0 );
    isa_ok( $folder, 'Lab::Moose::DataFolder' );
    my $path = $folder->path();
    is( $path, 'MEAS_001', "default folder name" );
    file_exists_ok( our_catfile( $path, 'META.yml' ) );
    file_exists_ok( our_catfile( $path, 'script' ) );
    remove_tree($path);
}

sub get_dir_entries {
    my $dir = shift;
    opendir my $dh, $dir
        or die "cannot open $dir: $!";

    my @entries = readdir $dh;
    @entries = grep { $_ ne '.' and $_ ne '..' } @entries;
    return @entries;
}

sub hashref_contains {
    my $hashref = shift;
    my @keys    = @_;
    for my $key (@keys) {
        ok( exists $hashref->{$key}, "hashref contains '$key'" );
    }
}

done_testing();
