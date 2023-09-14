#!perl
use 5.020;
use Test2::V0;
use Data::Dumper;

use HTTP::Request;
use HTTP::Request::Common;

use HTTP::Request::Diff;

my $get = HTTP::Request::Common::GET('https://example.com');
my $path = HTTP::Request::Common::GET('https://example.com/login');
my $port = HTTP::Request::Common::GET('https://example.com:80443');
my $port2 = HTTP::Request::Common::GET('https://example.com:443');
my $query = HTTP::Request::Common::GET('https://example.com?foo=bar');
my $query2 = HTTP::Request::Common::GET('https://example.com?foo=baz');
my $post = HTTP::Request::Common::POST('https://example.com', { foo => 'bar' });

my @d = HTTP::Request::Diff->new->diff( $get, $get );
is \@d, [], "Identity has no diff";

@d = HTTP::Request::Diff->new->diff( $get, $post );
is \@d, [
    { type => 'request.method',         reference => 'GET', actual => 'POST',    kind => 'value' },
    { type => 'headers.Content-Length', reference => undef, actual => '7',       kind => 'missing' },
    { type => 'headers.Content-Type',   reference => undef, actual => 'application/x-www-form-urlencoded', kind => 'missing' },
    { type => 'request.content',        reference => '',    actual => 'foo=bar', kind => 'value' },
], "Method/content difference gets detected";

@d = HTTP::Request::Diff->new->diff( $get, $path );
is \@d, [
    { type => 'uri.path',           reference => '',    actual => '/login', kind => 'value' },
], "Differing path gets detected";

@d = HTTP::Request::Diff->new->diff( $get, $port );
is \@d, [
    { type => 'uri.port',           reference => '443',    actual => '80443', kind => 'value' },
], "Differing port gets detected"
or diag Dumper \@d;

@d = HTTP::Request::Diff->new->diff( $get, $port2 );
is \@d, [
], "Default port gets ignored"
or diag Dumper \@d;

@d = HTTP::Request::Diff->new->diff( $get, $query );
is \@d, [
    { type => 'query.foo',   reference => [undef], actual => ['bar'], kind => 'missing' },
], "Query difference gets detected"
or diag Dumper \@d;

@d = HTTP::Request::Diff->new->diff( $query, $query2 );
is \@d, [
    { type => 'query.foo',   reference => ['bar'], actual => ['baz'], kind => 'value' },
], "Query difference gets detected"
or diag Dumper \@d;

done_testing();
