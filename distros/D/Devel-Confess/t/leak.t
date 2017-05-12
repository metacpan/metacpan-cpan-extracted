use strict;
use warnings;
BEGIN {
  $ENV{DEVEL_CONFESS_OPTIONS} = '';
}
use Scalar::Util;
use Test::More
  defined &Scalar::Util::weaken ? (tests => 4)
    : (skip_all => "Can't prevent leaks without Scalar::Util::weaken");

use Devel::Confess;

my $gone = 0;
{
  package MyException;
  sub new {
    bless {}, __PACKAGE__;
  }
  sub throw {
    die __PACKAGE__->new;
  }
  sub DESTROY {
    $gone++;
  }
}

eval {
  MyException->throw;
};
my $class = ref $@;
is $gone, 0, "exception not destroyed when captured";
undef $@;
is $gone, 1, "exception destroyed after \$@ cleared";

ok !UNIVERSAL::can($class, 'DESTROY'), "temp packages don't leak";

$gone = 0;
eval {
  MyException->throw;
};
Devel::Confess->CLONE;
undef $@;
is $gone, 1, "exception destroyed after \$@ cleared";
