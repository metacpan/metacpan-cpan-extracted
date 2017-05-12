#!/usr/bin/perl

use strict;
use warnings;

use Test::Most;
use Test::Warnings;
use IO::File;

use lib 't/lib';
use TestClass;

use Encode;

my $builder = Test::More->builder;
binmode $builder->output         , ":utf8";
binmode $builder->failure_output , ":utf8";
binmode $builder->todo_output    , ":utf8";

my $latin1_test_file = "t/test_data/some_file_latin1.txt";
my $utf8_test_file   = "t/test_data/some_file_utf8.txt";
my $binary_file      = "t/test_data/some_file_binary.data";

sub slurp {
    my $f = shift;
    local $/;
    open my $fh, "<", $f;
    return <$fh>;
}
sub slurp_utf8 {
    my $f = shift;
    local $/;
    open my $fh, "<", $f;
    binmode $fh, ":encoding(utf8)";
    return <$fh>;
}

sub file_test_1 {

    my ($file_arg) = @_;

    if ( UNIVERSAL::isa($file_arg, "IO::Seekable") ){
        $file_arg->seek( 0, 0 );
    }

    my @args = (
        [ "plain hash", { file => $file_arg } ],
        [ "file only", $file_arg ],
        [ "arg filename", { filename => $file_arg } ],
        [ "arg path", { path => $file_arg } ],
        # [ "arg uri", { uri => $file_arg } ],
        # [ "arg url", { url => $file_arg } ],
    );

    my $f_ref = TestClass->new(@_);

    for (@args) {

        if ( UNIVERSAL::isa($file_arg, "IO::Seekable") ) {
            $file_arg->seek( 0, 0 );
        }

        my $f_obj = TestClass->new($_->[1]);

        cmp_deeply(
            {%$f_obj},
            {
                blob => $f_ref->blob,
                file => ignore,
                fh => ignore,
                defined $f_ref->filename ? (filename => $f_ref->filename) : (),
                defined $f_ref->size ? (size => $f_ref->size) : (),
            },
            $_->[0]
        );

    }

    return $f_ref;

}

sub test_files {

    my @files = @_;

    ## test from filename:
    note( "latin1 file tests" );

    file_test_1( $files[0] );

    note( "utf8 file tests" );

    my $f2 = TestClass->new({file => $files[1], encoding => "utf8" });

    is( slurp_utf8($utf8_test_file),
        $f2->blob, "read data matches file content");

    if ( not ref $files[0] ) {
        is( $f2->filename, $utf8_test_file, "file name picked up" );
        is( $f2->size, length encode( "UTF-8", $f2->blob ),
            "stored file size matches contents length" );
    }

    note( "binary file tests" );
    my $f3 = TestClass->new({file => $files[2] });
    is( -s $binary_file, length $f3->blob, "file size matches contents length" );
    is( slurp($binary_file), $f3->blob, "read data matches file content");

    if ( not ref $files[0] ) {
        is( $f3->filename, $binary_file, "file name picked up" );
        is( $f3->size, length $f3->blob, "stored file size matches contents length" );
    }

}

note("Testing on file names");
test_files( $latin1_test_file, $utf8_test_file, $binary_file );

note("Testing on IO::File's");
my @io_files = (
                IO::File->new( "< $latin1_test_file" ),
                IO::File->new( "< $utf8_test_file"   ),
                IO::File->new( "< $binary_file"      ),
               );
binmode $io_files[1], ":utf8";
test_files( @io_files );

note("Testing on scalar references");
test_files(
           \slurp( "$latin1_test_file" ),
           \slurp_utf8( "$utf8_test_file"   ),
           \slurp( "$binary_file"      ),
          );

done_testing;
