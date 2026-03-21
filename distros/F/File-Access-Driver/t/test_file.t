#!/usr/bin/perl

# @author Bodo (Hugo) Barwich
# @version 2026-01-30
# @package Test for the Object::Meta::File Module
# @subpackage t/test_files.t

# This Module runs tests on the Object::Meta::File Module
#
#---------------------------------
# Requirements:
# - The Perl Module "File::Access::Driver" must be installed
#

use warnings;
use strict;

use Cwd         qw(abs_path);
use Digest::MD5 qw(md5_hex);

use Test::More;

BEGIN {
    use lib "lib";
    use lib "../lib";
}    #BEGIN

require_ok('File::Access::Driver');

use File::Access::Driver;

my $smodule = "";
my $spath   = abs_path($0);

( $smodule = $spath ) =~ s/.*\/([^\/]+)$/$1/;
$spath =~ s/^(.*\/)$smodule$/$1/;

my $driver    = undef;
my %path_data = ( 'filename' => 'testfile.txt', 'filedirectory' => 'directory1' );

subtest 'Constructors' => sub {

    #------------------------
    #Test: 'Constructors'

    subtest 'empty driver' => sub {
        $driver = File::Access::Driver->new();

        is( ref $driver, 'File::Access::Driver', "object 'File::Access::Driver': created correctly" );

        is( $driver->getFileName(),      '', "File Name: is empty as expected" );
        is( $driver->getFileDirectory(), '', "File Directory: is empty as expected" );
        is( $driver->getFilePath(),      '', "File Path: is empty as expected" );
    };
    subtest 'driver from name and directory' => sub {
        $driver = File::Access::Driver->new( 'filename' => 'testfile.txt', 'filedirectory' => 'directory1' );

        is( ref $driver, 'File::Access::Driver', "object 'File::Access::Driver': created correctly" );

        is( $driver->getFileName(),      'testfile.txt',            "File Name: set correctly" );
        is( $driver->getFileDirectory(), 'directory1/',             "File Directory: set correctly" );
        is( $driver->getFilePath(),      'directory1/testfile.txt', "File Path: built correctly" );
    };
    subtest 'object from path' => sub {
        my $driver = md5_hex('file2');

        $driver = File::Access::Driver->new( 'filepath' => 'directory1/testfile.txt' );

        is( ref $driver, 'File::Access::Driver', "object 'File::Access::Driver': created correctly" );

        is( $driver->getFileName(),      'testfile.txt',            "File Name: set correctly" );
        is( $driver->getFileDirectory(), 'directory1/',             "File Directory: set correctly" );
        is( $driver->getFilePath(),      'directory1/testfile.txt', "File Path: built correctly" );
    };
};

subtest 'File Checks' => sub {

    #------------------------
    #Test: 'File Checks'

    subtest 'file exists' => sub {
        $driver = File::Access::Driver->new( 'filepath' => $spath . 'files/out/testfile_out.txt' );

        # Make sure the file does not exist
        is( $driver->Delete(), 1, "File Delete: Delete operation 1 correct" );
        is( $driver->Exists(), 0, "File Exist: File does not exist anymore" );

        # File create test
        is( $driver->Create(),      1, "File Create: Create operation correct" );
        is( $driver->Exists(),      1, "File Exist: File does exist now" );
        is( $driver->getFileSize(), 0, "File Size: File is empty" );

        # File delete test
        is( $driver->Delete(), 1, "File Delete: Delete operation 2 correct" );
        is( $driver->Exists(), 0, "File Exist: File does not exist anymore" );

        # Clear any errors that have occurred
        $driver->clearErrors();

        # File write test
        $driver->setContentArray( [ '1st content line', '2nd content line', '3th content line' ] );

        is( $driver->Write(), 1, "File Write: Write operation correct" );

        printf(
            "Test File Exists - File '%s': Write finished with [%d]\n",
            $driver->getFileName(),
            $driver->getErrorCode()
        );
        printf(
            "Test File Exists - File '%s': Write Report:\n'%s'\n",
            $driver->getFileName(),
            ${ $driver->getReportString() }
        );
        printf(
            "Test File Exists - File '%s': Write Error:\n'%s'\n",
            $driver->getFileName(),
            ${ $driver->getErrorString() }
        );

        is( $driver->getErrorCode(),        0,  "Write Error Code: No errors have occurred" );
        is( ${ $driver->getErrorString() }, '', "Write Error Message: No errors are reported" );

        is( $driver->Exists(), 1, "File Exist: File does exist now" );
        isnt( $driver->getFileSize(), 0, "File Size: File is not empty anymore" );

        # File truncate test
        is( $driver->Truncate(),    1, "File Truncate: Truncate operation correct" );
        is( $driver->getFileSize(), 0, "File Size: File is empty now" );

        # Clean up test files
        is( $driver->Delete(), 1, "File Delete: Delete operation 3 correct" );
    };

};

