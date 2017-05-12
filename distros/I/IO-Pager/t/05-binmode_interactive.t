use strict;
use warnings;
use Test::More 0.88;
require './t/TestUtils.pm';
t::TestUtils->import();

# Test paging binary content

SKIP: {
  skip_interactive();
  skip_old_perl();

  require IO::Pager;

  my $warnings;
  eval {
    # Promote warnings to errors so we can catch them
    local $SIG{__WARN__} = sub { $warnings .= shift };

    # Stream unicode in a pager
    local $STDOUT = new IO::Pager *BOB, ':utf8', 'IO::Pager::Buffered';


    printf BOB "Unicode Z-inverted carat: \x{17D}\n"; #Ž
    printf BOB "Unicode Copyright < Copyleft: \x{A9} < \x{2184}\x{20DD}\n"; #© < ↄ⃝
    printf BOB "Unicode camel: \x{1f42a}\n", $_; #	🐪 
    printf BOB "\nEnd of text, try pressing 'Q' to exit.\n";
    close BOB;
  };

  is $warnings, undef, 'No wide character warnings';

  binmode STDOUT, ":utf8";
  my $A = prompt("\nWere Unicode characters like \x{17D} and \x{A9},\nor perhaps a bytecode placeholder such as <U+1F42A> displayed in the pager? [Yn]");
  ok is_yes($A), 'Binmode layer selection / pager Unicode support';
}

done_testing;
