use Test::Most;
use DracPerl::Client;

BEGIN {
    $ENV{LWP_UA_MOCK}      ||= 'playback';
    $ENV{LWP_UA_MOCK_FILE} ||= 't/mocked/idrac.out';
}

use LWP::UserAgent::Mockable;
isa_ok my $drac_client = DracPerl::Client->new(
    {   user     => $ENV{DRAC_USR} || "username",
        password => $ENV{DRAC_PWD} || "password",
        url      => $ENV{DRAC_URL} || "https://dracip",
    }
    ),
    "DracPerl::Client", "Object instanciated correctly";

is $drac_client->openSession(), 1, "sucessfully opened a session";

is length $drac_client->token, 32, "Token is present after login";

ok my $session_saved = $drac_client->saveSession(),
    "Session saved successfully";

ok my $result = $drac_client->get({
    commands => ["fans"],
}),
    "Data is retrieved sucessfully";

ok my $fans = $result->{fans};

is scalar @{$fans->list}, 5, "Fans data is correct";

is $drac_client->isAlive(), 1, "Session is still alive";

ok my $drac_client_bis = DracPerl::Client->new(
    {   user     => "dummy",
        password => "dummy",
        url      => $ENV{DRAC_URL} || "https://dracip",
    }
    ),
    "Second client created";
is $drac_client_bis->openSession($session_saved), 1,
    "Reopened the same session on client bis";
is $drac_client_bis->isAlive, 1, "Session is working on client bis";

ok $drac_client->closeSession(), "Session closed correctly";

is $drac_client->isAlive(), 0, "Session is now dead";

is $drac_client->token, 0,
    "Token has been wiped because session has been closed";

END {
    LWP::UserAgent::Mockable->finished;
}

done_testing();
