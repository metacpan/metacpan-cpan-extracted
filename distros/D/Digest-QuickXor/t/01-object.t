use strict;
use warnings;
use utf8;
use v5.24;

use Test::More;

my $package;

BEGIN {
  $package = 'Digest::QuickXor';
  use_ok $package or exit;
}

note 'Constructor';
can_ok $package, 'new';

note 'Object';
ok my $object = $package->new, 'Create object';
my @methods = qw|add addfile b64digest|;
can_ok $object, $_ for @methods;

note 'Internal qx object';
ok my $qx = $object->{_qx};
isa_ok $qx, 'Digest::QuickXor::HashPtr', 'Hash pointer';
@methods = qw|add b64digest reset DESTROY|;
can_ok $qx, $_ for @methods;

done_testing();
