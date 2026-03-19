#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long qw(GetOptions);
use Time::HiRes qw(time);
use Mojo::UserAgent;
use Mojo::JSON qw(encode_json);

my $base_url        = 'http://127.0.0.1:8090';
my $model           = 'qwen2.5-7b-instruct';
my $requests        = 10;
my $concurrency     = 10;
my $timeout         = 120;
my $max_tokens      = 32;
my $prompt          = 'Say hello in exactly three words.';
my $api_key         = '';
my $status_interval = 0.5;
my $show_errors     = 0;
my $json_out        = 0;

GetOptions(
  'base-url=s'        => \$base_url,
  'model=s'           => \$model,
  'requests|n=i'      => \$requests,
  'concurrency|c=i'   => \$concurrency,
  'timeout=i'         => \$timeout,
  'max-tokens=i'      => \$max_tokens,
  'prompt=s'          => \$prompt,
  'api-key=s'         => \$api_key,
  'status-interval=f' => \$status_interval,
  'show-errors!'      => \$show_errors,
  'json!'             => \$json_out,
) or die _usage();

die "--requests must be >= 1\n" unless $requests >= 1;
die "--concurrency must be >= 1\n" unless $concurrency >= 1;

my $ua = Mojo::UserAgent->new;
$ua->request_timeout($timeout);
$ua->connect_timeout($timeout > 20 ? 20 : $timeout);

my $endpoint = $base_url;
$endpoint =~ s{/\z}{};
if ($endpoint =~ m{/v1/chat/completions\z}) {
  # already full endpoint
} elsif ($endpoint =~ m{/v1\z}) {
  $endpoint .= '/chat/completions';
} else {
  $endpoint .= '/v1/chat/completions';
}

my $started = 0;
my $done    = 0;
my $inflight = 0;
my $ok = 0;
my $fail = 0;
my $with_content = 0;
my @lat_ms;
my %status_count;
my @errors;

my $t0 = time;
my $loop = Mojo::IOLoop->singleton;
my $ticker_id;

my $print_status = sub {
  my $elapsed = time - $t0;
  $elapsed = 0.000001 if $elapsed <= 0;
  my $rps = $done / $elapsed;
  my $p50 = _percentile(\@lat_ms, 50);
  my $p95 = _percentile(\@lat_ms, 95);
  my $line = sprintf(
    "\r%6.1fs started=%d inflight=%d done=%d/%d ok=%d fail=%d content=%d rps=%.2f p50=%.1fms p95=%.1fms",
    $elapsed,
    $started,
    $inflight,
    $done,
    $requests,
    $ok,
    $fail,
    $with_content,
    $rps,
    $p50,
    $p95,
  );
  print $line;
};

my $finish = sub {
  $print_status->();
  print "\n";

  my $elapsed = time - $t0;
  $elapsed = 0.000001 if $elapsed <= 0;
  my $rps = $done / $elapsed;
  my $p50 = _percentile(\@lat_ms, 50);
  my $p95 = _percentile(\@lat_ms, 95);
  my $p99 = _percentile(\@lat_ms, 99);

  print "\nSummary\n";
  print "  endpoint    : $endpoint\n";
  print "  model       : $model\n";
  print "  requests    : $requests\n";
  print "  concurrency : $concurrency\n";
  printf "  elapsed     : %.2fs\n", $elapsed;
  printf "  throughput  : %.2f req/s\n", $rps;
  print "  ok/fail     : $ok/$fail\n";
  print "  with content: $with_content\n";
  printf "  latency ms  : p50=%.1f p95=%.1f p99=%.1f\n", $p50, $p95, $p99;

  if (%status_count) {
    print "  status      :";
    for my $code (sort { $a <=> $b } keys %status_count) {
      print " $code=$status_count{$code}";
    }
    print "\n";
  }

  if ($show_errors && @errors) {
    print "\nErrors\n";
    my $max = @errors < 20 ? scalar(@errors) : 20;
    for my $i (0 .. $max - 1) {
      print "  - $errors[$i]\n";
    }
    my $more = @errors - $max;
    print "  ... $more more\n" if $more > 0;
  }

  my %summary = (
    endpoint      => $endpoint,
    model         => $model,
    requests      => $requests,
    concurrency   => $concurrency,
    elapsed_s     => 0 + sprintf('%.6f', $elapsed),
    throughput_rps=> 0 + sprintf('%.6f', $rps),
    ok            => $ok,
    fail          => $fail,
    with_content  => $with_content,
    p50_ms        => 0 + sprintf('%.3f', $p50),
    p95_ms        => 0 + sprintf('%.3f', $p95),
    p99_ms        => 0 + sprintf('%.3f', $p99),
    status        => \%status_count,
  );

  printf "RESULT endpoint=%s ok=%d fail=%d rps=%.2f p50_ms=%.1f p95_ms=%.1f p99_ms=%.1f\n",
    $endpoint, $ok, $fail, $rps, $p50, $p95, $p99;
  print encode_json(\%summary), "\n" if $json_out;

  exit($fail ? 1 : 0);
};

