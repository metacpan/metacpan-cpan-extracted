use strict;
use Test::More;
use Test::Fatal;

use Email::Sender::Transport::Mailgun  qw( );
use File::Temp                         qw( tempfile );
use HTTP::Tiny                         qw( );

my @apikeys = ( 'regular123', 'reserved:@?#/' );

for my $apikey (@apikeys) {
    my $estm = Email::Sender::Transport::Mailgun->new(
        api_key => $apikey, domain => 'test'
    );

    my $uri = $estm->_build_uri;

    my $ht = HTTP::Tiny->new;
    my ($scheme, $host, $port, $path_query, $auth) = $ht->_split_url($uri);

    is($auth, "api:$apikey", 'API key got escaped properly for HTTP::Tiny');
}

my @tests = (
    {
        args => { },
        exception => qr/api_key or api_key_path/,
        message => 'Neither api key args fails',
    },
    {
        args => { api_key => 'api_key', api_key_path => '/dev/null' },
        exception => qr/api_key and api_key_path/,
        message => 'Both api key args fails',
    },
    {
        args => { api_key => 'api_key' },
        message => 'Only api_key lives',
    },
    {
        args => { api_key_path => '/dev/null' },
        message => 'Only api_key_path lives',
    },
);

for my $test (@tests) {
    my %args = ( %{ $test->{args} }, domain => 'test' );
    if (exists $test->{exception}) {
        like(
            exception { Email::Sender::Transport::Mailgun->new(%args) },
            $test->{exception},
            $test->{message},
        );
    }
    else {
        is(
            exception { Email::Sender::Transport::Mailgun->new(%args) },
            undef,
            $test->{message},
        );
    }
}

{
    my $expected = 'xyzzy';
    my $etcm = Email::Sender::Transport::Mailgun->new(
        api_key => $expected, domain => 'test'
    );

    my $got = $etcm->_api_key;

    is($got, $expected, 'api_key param works as expected');
}

{
    my $expected = 'xyzzy';
    my ($fh, $filename) = tempfile();
    print {$fh} $expected;
    close($fh);

    my $etcm = Email::Sender::Transport::Mailgun->new(
        api_key_path => $filename, domain => 'test'
    );

    my $got = $etcm->_api_key;

    is($got, $expected, 'api_key_path param works as expected');
}

done_testing;
