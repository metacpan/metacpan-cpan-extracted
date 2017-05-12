use strict;
use warnings;
use Test::More 0.88;
require './t/TestUtils.pm';
t::TestUtils->import();

# Test unbuffered paging

SKIP: {
  skip_interactive();
  
  require IO::Pager;


  {
    my $BOB;
    local $STDOUT = IO::Pager::open($BOB, 'IO::Pager::Buffered');

    is ref($BOB), 'GLOB', 'Gensym';
    isa_ok $STDOUT, 'IO::Pager::Buffered';
    isa_ok $STDOUT, 'Tie::Handle';

    eval {
      my $i = 0;
      for (1..20) {
        printf($BOB "%06i There is more than one to do it.\n", $_);
      }
      printf $BOB "\nEnd of text, try pressing 'Q' to exit.\n", $_;
    };
    close($BOB);
  }

  my $A = prompt("\nWas the text displayed in a pager? [Yn]");
  ok is_yes($A), 'Buffered scalar filehandle';
}

done_testing;
