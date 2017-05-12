use strict;
use warnings;
use File::Spec;
use Test::More 0.88;
require './t/TestUtils.pm';
t::TestUtils->import();
no warnings; $^W = 0; #Avoid: Can't exec "/dev/null": Permission denied

use IO::Pager;

SKIP: {
  skip("Skipping because Windows has to be different^Wdifficult", 1)
    if $^O =~ /MSWin32|cygwin/;

  undef $ENV{PAGER};
  eval{ my $token = new IO::Pager };
  like($@, qr/The PAGER environment variable is not defined/, 'PAGER undefined since find_pager()');
  
  $ENV{PAGER} = File::Spec->devnull();
  eval{ my $token = new IO::Pager or die $!};
  like($@, qr/Could not pipe to PAGER/, 'Could not create pipe');
}

done_testing;

