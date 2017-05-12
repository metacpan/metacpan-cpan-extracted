use strict;
use warnings;
use Test::More;
use Test::Exception;
use Search::Elasticsearch::TestServer;
use Message::Passing::Output::Search::Elasticsearch;
use Search::Elasticsearch::Client::5_0::Async::Bulk;
use Search::Elasticsearch;
use AnyEvent;

my $server =
    Search::Elasticsearch::TestServer->new(
    es_home => '/usr/share/elasticsearch' );

my $nodes;

# work around non-checked exec in TestServer which forks
my $pid = $$;
eval { $nodes = $server->start };
exit
    unless $pid == $$;

plan skip_all => "Can't run tests without Elasticsearch server"
    if $@;

my $out_es;

lives_ok {
    $out_es = Message::Passing::Output::Search::Elasticsearch->new(
        es_params  => { nodes => $nodes, },
        type       => 'syslog',
        index_name => 'syslog',
    );
}
'output instantiated using es_params';

my $es;
lives_ok {
    $es = Search::Elasticsearch::Async->new( nodes => $nodes );
}
'Search::Elasticsearch::Async instantiated';

lives_ok {
    $out_es = Message::Passing::Output::Search::Elasticsearch->new(
        es         => $es,
        type       => 'syslog',
        index_name => 'syslog',
    );
}
'output instantiated using es';

lives_ok {
    $out_es = Message::Passing::Output::Search::Elasticsearch->new(
        es_bulk    => Search::Elasticsearch::Client::5_0::Async::Bulk->new( es => $es ),
        type       => 'syslog',
        index_name => 'syslog',
    );
}
'output instantiated using es_bulk';

my $cv = AnyEvent->condvar;

lives_ok {
    $out_es = Message::Passing::Output::Search::Elasticsearch->new(
        es             => $es,
        es_bulk_params => {
            max_count  => 1,
            on_success => sub {
                $cv->send;
            },
        },
        type       => 'syslog',
        index_name => 'syslog',
    );
}
'output instantiated using es_bulk_params';

my $sync_es = Search::Elasticsearch->new( nodes => $nodes );

# non-hashref messages are currently silently ignored
# thus no callback is called which we could wait for
lives_ok { $out_es->consume('text message'); } 'text message consumed';

# ensure that Elasticsearch returns the newly indexed document
$sync_es->indices->refresh;
is $sync_es->count->{count}, 0, "and wasn't indexed";

lives_ok {
    $out_es->consume(
        { timestamp => 12345678, message => 'hashref message' } );
}
'hashref message consumed';

# wait for the callback
$cv->recv;

# ensure that Elasticsearch returns the newly indexed document
$sync_es->indices->refresh;
is $sync_es->count->{count}, 1, "and was indexed";

done_testing;
