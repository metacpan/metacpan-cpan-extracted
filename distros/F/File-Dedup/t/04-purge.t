#!/usr/bin/env perl

use strict;
use warnings;

use File::Dedup;
use Test::More tests => 1;

my $TEST_DIRECTORY = 'test_files';
subtest 'File::Dedup-_purge_files' => sub {
   plan tests => 2;

   setup_test();
   
   my $deduper = File::Dedup->new( directory => $TEST_DIRECTORY, ask => 0 );
   $deduper->_purge_files( [glob("$TEST_DIRECTORY/*")] );

   ok( ! -e "$TEST_DIRECTORY/file1", 'file1 was purged' );
   ok( ! -e "$TEST_DIRECTORY/file2", 'file2 was purged' );
   
   teardown_test();
};

sub setup_test {
   mkdir $TEST_DIRECTORY 
      or die "Unable to make directory: $!";

   foreach my $filename ( qw(file1 file2) ) {
      open my $fh, '>', "$TEST_DIRECTORY/$filename"
         or die "Unable to open file: $!";

      print {$fh} " ";
      close($fh);
   }
}

sub teardown_test {
   foreach my $filename ( glob("$TEST_DIRECTORY/*") ) {
      unlink($filename) 
         or die "Unable to delete file '$filename': $!";
   }

   rmdir $TEST_DIRECTORY
      or die "Unable to remove directory '$TEST_DIRECTORY': $!";
}
