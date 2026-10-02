use strict;
use warnings;
use Log::Any::Test;
use Log::Any qw( $log );
use Test2::V0;

# Regression guard (k35): tracing is observability, not the product. A
# Langfuse that accepts the connection and never answers must neither hold
# the request that is being traced nor leave its POST pending forever: the
# POST gives up after langfuse.timeout seconds (default 15, k62) and the
# failure is logged as a warning, not raised -- on either transport.

use IO::Async::Loop;
use Net::Async::HTTP::Server;
use Time::HiRes qw( time );
use Langertha::Knarr::Config;
use Langertha::Knarr::Tracing;

delete local $ENV{KNARR_LANGFUSE_TIMEOUT};

my $loop = IO::Async::Loop->new;
my @held;
my $langfuse = Net::Async::HTTP::Server->new( on_request => sub { push @held, $_[1] } );
$loop->add($langfuse);
$langfuse->listen( addr => { family => 'inet', socktype => 'stream', ip => '127.0.0.1', port => 0 } )->get;
my $url = 'http://127.0.0.1:' . $langfuse->read_handle->sockport;

for my $transport (qw( ingestion otel )) {
  subtest "$transport transport" => sub {
    $log->clear;
    @held = ();
    my $tracing = Langertha::Knarr::Tracing->new( config => Langertha::Knarr::Config->new( data => {
      models   => { m => { engine => 'OpenAI' } },
      langfuse => { public_key => 'pk', secret_key => 'sk', url => $url,
                    transport => $transport, timeout => 2 },
    } ) );
    ok( $tracing->_enabled, 'tracing enabled against the hanging Langfuse' );

    my $start = time;
    my $trace = $tracing->start_trace( model => 'm', engine => 'e', format => 'openai',
      messages => [ { role => 'user', content => 'hi' } ] );
    $tracing->end_trace( $trace, output => 'done' );
    ok( time - $start < 1, 'end_trace returns without waiting for Langfuse' );

    my $deadline = time + 10;
    my $flush_error;
    until ( $flush_error || time > $deadline ) {
      $loop->loop_once(0.2);
      ($flush_error) = grep { $_->{level} eq 'warning' && $_->{message} =~ /Langfuse flush error/ }
        @{ $log->msgs };
    }
    my $took = time - $start;
    ok( $flush_error, 'the hanging POST fails and is logged as a warning' );
    like( $flush_error->{message}, qr/Timed out/, 'it failed by timing out' ) if $flush_error;
    ok( $took >= 1.8, 'not before the configured 2s' ) or note "took $took s";
    ok( $took < 5, 'soon after the configured 2s' ) or note "took $took s";
    ok( scalar @held, 'the POST did reach Langfuse' );
  };
}

done_testing;
