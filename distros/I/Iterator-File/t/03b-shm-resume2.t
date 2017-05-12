#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
require 't/util.pl';

use Iterator::File;

## Is IPC::Shareable present?  If not, don't bother testing it...
if(eval "use IPC::Shareable; 1") {
  plan tests => 3;
} else {
  plan skip_all => 'Skipping IPC::Shareable related tests (IPC::Shareable not present)...';
}


my $ipc_key = 9997;

## resume, part 2
{
  my $file = 't/data/ten_lines.txt'; 
  my $expected = join("", (slurp( $file ))[3 .. 9] );

  my $i;
  $i = iterator_file( $file,
                      'ipc_key'     => $ipc_key,
                      'chomp'       => 0,
                      'resume'      => 1,
                      'state_class' => 'Iterator::File::State::IPCShareable',
                    );
  
  my $actual = "";
  do { $actual .= $i->value(); } while $i->next();

  is( $actual, $expected, "resume, part 2");
}


## make sure cleanup happened correclty
{
  my $marker;
  my $ipc_object;
  eval {
    ## We do this to silence an expected error from IPC::Shareable if we can
    local *STDERR;
    if (-e '/dev/null') {
      open(F, ">", "/dev/null") || die ("Couldn't open /dev/null: $!");
      *STDERR = *F;
    }
    $ipc_object = tie $marker, 'IPC::Shareable', $ipc_key;
  };

  ok( defined( $@ ) , "shm segment cleanup - 1" );
  ok( !defined( $ipc_object),   "shm segement cleanup - 2");
}
