use strict;
use warnings;
use Test::More 0.88;
require './t/TestUtils.pm';
t::TestUtils->import();

# Test OO interface

SKIP: {
  skip_interactive();

  use blib;
  require IO::Pager;
  require IO::Pager::Buffered;
  {
#   my $BOB = new IO::Pager::Buffered or die "Failed to create PAGER FH $!";
    my $BOB = new IO::Pager local *STDOUT, 'Buffered' or die "Failed to create PAGER FH $!";

    isa_ok $BOB, 'IO::Pager::Buffered';
    
    $BOB->print("OO factory filehandle\n") foreach 1..25;
    $BOB->print("\nEnd of text, try pressing 'Q' to exit.\n");
  }

  select STDERR;
  my $A1 = prompt("\nDid you see 'OO factory filehandle' in your pager? [Yn]");
  ok is_yes($A1), 'OO, factory instantiation';

  require IO::Pager::Unbuffered;

  {
    my $BOB = new IO::Pager::Unbuffered or die "Failed to create PAGER FH $!";

    isa_ok $BOB, 'IO::Pager::Unbuffered';

    $BOB->say("OO subclass filehandle") foreach 1..25;
    $BOB->say("\nEnd of text, try pressing 'Q' to exit.");
    #XXX Close required because pager is not terminated on DESTROY
    $BOB->close();
  }

  my $A2 = prompt("\nDid you see 'OO subclass filehandle' in your pager? [Yn]");
  ok is_yes($A2), 'OO, subclass instantiation';
}

done_testing;
