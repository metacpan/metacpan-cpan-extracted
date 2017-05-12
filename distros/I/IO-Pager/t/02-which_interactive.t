use strict;
use warnings;
use Test::More 0.88;
require './t/TestUtils.pm';
t::TestUtils->import();
use Env qw( PAGER );

# Test that a reasonable pager can be found

SKIP: {
  skip_interactive();

  diag "Current PAGER: '".($PAGER||'')."'\n";
  
  require IO::Pager;
  diag "PAGER set by IO::Pager: '".($PAGER||'')."'\n";

  select STDERR;
  my $A = prompt("\nIs this reasonable? [Yn]");
  ok is_yes($A), 'Found a reasonable pager';
}

done_testing;