subtest 'File Read / Write' => sub {

    #------------------------
    #Test: 'File Read / Write'

    subtest 'File Read' => sub {
        $driver = File::Access::Driver->new( 'filepath' => $spath . 'files/testfile.txt' );

        # Make sure the file exists
        is( $driver->Exists(), 1, "File Exist: File exists already" );
        isnt( $driver->getFileSize(), 0, "File Size: File is not empty" );

        is( $driver->Read(), 1, "File Read: Read operation correct" );

        printf(
            "Test File Read - File '%s': Read finished with [%d]\n",
            $driver->getFileName(),
            $driver->getErrorCode()
        );
        printf(
            "Test File Read - File '%s': Read Report:\n'%s'\n",
            $driver->getFileName(),
            ${ $driver->getReportString() }
        );
        printf(
            "Test File Read - File '%s': Read Error:\n'%s'\n",
            $driver->getFileName(),
            ${ $driver->getErrorString() }
        );

        is( $driver->getErrorCode(),        0,  "Read Error Code: No errors have occurred" );
        is( ${ $driver->getErrorString() }, '', "Read Error Message: No errors are reported" );

        my $content = $driver->getContent();

        printf(
            "Test File Read - File '%s': Read Content (%s):\n'%s'\n",
            $driver->getFileName(),
            length( ${$content} ),
            ${$content}
        );

        isnt( length( ${$content} ), 0,  "File Content: Length is correct" );
        isnt( ${$content},           '', "File Content: is not empty" );

        my $content_array = $driver->getContentArray();

        printf(
            "Test File Read - File '%s': Read Content Lines (%s):\n'%s'\n",
            $driver->getFileName(),
            scalar( @{$content_array} ),
            join( '|', @{$content_array} )
        );

        is( scalar( @{$content_array} ), 6, "File Content Lines: 6 Lines were read" );
    };

    subtest 'File Write' => sub {
        $driver = File::Access::Driver->new( 'filepath' => $spath . 'files/out/testfile_out.txt' );

        # Make sure the file does not exist
        is( $driver->Delete(), 1, "File Delete: Delete operation 1 correct" );
        is( $driver->Exists(), 0, "File Exist: File does not exist anymore" );

        $driver->writeContent(q(This is the multi line content for the test file.

It will be written into the test file.
The file should only contain this text.
Also the file should be created.
));

        printf(
            "Test File Exists - File '%s': Write finished with [%d]\n",
            $driver->getFileName(),
            $driver->getErrorCode()
        );
        printf(
            "Test File Exists - File '%s': Write Report:\n'%s'\n",
            $driver->getFileName(),
            ${ $driver->getReportString() }
        );
        printf(
            "Test File Exists - File '%s': Write Error:\n'%s'\n",
            $driver->getFileName(),
            ${ $driver->getErrorString() }
        );

        is( $driver->getErrorCode(),        0,  "Write Error Code: No errors have occurred" );
        is( ${ $driver->getErrorString() }, '', "Write Error Message: No errors are reported" );

        is( $driver->Exists(), 1, "File Exist: File does exist now" );
        isnt( $driver->getFileSize(), 0, "File Size: File is not empty anymore" );
    };
};

done_testing();
