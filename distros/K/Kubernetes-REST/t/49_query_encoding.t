#!/usr/bin/env perl
# karr k35: query parameters reach the API server exactly as the caller wrote
# them.
#
# prepare_request used to join its parameters as raw "key=value". The API
# server splits a query with Go's net/url ParseQuery: into pairs at '&', drops
# a pair that holds a ';' whole, splits key from value at the FIRST '=', then
# reads '+' as a space and '%XX' as a byte, and drops a pair with a malformed
# '%'. Before any of that the client cuts the URL at '#' - URI (LWP,
# Net::Async::HTTP) and HTTP::Tiny both take the rest for a fragment and never
# send it - and a space, a control character or a raw non-ASCII byte has no
# place in an HTTP request target at all. A fieldSelector value holding any of
# them reached the server altered, truncated, or not at all; an ignored
# selector is an unfiltered list.
#
# Claims pinned here:
#   - each of those characters survives: the query, decoded the way the server
#     decodes it, holds exactly the keys and values the caller passed, and a
#     parameter after the value is not lost with it;
#   - non-ASCII goes as UTF-8, whatever Perl's internal representation of the
#     string - never as Latin-1;
#   - everything else stays as it was: a typical selector renders byte for
#     byte as before, so a caller comparing the raw query (t/47's mock keys,
#     Net::Async::Kubernetes's MockTransport) sees the same string;
#   - LWP puts the URL on the wire as built - no part lost, nothing encoded
#     twice.
use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib", "$FindBin::Bin/../lib";

use Encode ();
use HTTP::Request;
use Test::Kubernetes::Mock qw(mock_api);

binmode Test::More->builder->$_, ':encoding(UTF-8)'
    for qw( output failure_output todo_output );

my $ENDPOINT = 'http://mock.local';

# The query of $url as the API server reads it: the part a client sends (up to
# the first '#'), which must be a valid request target, split and decoded like
# Go's url.ParseQuery. Returns { key => [ values ] } with keys and values
# decoded from UTF-8, or dies when the URL could not be sent as it is.
sub server_query {
    my ($url) = @_;
    (my $sent = $url) =~ s/#.*//s;
    my ($target) = $sent =~ m{\A\Q$ENDPOINT\E(.*)\z}s
        or die "not a URL on $ENDPOINT: '$url'\n";
    die "not a valid HTTP request target: '$target'\n"
        if $target =~ /[^\x21-\x7E]/;
    my (undef, $query) = split /\?/, $target, 2;
    my %params;
    PAIR: for my $pair (split /&/, $query // '') {
        next PAIR if $pair eq '' || $pair =~ /;/;
        my ($key, $value) = split /=/, $pair, 2;
        my @decoded;
        for my $part ($key, $value // '') {
            next PAIR if $part =~ /%(?![0-9A-Fa-f]{2})/;
            (my $bytes = $part) =~ tr/+/ /;
            $bytes =~ s/%([0-9A-Fa-f]{2})/chr hex $1/ge;
            push @decoded, Encode::decode('UTF-8', $bytes, Encode::FB_CROAK);
        }
        push @{ $params{ $decoded[0] } }, $decoded[1];
    }
    return \%params;
}

my $api = mock_api();

# ---------------------------------------------------------------------------
# Every character that splits or alters a query arrives as it was written.
# A 'watch' parameter sorts after fieldSelector, so a value that ends the URL
# early ('#') or swallows what follows would lose it.
# ---------------------------------------------------------------------------
my @ENCODED = (
    [ 'percent'                 => 'metadata.name=100%sure' ],
    [ 'percent-escape lookalike' => 'metadata.name=%41' ],
    [ 'ampersand'               => 'metadata.name=a&b' ],
    [ 'plus'                    => 'metadata.name=a+b' ],
    [ 'hash'                    => 'metadata.name=a#b' ],
    [ 'semicolon'               => 'metadata.name=a;b' ],
    [ 'space'                   => 'metadata.name=a b' ],
    [ 'tab'                     => "metadata.name=a\tb" ],
    [ 'newline'                 => "metadata.name=a\nb" ],
    [ 'NUL'                     => "metadata.name=a\0b" ],
    [ 'DEL'                     => "metadata.name=a\x7Fb" ],
    [ 'Latin-1 range character' => 'metadata.name=café' ],
    [ 'CJK characters'          => 'metadata.name=日本' ],
    [ 'astral character'        => "metadata.name=\x{1F600}" ],
    [ 'set-based selector'      => 'environment in (production,qa),tier notin (frontend)' ],
);

