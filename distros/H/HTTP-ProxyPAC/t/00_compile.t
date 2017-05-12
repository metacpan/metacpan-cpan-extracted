use strict;
use Test::More tests => 1;

BEGIN { use_ok   'HTTP::ProxyPAC' 
     or BAIL_OUT ("Without a usable HTTP::ProxyPAC there is nothing to test");
}
