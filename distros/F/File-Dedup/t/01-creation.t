#!/usr/bin/env perl

use strict;
use warnings;

use File::Dedup;
use Test::Exception;
use Test::More tests => 3;

subtest 'File::Dedup-test-defaults' => sub {
   plan tests => 4;
   
   {
      my $deduper = File::Dedup->new( directory => '.' );
      is( $deduper->recursive, 0, 'recursive search is *off* by default' );
      is( $deduper->ask, 1, 'asking before delete is *on* by default' );
   }
   
   { # ensure defaults don't override supplied options
      my $deduper = 
         File::Dedup->new( directory => '.', ask => 0, recursive => 1 );
      is( $deduper->recursive, 1, 'recursive search is on when explicitly passed in' );
      is( $deduper->ask, 0, 'asking before delete is *off* when explicitly passed in' );
   }
};

subtest 'File::Dedup-valid-options' => sub {
   plan tests => 4;

   lives_ok {
      File::Dedup->new( directory => '.' );
   } 'lives ok when passed required directory option';

   lives_ok {
      File::Dedup->new( directory => '.', ask => 0 );
   } 'lives ok when passed required directory option, optional ask option';

   lives_ok {
      File::Dedup->new( directory => '.', ask => 0, recursive => 1 );
   } 'lives ok when passed required directory option, optional ask, and recursive options';

   lives_ok {
      File::Dedup->new( directory => '.', ask => 0, recursive => 1, group => 1 );
   } 'lives ok when passed required directory option, optional ask, recursive, and group options';
   
};

subtest 'File::Dedup-invalid-options' => sub {
   plan tests => 3;

   throws_ok {
      File::Dedup->new
   } qr/Must pass a directory to process/;

   throws_ok {
      File::Dedup->new( directory => '../dist.ini' )
   } qr|Supplied directory argument '../dist.ini' is not a directory|;

   throws_ok {
      File::Dedup->new( directory => '.', fake_option => 1 )
   } qr/Invalid argument 'fake_option' passed to new/;   
};

