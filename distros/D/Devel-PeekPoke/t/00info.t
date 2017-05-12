use strict;
use warnings;

use Test::More;
use Devel::PeekPoke::Constants qw/PTR_SIZE PTR_PACK_TYPE BIG_ENDIAN/;
use Config;

diag("\nPerl: $]\n");
diag(sprintf "%s: %s\n", $_, __PACKAGE__->$_ ) for (qw/BIG_ENDIAN PTR_PACK_TYPE PTR_SIZE/);
diag("IV_SIZE: $Config{ivsize}\n");

if (
  PTR_SIZE != $Config{ivsize}
    and
  eval { require Devel::PeekPoke::PP }
    and
  defined (my $offset = eval { Devel::PeekPoke::PP::_XPV_IN_SVU_OFFSET() })
) {
  diag "Pointer offset within an IV_SIZEd UNION: $offset\n"
}

ok('this is not a test, it just serves to diag() out what this system is using, for the curious (me)');
done_testing;