for my $case (@ENCODED) {
    my ($label, $value) = @$case;
    my $req = $api->prepare_request('GET', '/api/v1/pods',
        parameters => { fieldSelector => $value, watch => 'true' });
    my $got = eval { server_query($req->url) } // $@;
    is_deeply($got, { fieldSelector => [$value], watch => ['true'] },
        "$label: the server reads the value exactly, and the next parameter")
        or diag 'url: ' . $req->url;
}

subtest 'keys get the same treatment as values' => sub {
    for my $key ('a b', 'a&b', 'a+b', 'a#b', 'a;b', 'a%b', 'ключ') {
        my $req = $api->prepare_request('GET', '/api/v1/pods',
            parameters => { $key => 'v', watch => 'true' });
        my $got = eval { server_query($req->url) } // $@;
        is_deeply($got, { $key => ['v'], watch => ['true'] }, "key '$key' arrives exactly")
            or diag 'url: ' . $req->url;
    }
};

subtest 'arrayref values are encoded one by one' => sub {
    my $req = $api->prepare_request('GET', '/api/v1/namespaces/default/pods/p/exec',
        parameters => { command => ['sh', '-c', 'echo a&b; ls #x'] });
    my $got = eval { server_query($req->url) } // $@;
    is_deeply($got, { command => ['sh', '-c', 'echo a&b; ls #x'] },
        'every element arrives as its own exact value')
        or diag 'url: ' . $req->url;
};

subtest 'non-ASCII goes as UTF-8 whatever the internal representation' => sub {
    my $downgraded = 'metadata.name=café';
    utf8::downgrade($downgraded);
    my $upgraded = 'metadata.name=café';
    utf8::upgrade($upgraded);
    for my $case ([ downgraded => $downgraded ], [ upgraded => $upgraded ]) {
        my ($label, $value) = @$case;
        my $req = $api->prepare_request('GET', '/api/v1/pods',
            parameters => { fieldSelector => $value });
        is($req->url, "$ENDPOINT/api/v1/pods?fieldSelector=metadata.name=caf%C3%A9",
            "$label string: é is sent as its UTF-8 bytes");
    }
};

