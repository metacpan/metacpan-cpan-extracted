use strict;
use warnings;
use Test::More 0.88;
require './t/TestUtils.pm';
t::TestUtils->import();

# Test buffered paging

SKIP: {
  skip_interactive();

  require IO::Pager;
  
  diag "\n".
       "Reading is fun! Here is some text: ABCDEFGHIJKLMNOPQRSTUVWXYZ\n".
       "This text should be displayed directly on screen, not within a pager.\n".
       "\n";

  select STDERR;
  my $A = prompt("\nWas the text displayed directly on screen? [Yn]");
  ok is_yes($A), 'Diagnostic';
  
  {
    my $BOB = new IO::Pager *BOB, 'IO::Pager::Buffered';

    isa_ok $BOB, 'IO::Pager::Buffered';
    isa_ok $BOB, 'Tie::Handle';

    for (1..10) {
      printf BOB "Line %06i, buffer [%06i] @ %s\n",
	$_, tell(BOB), scalar localtime;
    }

    print BOB "Sleeping for 2 seconds...\n";
#    IO::Pager::Buffered::flush(*BOB);
    $BOB->flush();
    sleep 2;

    for (reverse 1..10) {
      printf BOB "Line %06i, buffer [%06i] @ %s\n",
	$_, tell(BOB), scalar localtime;
    }
    printf BOB "\nEnd of text, try pressing 'Q' to exit. @%s\n",
      scalar localtime;

    close BOB;
  }

  $A = prompt("\nWas the text displayed in a pager? [Yn]");
  ok is_yes($A), 'Buffered glob filehandle';

  $A = prompt("\nWas there a pause between the two blocks of text? [Yn]");
  ok is_yes($A), 'Flush buffered filehandle';
}

done_testing;
