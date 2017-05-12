
use strict;
use lib "lib";
use Test::More;
require "./t/must_die.pl";
plan tests => 1;
eval q{ use Croak; confess; };
use Exception::ThrowUnless qw(:all);
system("chmod -R 700 tmp");
system("rm -fr tmp");

ok("sky still up there.");
