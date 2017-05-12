use strict;
use warnings;
BEGIN {
  $ENV{DEVEL_CONFESS_OPTIONS} = '';
}
use Test::More tests => 1;
use lib 't/lib';
use Capture capture => ['-MDevel::Confess'];

unlike capture <<"END_CODE", qr/Assertion failed/, "die in END";
sub error {
#line 1 test-block.pl
  die "error in something";
}
END { error() }
END_CODE
