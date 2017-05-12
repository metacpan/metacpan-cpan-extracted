use strict;
use Test::More;

BEGIN
{
    eval "use POE; use POE::Component::Client::HTTP";
    if ($@) {
        plan skip_all => "POE engine not available";
    } else {
        plan tests => 8;
    }
    use_ok("Gungho");
    use_ok("Gungho::Request");
    use_ok("Gungho::Response");
    use_ok("GunghoX::FollowLinks::Rule", 'FOLLOW_ALLOW', 'FOLLOW_DENY');
    use_ok("GunghoX::FollowLinks");
}
# XXX - Hmm, why isn't this working?
# use GunghoX::FollowLinks::Rule qw(FOLLOW_ALLOW);

{
    package Dummy;
    use Test::More;
    use vars qw(@ISA $VERSION);
    $VERSION = '0.00001';
    @ISA = qw(Gungho::Component);
    __PACKAGE__->mk_classdata('link_count' => 0);
    sub  pushback_request {
        my ($c, $req) = @_;

        is($req->uri->host, 'www.example.com', "host is www.example.com");
        if ($req->uri->host eq 'www.example.com') {
            $c->link_count( $c->link_count + 1 );
        }
    }
}

Gungho->bootstrap(
    {
        provider     => { module => 'Simple' },
        handler      => { module => 'Null' },
        components   => [ '+Dummy', '+GunghoX::FollowLinks' ],
        follow_links => {
            parsers => [
                {
                    module => 'HTML',
                    config => {
                        rules => [
                            {
                                module => 'URI',
                                config => {
                                    match => [
                                        {
                                            action => &GunghoX::FollowLinks::Rule::FOLLOW_ALLOW,
                                            host   => '^www\.example\.com$'
                                        }
                                    ]
                                }
                            },
                            {
                                module => 'Deny',
                            }
                        ]
                    }
                }
            ]
        }
    }
);

my $request  = Gungho::Request->new(GET => "http://www.example.com");
my $response = Gungho::Response->new(
    200,
    "OK", 
    HTTP::Headers->new( Content_Type => 'text/html; charset=utf-8' ),
    join("\n",
        '<html>',
        '<body>',
        '  <a href="http://www.example.com">',
        '  <a href="http://ftp.example.com">',
        '  <a href="http://svn.example.com">',
        '  <a href="http://www.example.com">',
        '</body>',
        '</html>'
    )
);
$response->request($request);

Gungho->follow_links($response);
is(Gungho->link_count, 2, "found 2 hosts");