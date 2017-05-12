#!/usr/bin/env perl 
use warnings;
use strict;

use Data::Dumper;
use File::Spec;

my $numtests;
BEGIN {
    $numtests = 6;
}

use Test::More tests => $numtests;
BEGIN { use_ok('GRID::Machine', 'is_operative') };

my $test_exception_installed;
BEGIN {
 $test_exception_installed = 1;
 eval { require Test::Exception };
 $test_exception_installed = 0 if $@;
}


my $host = $ENV{GRID_REMOTE_MACHINE} || '';
SKIP: {
      skip "Remote not operative or Test::Exception not installed", $numtests-1
    unless $test_exception_installed and  $host && is_operative('ssh', $host);

   my $tmpdir = File::Spec->tmpdir();
   my $m;
   Test::Exception::lives_ok {
     $m = GRID::Machine->new(
          host => $host,
          prefix => $tmpdir,
          log => $tmpdir,
          err => $tmpdir,
          startdir => $tmpdir,
          #debug => 12344,
          wait => 10,
          uses => [ 'Sys::Hostname' ],
    );
   } 'No fatals creating a GRID::Machine object';

    my $r = $m->eval('hostname()');
    is($r->stderr, '', 'no errors');

    $r = $m->getcwd->result;
    my $rtd = quotemeta($tmpdir);
    like($r, qr{$rtd}, "pwd is $tmpdir");

    $r = join "\n", $m->glob('rperl*')->Results ;
    like($r, qr{rperl\w+.err}, "err file found in $tmpdir");
    like($r, qr{rperl\w+.log}, "err file found in $tmpdir");
}



