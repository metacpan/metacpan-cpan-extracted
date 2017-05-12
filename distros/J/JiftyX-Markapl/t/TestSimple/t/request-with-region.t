#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use lib 't/TestSimple/lib/TestSimple';
use Test::More;
use Jifty::Test;
use Jifty::Test::WWW::Mechanize;

my $server = Jifty::Test->make_server;
my $server_url = $server->started_ok;

my $mech = Jifty::Test::WWW::Mechanize->new;

$mech->get_ok("${server_url}/hi1");

$mech->content_is(qq{<h1>HI One</h1><script type="text/javascript">\nnew Region('hi2',{},'/hi2',null,null);\n</script><div id="region-hi2" class="jifty-region"><h1>HI Two</h1></div>});

done_testing;
