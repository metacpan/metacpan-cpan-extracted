use strict;
use warnings;
use Test2::V0;
use File::Temp qw( tempdir );
use JSON::MaybeXS;
use Path::Tiny;

use Langertha::Usage;
use Langertha::Knarr::Config;
use Langertha::Knarr::RequestLog;

# k71: the JSONL log kept only input/output/total of a Langertha::Usage and
# lost the prompt-cache tokens. They ride beside the canonical counts now,
# split like the Langfuse trace splits them (k65).

my $json = JSON::MaybeXS->new( utf8 => 1 );
my $tmp  = tempdir( CLEANUP => 1 );
my $file = "$tmp/requests.jsonl";
my $rlog = Langertha::Knarr::RequestLog->new(
  config => Langertha::Knarr::Config->new(
    data => { listen => ['127.0.0.1:0'], models => {}, logging => { file => $file } },
  ),
);

sub logged_usage {
  my ($usage) = @_;
  path($file)->remove;
  my $h = $rlog->start_request( model => 'm', format => 'openai' );
  $rlog->end_request( $h, output => 'x', usage => $usage );
  my ($line) = grep { length } split /\n/, path($file)->slurp_utf8;
  return $json->decode($line)->{usage};
}

subtest 'Anthropic cache tokens are logged beside the counts' => sub {
  my $u = logged_usage( Langertha::Usage->from_hash( {
    input_tokens => 10, output_tokens => 5,
    cache_read_input_tokens => 300, cache_creation_input_tokens => 40,
  } ) );
  is $u->{input_tokens},       10,  'input_tokens unchanged';
  is $u->{output_tokens},      5,   'output_tokens unchanged';
  is $u->{cached_tokens},      300, 'cache reads logged';
  is $u->{cache_write_tokens}, 40,  'cache writes logged';
};

subtest 'OpenAI cached tokens are logged, input not shrunk' => sub {
  my $u = logged_usage( Langertha::Usage->from_hash( {
    prompt_tokens => 100, completion_tokens => 7, total_tokens => 107,
    prompt_tokens_details => { cached_tokens => 80 },
  } ) );
  is $u->{input_tokens},  100, 'input_tokens is the whole input';
  is $u->{cached_tokens}, 80,  'cache reads logged';
  ok !exists $u->{cache_write_tokens}, 'no zero cache write field';
};

subtest 'no cache, no extra fields' => sub {
  my $u = logged_usage( Langertha::Usage->from_hash( { input_tokens => 3, output_tokens => 2 } ) );
  is $u, { input_tokens => 3, output_tokens => 2, total_tokens => 5 }, 'format unchanged';
};

subtest 'usage without any count is null, not 0/0/0' => sub {
  is logged_usage( Langertha::Usage->from_hash( {} ) ), undef, 'null';
};

subtest 'plain hashref stays verbatim' => sub {
  is logged_usage( { input => 1, output => 2, total => 3 } ),
    { input => 1, output => 2, total => 3 }, 'verbatim';
};

done_testing;
