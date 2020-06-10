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

    #XXX No longer needed with return of control to host loop instead of
    #XXX repeating input loop, but cannot hurt to preserve the instructions
    warn "\n\nCurrent IO::Pager::Less is suboptimal \e[7;5m*** Press Ctrl-L to refresh ***\e[0m\n\n\n";

    $BOB->print("This pager is implemented in perl\n") foreach 1..25;
    $BOB->print("\nEnd of text, try pressing 'Q' to exit.\n");
  }

  select STDERR;
  my $A1 = prompt("\nDid you see 'This pager is implemented in perl' in a pager? [Yn]");
  ok is_yes($A1), 'OO, factory instantiation';

}

done_testing;