my $pump;
$pump = sub {
  while ($inflight < $concurrency && $started < $requests) {
    my $id = $started++;
    $inflight++;
    my $req_t0 = time;

    my %headers = ('Content-Type' => 'application/json');
    $headers{Authorization} = "Bearer $api_key" if defined($api_key) && length($api_key);

    my $payload = {
      model => $model,
      messages => [
        { role => 'user', content => $prompt },
      ],
      temperature => 0,
      max_tokens  => $max_tokens,
    };

    $ua->post_p($endpoint => \%headers => json => $payload)->then(
      sub {
        my ($tx) = @_;
        my $ms = (time - $req_t0) * 1000;
        push @lat_ms, $ms;
        $done++;
        $inflight--;

        my $code = $tx->res->code // 599;
        $status_count{$code}++;

        if ($tx->res->is_success) {
          $ok++;
          my $json = $tx->res->json;
          my $content = '';
          if (ref($json) eq 'HASH' && ref($json->{choices}) eq 'ARRAY' && @{$json->{choices}}) {
            my $msg = $json->{choices}[0]{message};
            $content = $msg->{content} if ref($msg) eq 'HASH' && defined($msg->{content});
          }
          $with_content++ if defined($content) && length($content);
        } else {
          $fail++;
          my $body = $tx->res->body // '';
          $body =~ s/\s+/ /g;
          $body = substr($body, 0, 240);
          push @errors, "id=$id status=$code body=$body";
        }

        if ($done >= $requests && $inflight == 0) {
          $loop->remove($ticker_id) if defined($ticker_id);
          $finish->();
          return;
        }

        $pump->();
        return;
      }
    )->catch(
      sub {
        my ($err) = @_;
        my $ms = (time - $req_t0) * 1000;
        push @lat_ms, $ms;
        $done++;
        $inflight--;
        $fail++;
        $status_count{599}++;
        push @errors, "id=$id transport=$err";

        if ($done >= $requests && $inflight == 0) {
          $loop->remove($ticker_id) if defined($ticker_id);
          $finish->();
          return;
        }

        $pump->();
        return;
      }
    );
  }
};

$ticker_id = $loop->recurring($status_interval => sub { $print_status->() });
$pump->();
$loop->start;

sub _percentile {
  my ($arr, $p) = @_;
  return 0 unless ref($arr) eq 'ARRAY' && @$arr;
  my @sorted = sort { $a <=> $b } @$arr;
  return $sorted[0] if @sorted == 1;
  my $rank = ($p / 100) * ($#sorted);
  my $lo = int($rank);
  my $hi = $lo + 1;
  return $sorted[$lo] if $hi > $#sorted;
  my $frac = $rank - $lo;
  return $sorted[$lo] + ($sorted[$hi] - $sorted[$lo]) * $frac;
}

sub _usage {
  return <<'USAGE';
Usage:
  perl examples/skeid-parallel-smoke.pl [options]

Options:
  --base-url URL          Skeid base URL or OpenAI /v1 URL
                          (default: http://127.0.0.1:8090)
  --model NAME            Model name (default: qwen2.5-7b-instruct)
  --requests, -n N        Total requests (default: 10)
  --concurrency, -c N     Parallel in-flight requests (default: 10)
  --timeout SEC           Request timeout seconds (default: 120)
  --max-tokens N          max_tokens per request (default: 32)
  --prompt TEXT           User prompt text
  --api-key KEY           Optional Skeid bearer key
  --status-interval SEC   Live status refresh interval (default: 0.5)
  --show-errors           Print error samples at the end
  --json                  Print a JSON summary line after RESULT
USAGE
}
