use strict;
use Test::More;

BEGIN
{
    if (! $ENV{GUNGHO_TEST_LIVE}) {
        plan skip_all => "Enable GUNGHO_TEST_LIVE to run these tests";
    } else {
        # Check which engine we're checking


        plan tests => 5;
        use_ok "Gungho::Inline";
    }
}

Gungho::Inline->run(
    {
        engine => {
            module => qw(POE),
            config => {
                agent => 'test_user_agent' # this only works for POE
            },
        }
    },
    {
        provider => sub {
            my($p, $c) = @_;
            $c->send_request(Gungho::Request->new(GET => $_)) for qw(
                http://www.perl.com
                http://search.cpan.org
            )
        },
        handler => sub {
            my($h, $c, $req, $res) = @_;
            ok( $res->is_success, $req->uri . " is success");
            ok( $res->request->header('User-Agent'), 'test_user_agent');
        },
    }
);