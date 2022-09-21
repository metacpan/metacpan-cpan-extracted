#!perl
BEGIN
{
    use strict;
    use warnings;
    use Test::More;
    use URI;
};

BEGIN
{
    use_ok( 'HTML::Object::DOM' ) || BAIL_OUT( "Cannot load HTML::Object::DOM" );
    use_ok( 'HTML::Object::DOM::Element::Anchor' ) || BAIL_OUT( "Cannot load HTML::Object::DOM::Element::Anchor" );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

can_ok( 'HTML::Object::DOM::Element::Anchor', 'hash' );
can_ok( 'HTML::Object::DOM::Element::Anchor', 'host' );
can_ok( 'HTML::Object::DOM::Element::Anchor', 'hostname' );
can_ok( 'HTML::Object::DOM::Element::Anchor', 'href' );
can_ok( 'HTML::Object::DOM::Element::Anchor', 'hreflang' );
can_ok( 'HTML::Object::DOM::Element::Anchor', 'origin' );
can_ok( 'HTML::Object::DOM::Element::Anchor', 'password' );
can_ok( 'HTML::Object::DOM::Element::Anchor', 'pathname' );
can_ok( 'HTML::Object::DOM::Element::Anchor', 'port' );
can_ok( 'HTML::Object::DOM::Element::Anchor', 'protocol' );
can_ok( 'HTML::Object::DOM::Element::Anchor', 'referrerPolicy' );
can_ok( 'HTML::Object::DOM::Element::Anchor', 'rel' );
can_ok( 'HTML::Object::DOM::Element::Anchor', 'relList' );
can_ok( 'HTML::Object::DOM::Element::Anchor', 'search' );
can_ok( 'HTML::Object::DOM::Element::Anchor', 'target' );
can_ok( 'HTML::Object::DOM::Element::Anchor', 'text' );
can_ok( 'HTML::Object::DOM::Element::Anchor', 'toString' );
can_ok( 'HTML::Object::DOM::Element::Anchor', 'type' );
can_ok( 'HTML::Object::DOM::Element::Anchor', 'username' );

my $parser = HTML::Object::DOM->new;
my $doc = $parser->new_document;
my $link = $doc->createElement( 'a' );
isa_ok( $link => 'HTML::Object::DOM::Element::Anchor', 'createElement( "a" ) -> HTML::Object::DOM::Element::Anchor' );
ok( $link->is_closed, 'new link element is closed by default' );

my $a = HTML::Object::DOM::Element::Anchor->new;
$a->download = 'my_file.txt';
is( $a->download, 'my_file.txt', 'download' );
is( $a->as_string, q{<a download="my_file.txt">}, 'download' );
$a->hash = 'opened';
is( $a->hash, '#opened', 'hash' );
is( $a->as_string, q{<a download="my_file.txt" href="#opened">}, 'hsah -> as_string' );
my $uri = $a->href;
isa_ok( $uri => 'URI' );
$a->host = 'example.org';
is( $a->host, 'example.org', 'host' );
$uri = $a->href;
ok( !$uri->can( 'host' ), 'URI has no host yet' );
$a->hostname = 'example.com';
is( $a->hostname, 'example.com', 'hostname' );
$uri = $a->href;
is( "$uri", '#opened', 'URI has not changed yet' );
my $uri2 = URI->new( 'https://www.example.net:4242/some/where' );
$a->href = $uri2;
$uri = $a->href;
isa_ok( $uri => 'URI::https', 'URI object assigned directly to href' );
is( $a->protocol, 'https:', 'protocol from assigned URI' );
is( $a->hostname, 'www.example.net', 'host from assigned URI' );
is( $a->hash, undef, 'hash removed after assigned URI' );
$a->hreflang = 'ja';
is( $a->hreflang, 'ja', 'hreflang' );
is( $a->toString(), 'https://www.example.net:4242/some/where', 'toString' );
is( $a->as_string, q{<a download="my_file.txt" href="https://www.example.net:4242/some/where" hreflang="ja">}, 'hreflang -> as_string' );
is( $a->origin, 'https://www.example.net:4242', 'origin' );
$a->password = 'abracadabra';
is( $a->password, 'abracadabra', 'password' );
is( $a->pathname, '/some/where' );
$a->pathname = '/some/where/else';
is( $a->pathname, '/some/where/else', 'pathname' );
$a->port = 443;
is( $a->port, 443, 'post' );
is( $a->origin, 'https://www.example.net', 'port -> origin' );
is( $a->protocol, 'https:', 'protocol' );
$a->protocol = 'http';
is( $a->protocol, 'http:', 'protocol' );
is( $a->origin, 'http://www.example.net:443', 'protocol -> origin' );
$a->referrerPolicy = 'no-referrer';
is( $a->referrerPolicy, 'no-referrer', 'referrerPolicy' );
is( $a->as_string, q{<a download="my_file.txt" href="http://:abracadabra@www.example.net:443/some/where/else" hreflang="ja" referrerpolicy="no-referrer">}, 'referrerPolicy -> as_string' );
$a->rel = 'noopener';
is( $a->rel, 'noopener', 'rel' );
ok( $a->relList->contains( 'noopener' ), 'relList' );
$a->relList->add( 'noreferrer noopener' );
is( $a->as_string, q{<a download="my_file.txt" href="http://:abracadabra@www.example.net:443/some/where/else" hreflang="ja" referrerpolicy="no-referrer" rel="noopener noreferrer">}, 'relList -> as_string' );
my $tokens = $a->relList;
isa_ok( $tokens, 'HTML::Object::TokenList', 'tokens list object retrieved' );
$a->debug( $DEBUG ) if( $DEBUG );
$a->rel = "alternate noopener noreferrer";
ok( $tokens->contains( 'alternate' ), 'bidirectional tokens list' );
$a->search = 'q=something';
is( $a->search, '?q=something', 'search' );
is( $a->as_string, q{<a download="my_file.txt" href="http://:abracadabra@www.example.net:443/some/where/else?q=something" hreflang="ja" referrerpolicy="no-referrer" rel="alternate noopener noreferrer">}, 'search -> as_string' );
$a->hash = "nice";
is( $a->as_string, q{<a download="my_file.txt" href="http://:abracadabra@www.example.net:443/some/where/else?q=something#nice" hreflang="ja" referrerpolicy="no-referrer" rel="alternate noopener noreferrer">}, 'hash -> as_string' );
$a->target = '_blank';
is( $a->target, '_blank', 'target' );
is( $a->as_string, q{<a download="my_file.txt" href="http://:abracadabra@www.example.net:443/some/where/else?q=something#nice" hreflang="ja" referrerpolicy="no-referrer" rel="alternate noopener noreferrer" target="_blank">}, 'target -> as_string' );
$a->text = "Nice try!";
is( $a->text, 'Nice try!', 'text' );
$a->close;
is( $a->as_string, q{<a download="my_file.txt" href="http://:abracadabra@www.example.net:443/some/where/else?q=something#nice" hreflang="ja" referrerpolicy="no-referrer" rel="alternate noopener noreferrer" target="_blank">Nice try!</a>}, 'text -> as_string' );
$a->type = 'text/plain';
is( $a->type, 'text/plain', 'type' );
is( $a->as_string, q{<a download="my_file.txt" href="http://:abracadabra@www.example.net:443/some/where/else?q=something#nice" hreflang="ja" referrerpolicy="no-referrer" rel="alternate noopener noreferrer" target="_blank" type="text/plain">Nice try!</a>}, 'text -> as_string' );
$a->username = 'anonymous';
is( $a->username, 'anonymous', 'username' );
is( $a->as_string, q{<a download="my_file.txt" href="http://anonymous:abracadabra@www.example.net:443/some/where/else?q=something#nice" hreflang="ja" referrerpolicy="no-referrer" rel="alternate noopener noreferrer" target="_blank" type="text/plain">Nice try!</a>}, 'username -> as_string' );

done_testing();

__END__

