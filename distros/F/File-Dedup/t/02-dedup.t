#!/usr/bin/env perl

use strict;
use warnings;

use File::Dedup;
use Test::More tests => 1;

my $TEST_DIRECTORY = 'test_files';
subtest 'File::Dedup-dedup' => sub {
   plan tests => 2;

   setup_test();

   my $deduper = File::Dedup->new( directory => $TEST_DIRECTORY, ask => 0 );
   $deduper->dedup;

   ok( -e "$TEST_DIRECTORY/file1", 'first duplicate was kept' );
   ok( -e "$TEST_DIRECTORY/file3", 'non-duplicated file was kept' );

   teardown_test();
};

sub setup_test {
   mkdir $TEST_DIRECTORY 
      or die "Unable to make directory: $!";

   my $teststring = 'abc' x 9;
   foreach my $filename ( qw(file1 file2 file3) ) {
      open my $fh, '>', "$TEST_DIRECTORY/$filename"
         or die "Unable to open file: $!";

      if ( $filename eq 'file3' ) { $teststring .= '!!!!'; }
      print {$fh} "$teststring";
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
