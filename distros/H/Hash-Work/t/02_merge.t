#!/usr/bin/perl

use strict;
use warnings;
use lib '../lib','lib';


use Test::More tests => 3;


use Hash::Work qw(merge_hashes);



my $h1 = {
          'def' => '456',
          'foo' => 'ooo',
         };


my $h2 = {
          'def' => '777',
          'more' => 'mmm',
         };


my $res = merge_hashes($h1,$h2);


 is( $res->{'def'} , '777' ,  "data at place" );
 is( $res->{'more'} , 'mmm' ,  "data at place" );
 is( $res->{'foo'} , 'ooo' ,  "data at place" );
 



1;