# ---------------------------------------------------------------------------
# Everything else is sent exactly as before - the strings are what the old
# prepare_request produced.
# ---------------------------------------------------------------------------
subtest 'typical selectors render byte-identically to the old request' => sub {
    my @RAW = (
        [ labelSelector => 'app=web' ],
        [ labelSelector => 'app=demo' ],
        [ labelSelector => 'app.kubernetes.io/component=queen' ],
        [ labelSelector => 'env!=prod,tier' ],
        [ labelSelector => '!canary' ],
        [ labelSelector => 'app.kubernetes.io/name=x,app.kubernetes.io/part-of=y' ],
        [ fieldSelector => 'status.phase=Running' ],
        [ fieldSelector => 'status.phase=Running,spec.nodeName=node-1' ],
        [ fieldSelector => 'metadata.namespace!=kube-system' ],
        [ fieldSelector => 'involvedObject.kind=Pod,involvedObject.name=web-1' ],
        [ sinceTime     => '2026-09-27T04:26:27Z' ],
        [ resourceVersion => '12345' ],
        [ weird         => q{a/b(c):d!e,f=g'h*i~j_k-l.m?n@o$p} ],
    );
    for my $case (@RAW) {
        my ($key, $value) = @$case;
        my $req = $api->prepare_request('GET', '/api/v1/pods',
            parameters => { $key => $value });
        is($req->url, "$ENDPOINT/api/v1/pods?$key=$value", "$key=$value is unchanged");
    }

    my $req = $api->prepare_request('GET', '/api/v1/namespaces/default/pods',
        parameters => {
            watch          => 'true',
            timeoutSeconds => 300,
            labelSelector  => 'app.kubernetes.io/component=queen,env!=prod',
            fieldSelector  => 'status.phase=Running',
        });
    is($req->url,
        "$ENDPOINT/api/v1/namespaces/default/pods?fieldSelector=status.phase=Running"
            . '&labelSelector=app.kubernetes.io/component=queen,env!=prod'
            . '&timeoutSeconds=300&watch=true',
        'a whole watch query is unchanged, keys sorted as before');

    $req = $api->prepare_request('GET', '/api/v1/namespaces/default/pods/nginx/portforward',
        parameters => { ports => [8080, 8443] });
    is($req->url,
        "$ENDPOINT/api/v1/namespaces/default/pods/nginx/portforward?ports=8080&ports=8443",
        'repeated arrayref pairs are unchanged');
};

subtest 'a query already on the path is left alone' => sub {
    # Net::Async::Kubernetes builds port_forward's '?ports=...' onto the path
    # itself; only the parameters passed are encoded.
    my $req = $api->prepare_request('GET',
        '/api/v1/namespaces/default/pods/nginx/portforward?ports=8080',
        parameters => { note => 'a b' });
    is($req->url,
        "$ENDPOINT/api/v1/namespaces/default/pods/nginx/portforward?ports=8080&note=a%20b",
        'the path keeps its query as given, the parameter is appended encoded');
};

subtest 'LWP sends the URL as built' => sub {
    for my $case (@ENCODED) {
        my ($label, $value) = @$case;
        my $req = $api->prepare_request('GET', '/api/v1/pods',
            parameters => { fieldSelector => $value, watch => 'true' });
        (my $target = $req->url) =~ s{\A\Q$ENDPOINT\E}{};
        is(HTTP::Request->new(GET => $req->url)->uri->path_query, $target,
            "$label: the request target on the wire is the one built");
    }
};

# ---------------------------------------------------------------------------
# End to end: list() and watch() put the encoded query on the request they
# hand the IO backend.
# ---------------------------------------------------------------------------
{
    package Test::QueryEncoding::RecordingIO;
    use Moo;
    extends 'Test::Kubernetes::Mock::IO';

    has urls => (is => 'ro', default => sub { [] });

    around [qw( call call_streaming )] => sub {
        my ($orig, $self, $req, @rest) = @_;
        push @{ $self->urls }, $req->url;
        return $self->$orig($req, @rest);
    };
}

subtest 'list and watch send the selectors exactly' => sub {
    my $io = Test::QueryEncoding::RecordingIO->new;
    my $rec_api = Kubernetes::REST->new(
        server      => { endpoint => $ENDPOINT },
        credentials => { token => 'MockToken' },
        resource_map_from_cluster => 0,
        io          => $io,
    );
    my $selector = 'metadata.name=a&b#c';

    # The mock answers 404 for the encoded query; only the request matters.
    eval { $rec_api->list('Pod', namespace => 'default',
        labelSelector => 'app=web', fieldSelector => $selector) };
    eval { $rec_api->watch('Pod', namespace => 'default', timeout => 5,
        labelSelector => 'app=web', fieldSelector => $selector, on_event => sub {}) };

    is(scalar @{ $io->urls }, 2, 'two requests were made');
    is_deeply(eval { server_query($io->urls->[0]) } // $@,
        { fieldSelector => [$selector], labelSelector => ['app=web'] },
        'list: both selectors arrive exactly');
    is_deeply(eval { server_query($io->urls->[1]) } // $@,
        { fieldSelector => [$selector], labelSelector => ['app=web'],
          timeoutSeconds => ['5'], watch => ['true'] },
        'watch: the selectors arrive exactly, and so does everything after them');
};

done_testing;
