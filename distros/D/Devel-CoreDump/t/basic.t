use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Devel::CoreDump' }

my $fh;
eval {
    $fh = Devel::CoreDump->get;
};

ok(!$@);
isa_ok($fh, 'IO::Handle');
