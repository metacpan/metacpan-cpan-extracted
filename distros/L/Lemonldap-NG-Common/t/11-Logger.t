use Test::More;
use t::TestPsgi;
use Plack::Test;
use HTTP::Request::Common;

subtest "Check logging API" => sub {
    my $args = { logger => 't::TestLogger', userLogger => 't::TestLogger' };
    my $psgi = new_ok( 't::TestPsgi' => [$args] );
    $psgi->init($args);

    my $server = Plack::Test->create( $psgi->run );

    my $res = $server->request( GET "/" );
    is( $res->code, 200, "Returned HTTP code 200" );
    $psgi->logger->contains( "notice", "Request handled by TestPsgi handler" );
    $psgi->userLogger->contains( "info", "User logger trace" );

    # no auditLogger defined: audit logs are sent to userLogger
    $psgi->userLogger->contains( "notice", "audit" );

  # Audit log without a message is reported as an error with correct stack trace
    $psgi->userLogger->contains( "info",
        qr/auditLogger internal error: no message provided at .*TestPsgi.pm/ );
};

subtest "Check audit API" => sub {
    my $args = {
        logger      => 't::TestLogger',
        userLogger  => 't::TestLogger',
        auditLogger => 't::TestAuditLogger'
    };
    my $psgi = new_ok( 't::TestPsgi' => [$args] );
    $psgi->init($args);

    my $server = Plack::Test->create( $psgi->run );

    my $res = $server->request( GET "/" );
    is( $res->code, 200, "Returned HTTP code 200" );

    $psgi->_auditLogger->contains( message => "audit" );
    $psgi->_auditLogger->contains( field1  => "one", field2 => "two" );

};

subtest "Check request ID" => sub {
    my $args = {
        logger      => 't::TestLogger',
        userLogger  => 't::TestLogger',
        auditLogger => 't::TestAuditLogger'
    };
    my $psgi = new_ok( 't::TestPsgi' => [$args] );
    $psgi->init($args);

    my $app = $psgi->run;
    my $server = Plack::Test->create( $app );

    # One request, no unique ID specified
    my $res = $server->request( GET "/" );
    # One request, no unique ID specified
    my $res = $server->request( GET "/" );
    # One request, with sepcified UNIQUE_ID
    my $req_env = GET("/")->to_psgi(UNIQUE_ID=>"aaabbbccc123");
    $app->($req_env);

    my $logs = $psgi->_auditLogger->logs;
    my @request_ids = map {$_->{req}->{id}} @$logs;
    my %request_id_count;
    map { $request_id_count{$_}++ } @request_ids;

    cmp_ok($request_id_count{"aaabbbccc123"}, ">=", 2, "Enforced UNIQUE_ID seen in 2 messages");
    is(scalar keys %request_id_count, 3, "Seen three different request IDs");
};

done_testing();
