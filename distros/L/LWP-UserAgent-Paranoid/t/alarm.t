use strict;
use warnings;

use Test::More;
use LWP::UserAgent::Paranoid::Test;

my ($SERVER, $TCP) = server(sub {
    my $env  = shift;
    local $_ = $env->{PATH_INFO};
    if (m{/sleep/(\d+)(?:/|$)}) {
        sleep $1;
    }
    if (m{/redir(/.+)$}) {
        return [302,["Location" => $1],[]];
    }
    return [200,[],["OK"]];
});

my $ua = create_ua_ok();
$ua->resolver->whitelisted_hosts(["127.0.0.1"]);
$ua->request_timeout(5);

test_timeouts();

eval {
    local $SIG{ALRM} = sub { die "ALARM!\n"; };
    test_timeouts();
};
ok !$@, "Caught no error" or diag "Error: $@";

sub test_timeouts {
    get_status_is($ua, "$SERVER/sleep/6", 500, "4s sleepy request timed out");
    get_status_is($ua, "$SERVER/sleep/1", 200, "1s sleepy request succeeded");
    get_status_is($ua, "$SERVER/sleep/1/redir/sleep/1", 200, "2s sleepy request with redirect succeeded");
    get_status_is($ua, "$SERVER/sleep/3/redir/sleep/3", 500, "6s sleepy request with redirect timed out");
}

done_testing;
