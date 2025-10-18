use Test::More;
use t::TestPsgi;
use Plack::Test;
use HTTP::Request;

subtest "Check successful init" => sub {
    my $server = Plack::Test->create( t::TestPsgi->run( {} ) );

    my $req = HTTP::Request->new( GET => "/" );
    $req->header( Accept => "text/html" );
    my $res = $server->request($req);
    is( $res->code, 200, "Returned HTTP code 200" );
    like( $res->content, qr/Body lines/, "Found expected message in body" );
};

done_testing();
