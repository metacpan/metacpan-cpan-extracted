use strict;
use warnings;
use Test::More 0.88;
require './t/TestUtils.pm';
t::TestUtils->import();
use IO::Pager;

SKIP: {
  skip_interactive();

  my $A;

  PAUSE: {
    my $token = new IO::Pager local *RIBBIT, 'Buffered';
    isa_ok $token, 'IO::Pager::Buffered';

    my $PID = $token->PID;
    $token->print("Pager child '$token->{pager}' is PID $PID\n");
    $token->print("\nEnd of text, try pressing 'Q' to exit.\n");
    is $PID, $token->{child}, "PID($PID)";
    sleep 1;
  }
  $A = prompt("\nWas there a pause before the text appeared? [Ynr] (r-epeat)");
  goto PAUSE if $A eq 'r';
  ok is_yes($A), 'Implicit close of buffered OO filehandle';


  {
    IO::Pager::open local *RIBBIT, 'Buffered';
    print RIBBIT "No toad sexing allowed";
    print RIBBIT "\nEnd of text, try pressing 'Q' to exit.\n"
  }
  $A = prompt("\nIs toad sexing allowed? (And posted before commentary on trains) [yN]");
  goto PAUSE if $A eq 'r';
  ok is_no($A), 'Implicit close of buffered glob filehandle';


  #Possible future test, but meanwhile is here to ensure proper destruction,
  #since the output of this block would appear before above if no implicit close
  {
    new IO::Pager *MARY;
    print MARY "I like trains\n";
    print MARY "\nEnd of text, try pressing 'Q' to exit.\n";
    close(MARY);
  }

}

done_testing;
