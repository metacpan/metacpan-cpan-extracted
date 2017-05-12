#!/usr/local/bin/perl -w
# Provided by Alex White. Thanks Alex!
use strict;
my $numtests;
BEGIN {
$numtests = 3;
}

use Test::More tests => $numtests;
BEGIN { use_ok('GRID::Machine', 'is_operative') };

my $test_exception_installed;
BEGIN {
 $test_exception_installed = 1;
 eval { require Test::Exception };
 $test_exception_installed = 0 if $@;
}

my $host = $ENV{GRID_REMOTE_MACHINE};

my $machine;
SKIP: {
   skip "Remote not operative or Test::Exception not installed", $numtests-1
 unless ($test_exception_installed and  $host && is_operative('ssh -p 22 -X', $host));

   my $ssh_options = [ '-o', "RemoteForward=localhost:12348 localhost:12349" ];

   Test::Exception::lives_ok {
       $machine = GRID::Machine->new(
           host       => $host,
           sshoptions => $ssh_options,
       );
   } 'No fatals creating a GRID::Machine object with "-o"';

# test the format "machine:port" and "sshoptions" in string form
   

   Test::Exception::lives_ok {
       $machine = GRID::Machine->new(
                host => $host, 
                sshoptions => '-p 22 -X',
                uses => [ 'Sys::Hostname' ]
     );
   } 'No fatals creating a GRID::Machine object with "-p 22 -X"';


} # end SKIP block
