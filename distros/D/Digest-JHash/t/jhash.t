use Test;
use strict;

BEGIN { plan tests => 5 };
use Digest::JHash;

ok(1); # If we made it this far, we loaded ok

ok( Digest::JHash::jhash("hello world"), 447289830 );
ok( Digest::JHash::jhash("goodbye cruel world"), 969307542 );

# make sure we don't explode unexpectedly if passed null
{
    # kill warnings in this block
    local $^W = 0;
    ok( Digest::JHash::jhash(undef), 0 );
    ok( Digest::JHash::jhash(''), 0 );
}

# warnings are active again here
