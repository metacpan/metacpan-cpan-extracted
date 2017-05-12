use strict;
use Test::More;
use Test::Requires 'Geo::Hash';

while (<xt/compat/*.t>) {
    subtest $_ => sub { do $_ };
}

done_testing();
