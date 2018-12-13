#!perl -w
use strict;
use Test::More tests => 8;
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

    is_deeply [sort {$a cmp $b} expand_url($pattern)], [sort @$expected], $name;
}

expands_properly('https://example.com/{bar,baz}.html', [
                 'https://example.com/bar.html',
                 'https://example.com/baz.html',
                 ], '{} expands properly');
expands_properly('http{s,}://example.com/', [
                 'http://example.com/',
                 'https://example.com/',
                 ], '{} keeps empty parts');
expands_properly('https://{example.com,localhost/foo}/{bar,baz}.html', [
                 'https://example.com/bar.html',
                 'https://example.com/baz.html',
                 'https://localhost/foo/bar.html',
                 'https://localhost/foo/baz.html',
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

my @urls = generate_requests(
    pattern => '[0..11][0..11]',
    limit   => 10,
);
is 0+@urls, 10, "We can limit the number of created items"
    or diag Dumper \@urls;
