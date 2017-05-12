use Kelp::Base -strict;
use Kelp;
use Kelp::Test;
use HTTP::Request::Common;
use Test::More;

# Basic
{
    my $app = Kelp->new();
    can_ok $app, $_ for qw/json/;
    is ref $app->json, 'JSON::XS';
    ok $app->json->get_utf8, "utf8 turned on";

    my $json = { a => 'text' };
    $app->add_route(
        '/json',
        sub {
            $json
        }
    );

    my $t = Kelp::Test->new( app => $app );
    $t->request( GET '/json' )->json_cmp($json);
}

done_testing;
