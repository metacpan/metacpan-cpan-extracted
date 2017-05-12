use strict;
use warnings;

use Test::More;
use Time::HiRes qw( sleep );
use IO::Socket::INET;
use lib 'buildlib';

my $PORT_NUM = 7890;
BEGIN {
    if ( $^O =~ /mswin/i ) {
        plan( 'skip_all', "fork on Windows not supported by KS" );
    }
}

use KinoSearch1::Search::SearchServer;
use KinoSearch1::Search::SearchClient;
use KinoSearch1::Searcher;
use KinoSearch1::Analysis::Tokenizer;
use KinoSearch1::Search::MultiSearcher;
use KinoSearch1::Test::TestUtils qw( create_index );

my $tokenizer = KinoSearch1::Analysis::Tokenizer->new;

my $kid;
$kid = fork;
if ($kid) {
    sleep .25;    # allow time for the server to set up the socket
    die "Failed fork: $!" unless defined $kid;
}
else {
    my $invindex = create_index( 'x a', 'x b', 'x c' );

    my $searcher = KinoSearch1::Searcher->new(
        analyzer => $tokenizer,
        invindex => $invindex,
    );

    my $server = KinoSearch1::Search::SearchServer->new(
        port       => $PORT_NUM,
        searchable => $searcher,
        password   => 'foo',
    );

    $server->serve;
    exit(0);
}

my $test_client_sock = IO::Socket::INET->new(
    PeerAddr => "localhost:$PORT_NUM",
    Proto    => 'tcp',
);
if ($test_client_sock) {
    plan( tests => 4 );
    undef $test_client_sock;
}
else {
    plan( 'skip_all', "Can't get a socket: $!" );
}

my $tokenizer2   = KinoSearch1::Analysis::Tokenizer->new;
my $searchclient = KinoSearch1::Search::SearchClient->new(
    analyzer     => $tokenizer2,
    peer_address => "localhost:$PORT_NUM",
    password     => 'foo',
);

my $hits = $searchclient->search('x');
is( $hits->total_hits, 3, "retrieved hits from search server" );

$hits = $searchclient->search('a');
is( $hits->total_hits, 1, "retrieved hit from search server" );

my $invindex_b = create_index( 'y b', 'y c', 'y d' );
my $searcher_b = KinoSearch1::Searcher->new(
    analyzer => $tokenizer,
    invindex => $invindex_b,
);

my $multi_searcher = KinoSearch1::Search::MultiSearcher->new(
    analyzer    => $tokenizer,
    searchables => [ $searcher_b, $searchclient ],
);

$hits = $multi_searcher->search('b');
is( $hits->total_hits, 2, "retrieved hits from MultiSearcher" );

my %results;
$results{ $hits->fetch_hit_hashref()->{content} } = 1;
$results{ $hits->fetch_hit_hashref()->{content} } = 1;
my %expected = ( 'x b' => 1, 'y b' => 1, );

is_deeply( \%results, \%expected, "docs fetched from both local and remote" );

END {
    $searchclient->terminate if defined $searchclient;
    kill( TERM => $kid ) if $kid;
}
