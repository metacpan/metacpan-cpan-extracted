use strict;
use warnings;

use Test::More;
use LWP::UserAgent::Paranoid::Test;
use Net::DNS::Paranoid;

my ($SERVER, $TCP) = server(sub { [200,[],["OK"]] });
my $ua = create_ua_ok();

get_status_is($ua, $SERVER, 403, "localhost is forbidden");

$ua->resolver->whitelisted_hosts(["127.0.0.1"]);
get_status_is($ua, $SERVER, 200, "localhost is now OK");

my ($ok, $err) = (eval { $ua->resolver( Net::DNS::Paranoid->new ) } || 0, $@);
ok !$ok, "couldn't set new resolver";
like $err, qr/resolver is read-only/, "resolver is read-only";

done_testing;
