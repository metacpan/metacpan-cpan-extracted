#!perl -w
use strict;
use Test::More tests => 16;
use Data::Dumper;

use HTTP::Request::Generator 'generate_requests';

sub expand_url {
    my( $pattern ) = @_;

    # generate all the parts
    my @requests = generate_requests(
        pattern => $pattern,
    );

    my @urls = map { $_->{url} } @requests;

    @urls
}

sub expands_properly {
    my( $pattern, $expected, $name) = @_;
    $name ||= "$pattern expands properly";

    my $res = [sort {$a cmp $b} expand_url($pattern)];
    is_deeply $res, [sort @$expected], $name
        or diag Dumper $res;
}

expands_properly('https://example.com/{bar,baz}.html', [
                 'https://example.com/bar.html',
                 'https://example.com/baz.html',
                 ], '{} expands properly');
expands_properly('http{s,}://example.com/', [
                 'http://example.com/',
                 'https://example.com/',
                 ], '{} keeps empty parts');
{
local $TODO = "Mixing host and path expansion needs rethinking";
expands_properly('https://{example.com,localhost/foo}/{bar,baz}.html', [
                 'https://example.com/bar.html',
                 'https://example.com/baz.html',
                 'https://localhost/foo/bar.html',
                 'https://localhost/foo/baz.html',
                 ], "host parts don't get escaped");
}
expands_properly('https://{example.com,localhost}/{foo/bar,baz}.html', [
                 'https://example.com/foo/bar.html',
                 'https://example.com/baz.html',
                 'https://localhost/foo/bar.html',
                 'https://localhost/baz.html',
                 ], "host parts don't get escaped");

expands_properly('https://www[01..03].example.com',
                ['https://www01.example.com',
                 'https://www02.example.com',
                 'https://www03.example.com'
                ], '[] expands properly with leading zeroes');
expands_properly('https://www[9..11].example.com',
                ['https://www9.example.com',
                 'https://www10.example.com',
                 'https://www11.example.com'
                ], '[] expands properly without leading zeroes');
expands_properly('https://[aa..ac].example.com', [
                 'https://aa.example.com',
                 'https://ab.example.com',
                 'https://ac.example.com',
                 ], '[] expands properly alphabetically');
expands_properly('https://example.com/[a..b]/{index,error}.html', [
                 'https://example.com/a/index.html',
                 'https://example.com/a/error.html',
                 'https://example.com/b/index.html',
                 'https://example.com/b/error.html',
                 ], '[] and {} can be mixed');
expands_properly('https://example.com:443/[a..b].html', [
                 'https://example.com/a.html',
                 'https://example.com/b.html',
                 ], 'ports can be added but defaults get canonicalized');
expands_properly('https://example.com:8443/[a..b].html', [
                 'https://example.com:8443/a.html',
                 'https://example.com:8443/b.html',
                 ], 'ports can be added but non-defaults survive');
expands_properly('https://[::1]:8443/[a..b].html', [
                 'https://[::1]:8443/a.html',
                 'https://[::1]:8443/b.html',
                 ], 'IPv6 addresses survive expansion');
expands_properly('https://127.0.0.8:8443/[a..b].html', [
                 'https://127.0.0.8:8443/a.html',
                 'https://127.0.0.8:8443/b.html',
                 ], 'IPv4 addresses survive expansion');

expands_properly('https://[0:0:0:0:0:ffff:10.138.196.205]:8443/[a..b].html', [
                 'https://[0:0:0:0:0:ffff:10.138.196.205]:8443/a.html',
                 'https://[0:0:0:0:0:ffff:10.138.196.205]:8443/b.html',
                 ], 'Fancy embedded IPv4 addresses survive expansion');

expands_properly('https://[::ffff:0:10.138.196.205]:8443/[a..b].html', [
                 'https://[::ffff:0:10.138.196.205]:8443/a.html',
                 'https://[::ffff:0:10.138.196.205]:8443/b.html',
                 ], 'Fancy embedded routed IPv4 addresses survive expansion');

my @urls = generate_requests(
    pattern => '//f/[0..11][0..11]',
    limit   => 10,
);
is 0+@urls, 10, "We can limit the number of created items"
    or diag Dumper \@urls;

my $iter = generate_requests(
    pattern => 'https://[a..z][a..z][a..z].example.com',
);
my $count = 0;
while( my $req = $iter->() ){
    $count++
};
is $count, 26*26*26, "We enumerate all expansions";
