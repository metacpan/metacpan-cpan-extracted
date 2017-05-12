use strict;
use Test::More;

my($username, $password);
BEGIN
{
    $username = $ENV{GUNGHO_TWITTER_USERNAME};
    $password = $ENV{GUNGHO_TWITTER_PASSWORD};

    if (! $username || ! $password) {
        plan(skip_all => "Enable GUNGHO_TWITTER_USERNAME and GUNGHO_TWITTER_PASSWORD to run these tests");
    } else {
        plan(tests => 5);
        use_ok("Gungho::Inline");
    }
}

Gungho::Inline->run(
    {
        credentials => {
            basic =>
              [ [ 'http://twitter.com', 'Twitter API', $username, $password ] ]
        },
        components => ['Authentication::Basic'],
    },
    {
        provider => \&provider,
        handler  => \&handler,
    }
);

sub provider {
    my ( $p, $c ) = @_;
    my $uri = URI->new('http:');
    $uri->query_form( status => 'test' );
    $p->add_request(
        $c->prepare_request(
            Gungho::Request->new(
                POST => 'http://twitter.com/statuses/update.json',
                [ 'Content-Type', 'application/x-www-form-urlencoded' ],
                $uri->query,
            )
        )
    );
}

sub handler {
    my ( $h, $c, $req, $res ) = @_;
    print $res->as_string();
}
