package Dummy;
use base qw(Gungho);
use Test::More;
use vars '$WANT_URL';

sub pushback_request
{
    my ($c, $request) = @_;
    isa_ok( $request, "Gungho::Request", "Is proper request" );
    is( $request->uri->as_string, $WANT_URL, "URL is correct ($WANT_URL)");
}

package main;
use strict;
use Test::More (tests => 22);

BEGIN
{
    use_ok("Gungho::Response");
    use_ok("GunghoX::FollowLinks::Parser::HTML");
    use_ok("GunghoX::FollowLinks::Rule", "FOLLOW_ALLOW", "FOLLOW_DENY");
    use_ok("GunghoX::FollowLinks::Rule::HTML::SelectedTags");
}

my $response = Gungho::Response->new(200, "OK", undef, <<EOHTML);
<html>
<body>
    <a href="http://www.example.com">bar</a>
    <a href="http://www.example.com">foo</a>
    <img src="http://www.example.com/image.gif">
</body>
</html>
EOHTML
my $request = Gungho::Request->new(GET => "http://example.com");
$response->request( $request );

Dummy->bootstrap( {
    provider => sub {},
    
});

my $p;

{
    $p = GunghoX::FollowLinks::Parser::HTML->new(
        rules => [
            { module => 'HTML::SelectedTags',
              config => { tags => [ 'a' ] }
            }
        ]
    );
    ok($p);
    isa_ok($p, "GunghoX::FollowLinks::Parser::HTML");

    local $Dummy::WANT_URL = "http://www.example.com";
    $p->parse('Dummy', $response);
}

{
    $p = GunghoX::FollowLinks::Parser::HTML->new(
        rules => [
            { module => 'HTML::SelectedTags',
              config => { tags => [ 'img' ] }
            }
        ]
    );
    ok($p);
    isa_ok($p, "GunghoX::FollowLinks::Parser::HTML");

    local $Dummy::WANT_URL = "http://www.example.com/image.gif";
    my $count = $p->parse('Dummy', $response);
    is($count, 1);
}

{
    $p = GunghoX::FollowLinks::Parser::HTML->new(
        rules => [
            { module => 'URI',
              config => { 
                match => [
                  { action => FOLLOW_ALLOW, path => qr(^/?$) }
                ]
              }
            }
        ]
    );

    ok($p);
    isa_ok($p, "GunghoX::FollowLinks::Parser::HTML");

    local $Dummy::WANT_URL = "http://www.example.com";
    my $count = $p->parse('Dummy', $response);
    is($count, 2);
}
