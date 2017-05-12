
use strict;

use Test::More;

my $have_scalar_util = 0;
if (eval "use Scalar::Util 1.09 (); 1") {
  $have_scalar_util = 1;
  plan tests => 8;
} else {
  plan tests => 6;
}

use_ok('Email::Address');

# We want to copy-on-write if we've got an object that is referenced by a
# cache.  If we don't... bad things happen.

my $ORIGINAL = 'original@example.com';
my $UPDATED  = 'updated@example.com';

my $orig_refaddr;

{
  my ($addr) = Email::Address->parse($ORIGINAL);

  isa_ok($addr, 'Email::Address');

  $orig_refaddr = Scalar::Util::refaddr($addr) if $have_scalar_util;

  is($addr->address, $ORIGINAL, "address is parsed in properly");

  $addr->address($UPDATED);

  is($addr->address, $UPDATED, "the address udpated properly");
}

my ($addr) = Email::Address->parse($ORIGINAL);

if ($have_scalar_util) {
  isnt(
    Scalar::Util::refaddr($addr),
    $orig_refaddr,
    "the new copy isn't the same refaddr as we had previously",
  );
}

isa_ok($addr, 'Email::Address');

is($addr->address, $ORIGINAL, "address is parsed in properly");

if ($have_scalar_util) {
  my ($addr2) = Email::Address->parse($ORIGINAL);
  is(
    Scalar::Util::refaddr($addr),
    Scalar::Util::refaddr($addr2),
    "we still get a cached copy",
  );
}
