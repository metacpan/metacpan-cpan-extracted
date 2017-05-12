#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;

use Test::More;
require 't/util.pl';

use Iterator::File;

## Is IPC::Shareable present?  If not, don't bother testing it...
if(eval "use IPC::Shareable; 1") {
  plan tests => 2;
} else {
  plan skip_all => 'Skipping IPC::Shareable related tests (IPC::Shareable not present)...';
}

## resume, part 1 -- churn through 5 lines.  2nd process should get the next 5
{
  my $file = 't/data/ten_lines.txt'; 
  my $expected = join("", (slurp( $file ))[0..2] );

  ## This seems odd, but ensures cleanup from a prior test took place &
  ## makes results consistent from run-to-run
  my $i;
  $i = iterator_file( $file,
                      'ipc_key'     => '9997',
                      'chomp'       => 0,
                      'resume'      => 1,
                      'state_class' => 'Iterator::File::State::IPCShareable',
                    );
  $i->finish();

  
  $i = iterator_file( $file,
                      'ipc_key'     => '9997',
                      'chomp'       => 0,
                      'resume'      => 1,
                      'state_class' => 'Iterator::File::State::IPCShareable',
                    );
  
  my $state_object = $i->state_object();
  is( $state_object->marker(), 0, "starting at 0");
  
  my $actual = "";
  $actual .= $i->next() for (1 .. 3);

  is( $actual, $expected, "resume, part 1");
}
