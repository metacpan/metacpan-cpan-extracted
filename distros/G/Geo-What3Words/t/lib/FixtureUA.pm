package FixtureUA;

## Stands in for HTTP::Tiny in the tests. Replays responses saved in
## t/data/responses, or with record => 1 makes real requests and saves
## the responses.
##
## Files are named <label>-<hash of the request>.json, the API key is
## not part of the request so it never ends up in a file.

use strict;
use warnings;
use Cpanel::JSON::XS;
use Digest::MD5 qw( md5_hex );
use File::Path  qw( make_path );
use File::Spec;
use HTTP::Tiny;

my $JSON = Cpanel::JSON::XS->new->utf8->canonical->pretty;

sub new {
    my ($class, %params) = @_;

    my $self = {
        dir    => $params{dir},
        label  => $params{label} || 'base',
        record => $params{record},
    };
    if ($self->{record}) {
        $self->{ua} = HTTP::Tiny->new;
        make_path($self->{dir});
    }

    return bless($self, $class);
}

sub agent {
    my ($self, @params) = @_;
    $self->{ua}->agent(@params) if $self->{ua};
    return;
}

sub get {
    my ($self, $url) = @_;

    my $request = _request_from_url($url);
    my $file    = File::Spec->catfile($self->{dir}, $self->{label} . '-' . substr(md5_hex($request), 0, 12) . '.json');

    if ($self->{record}) {
        my $response = $self->{ua}->get($url);
        my $body     = eval { $JSON->decode($response->{content}) };
        die "can't record $request, response is not JSON: $response->{status} $response->{content}\n"
            if !defined($body);

        open(my $fh, '>:raw', $file) || die "can't write $file: $!";
        print $fh $JSON->encode({request => $request, status => $response->{status} + 0, body => $body});
        close($fh);
        return $response;
    }

    die "no recorded response for $request ($file), see TESTING in the Geo::What3Words documentation\n"
        if !-e $file;

    open(my $fh, '<:raw', $file) || die "can't read $file: $!";
    my $fixture = $JSON->decode(do { local $/; <$fh> });
    close($fh);

    return {
        success => ($fixture->{status} >= 200 && $fixture->{status} < 300) ? 1 : 0,
        status  => $fixture->{status},
        reason  => '',
        content => $JSON->encode($fixture->{body}),
    };
}

## https://api.what3words.com/v3/convert-to-3wa?coordinates=1%2C2&format=json&key=abc
## => convert-to-3wa?coordinates=1%2C2&format=json
sub _request_from_url {
    my $url = shift;

    my ($method, $query) = $url =~ m{/([^/?]+)\??([^/]*)$};
    my @params = sort grep { !m/^key=/ } split(/&/, $query);
    return $method . '?' . join('&', @params);
}

1;
