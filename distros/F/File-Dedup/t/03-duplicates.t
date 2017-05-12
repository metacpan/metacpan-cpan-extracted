#!/usr/bin/env perl

use strict;
use warnings;

use File::Dedup;
use Sub::Override;
use Test::More tests => 3;

subtest 'File::Dedup-_handle_duplicates[ask=0]' => sub {
   plan tests => 1;

   my $deduper = File::Dedup->new( directory => '.', ask => 0 );
   is_deeply( 
      [ $deduper->_handle_duplicates( STUB_DUPLICATES() ) ],
      [qw(file2 file4)],
      'when ask = 0, the first duplicate is always kept',
   );
              
};

subtest 'File::Dedup-_handle_duplicates[ask=1]' => sub {
   plan tests => 1;

   my $override = Sub::Override->new( 
      'File::Dedup::_prompt' => sub { 1 }, # keep second duplicated file
   );
   my $deduper = File::Dedup->new( directory => '.' );
   is_deeply( 
      [ $deduper->_handle_duplicates( STUB_DUPLICATES() ) ],
      [qw(file1 file3)],
      'when ask = 1 and 1 is chosen as the index of the file to keep, the second duplicate is kept',
   );
   $override->restore;           
};

subtest 'File::Dedup-_handle_duplicates[ask=1]-SKIP' => sub {
   plan tests => 1;

   my $override = Sub::Override->new( 
      'File::Dedup::_prompt' => sub { -1 }, # skip all deletes 
   );
   my $deduper = File::Dedup->new( directory => '.' );
   is_deeply( 
      [ $deduper->_handle_duplicates( STUB_DUPLICATES() ) ],
      [],
      'when ask = 1 and -1 is chosen as the index of the file to keep, no files are purged',
   );
   $override->restore;           
};

sub STUB_DUPLICATES {
   return {
      '4d7ef84687c896644d3c1b02abcafdab' => [qw(file1 file2)],
      'fb48fa5d23a142ce48af2e8562580e1a' => [qw(file3 file4)],
   };
}
