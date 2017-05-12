#!/usr/bin/env perl

use strict;
use warnings;

use lib qw(t/lib);

use Test::More tests => 4;

# Confirm that values in %^H don't leak across require()

{
    use Devel::Pragma qw(:all);

    BEGIN { hints->{'Devel::Pragma::Test'} = 1 }
    BEGIN { is($^H{'Devel::Pragma::Test'}, 1) }

    use leak;

    BEGIN { is($^H{'Devel::Pragma::Test'}, 1) }

    my $hh = leak::hh();
    isa_ok($hh, 'HASH');
    is($hh->{'Devel::Pragma::Test'}, undef);
}
