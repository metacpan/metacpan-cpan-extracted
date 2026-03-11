use strict;
use warnings;
use Test::More;
use EV;
use EV::MariaDB;

plan tests => 2;

# Test that objects are properly cleaned up
{
    {
        my $m = EV::MariaDB->new(on_error => sub {});
        ok(defined $m, 'object created');
    }
    # $m goes out of scope - DESTROY should be called
    ok(1, 'object destroyed without crash');
}
