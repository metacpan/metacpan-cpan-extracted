use strict;
use Test::More;

BEGIN
{
    if (! $ENV{GUNGHO_TEST_PROXY}) {
        plan skip_all => "Set proxy URI to GUNGHO_TEST_PROXY to run these tests";
    } elsif ((eval "use POE"), $@) {
        plan skip_all => "POE Engine not available. Skipping";
    } else {
        plan tests => 5;
        use_ok "Gungho::Inline";
    }
}

Gungho::Inline->run(
    {
        engine => {
            module => qw(POE),
            config => {
                agent => 'test_user_agent', # this only works for POE
                client => {
                    proxy => $ENV{GUNGHO_TEST_PROXY},
                },
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
