#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use File::ELAN;
plan tests => 1;

use Data::Dumper;

my $elan = File::ELAN->read("t/test.eaf");
$elan->write("t/test2.eaf");

my $elan2 = File::ELAN->read("t/test2.eaf");

is_deeply($elan2->{annotations}, {
          'tier1' => [
                     {
                       'value' => 'An annotation',
                       'id' => 'a1',
                       'end' => '2.5',
                       'start' => '0.92'
                     },
                     {
                       'value' => 'Another annotation',
                       'id' => 'a2',
                       'end' => '3.78',
                       'start' => '3.33'
                     }
                   ],
          'tier2' => [
                     {
                       'value' => 'A third annotation',
                       'id' => 'a3',
                       'end' => '3.24',
                       'start' => '2.23'
                     }
                   ],                   
        }, "Data checks out OK");

END { unlink("t/test2.eaf"); }