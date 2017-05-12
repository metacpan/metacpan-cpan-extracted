#!perl
use strict;
use warnings;

use File::Basename;
use lib dirname($0);

use constant TESTCOUNT => 12;
use JSON;
use Test::More tests => &TESTCOUNT;
use Try::Tiny;

use MyTest;

use_ok('JIRA::REST::Class');

TestServer_setup();

# testing connection to server via JIRA::REST::Class
try {
    my $url    = TestServer_url();
    my $port   = TestServer_port();
    my $user   = 'username';
    my $pass   = 'password';
    my $client = JIRA::REST::Class->new($url, $user, $pass);

    ok( $client, qq{client returned from new()} );
    ok(
        ref($client) && ref($client) eq 'JIRA::REST::Class',
        "client is blessed as JIRA::REST::Class"
    );

    is( $client->url, $url,
        "client->url returns JIRA url $url");

    is( $client->username, $user,
        "client->username returns JIRA username");

    is( $client->password, $pass,
        "client->password returns JIRA password");

    my $pid = TestServer_pid();

    isnt( $pid, undef, 'PID defined for server' );

    like( $pid, qr/^\d+$/, "PID '$pid' is numeric" );

    ok( TestServer_is_running(),
        sprintf("server is running on PID %s",
                $pid || 'undef' ));

    ok( TestServer_is_listening(),
        sprintf("server is listening on port %s",
                $port || 'undef' ));

    is( TestServer_test(), '{"GET":"SUCCESS"}',
        "$url/test reports success" );

    is( TestServer_stop(), '{"quit":"SUCCESS"}',
        "$url/quit reports success" );
}
catch {
    my $error = $_;  # Try::Tiny puts the error in $_
    warn "Tests died: $error";
};

done_testing();
exit;
