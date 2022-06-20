use strict;
use Test::More;

use Email::Sender::Transport::Mailgun  qw( );
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

done_testing;

1;
