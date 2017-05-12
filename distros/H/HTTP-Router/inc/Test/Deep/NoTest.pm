#line 1
use strict;
use warnings;

# this is for people who don't want Test::Builder to be loaded but want to
# use eq_deeply. It's a bit hacky...

package Test::Deep::NoTest;

use vars qw( $NoTest );

{
  local $NoTest = 1;
  require Test::Deep;
}

sub import {
  my $import = Test::Deep->can("import");
  # make the stack look like it should for use Test::Deep
  my $pkg = shift;
  unshift(@_, "Test::Deep");
  goto &$import;
}

1;

