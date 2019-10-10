use strict;
use warnings;
use Test::More 0.88;
require './t/TestUtils.pm';
t::TestUtils->import();

BEGIN{ $IO::Pager::less::BLIB = $IO::Pager::less::BLIB = 1; }

# Test OO interface

SKIP: {
  skip_interactive();
  skip("Windows is currently unsupported") if $^O =~ /MSWin32/;

  require IO::Pager;
  require IO::Pager::less;
  {
    my $BOB = new IO::Pager local *STDOUT, 'less' or die "Failed to create PAGER FH $!";

    isa_ok $BOB, 'IO::Pager::less';
    
    $BOB->print("OO factory filehandle\n") foreach 1..25;
    $BOB->print("\nEnd of text, try pressing 'Q' to exit.\n");
  }

  select STDERR;
  my $A1 = prompt("\nDid you see 'OO factory filehandle' in your pager? [Yn]");
  ok is_yes($A1), 'OO, factory instantiation';

  {
    my $BOB = new IO::Pager::less or die "Failed to create PAGER FH $!";

    isa_ok $BOB, 'IO::Pager::less';

    $BOB->say("OO subclass filehandle") foreach 1..25;
    $BOB->say("\nEnd of text, try pressing 'Q' to exit.");
    #XXX Close required because pager is not terminated on DESTROY
    $BOB->close();
  }

  my $A2 = prompt("\nDid you see 'OO subclass filehandle' in your pager? [Yn]");
  ok is_yes($A2), 'OO, subclass instantiation';
}

done_testing;
