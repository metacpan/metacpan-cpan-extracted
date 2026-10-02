#!/usr/bin/env bash
# Smoke-test a built knarr binary against the pp runtime traps.
# Usage: verify-binary.sh <knarr-binary>
#
# Runs from a fresh PAR cache and a clean cwd, with the environment wiped
# (env -i): no PERL5LIB for the binary to lean on, no provider API keys, no
# LANGFUSE_* -- every request goes to a fake upstream on 127.0.0.1, nothing
# reaches an external service. The fake upstream and the HTTP client are
# core-only Perl (IO::Socket::INET), so the harness needs nothing beyond
# perl-base, which every Debian-ish target has; the binary itself needs no Perl.
set -euo pipefail
BIN=$(realpath "${1:?usage: verify-binary.sh <knarr-binary>}")
[ -x "$BIN" ] || { echo "FAIL: not an executable: $BIN" >&2; exit 1; }

work=$(mktemp -d)
cache=$(mktemp -d)
pids=()
cleanup() {
  for p in "${pids[@]}"; do kill "$p" 2>/dev/null || true; done
  wait 2>/dev/null || true
  [ -n "${KEEP_WORK:-}" ] && echo "kept $work" >&2 || rm -rf "$work" "$cache"
}
trap cleanup EXIT
mkdir -p "$work/home" "$work/cwd"
cd "$work/cwd"

kn() {
  env -i PATH=/usr/local/bin:/usr/bin:/bin HOME="$work/home" \
    PAR_GLOBAL_TEMP="$cache" "$BIN" "$@"
}
fail() {
  echo "FAIL: $*" >&2
  for f in "$work"/*.log; do
    [ -f "$f" ] && { echo "--- $f" >&2; tail -n 40 "$f" >&2; }
  done
  exit 1
}

# The fake upstream (OpenAI wire + Langfuse ingestion) and a raw HTTP client.
cat > "$work/fake.pl" <<'PERL'
use strict;
use warnings;
use IO::Socket::INET;

my $cmd = shift @ARGV;

if ( $cmd eq 'freeport' ) {
  my $s = IO::Socket::INET->new( Listen => 1, LocalAddr => '127.0.0.1', LocalPort => 0 ) or die $!;
  print $s->sockport, "\n";
  exit 0;
}

if ( $cmd eq 'serve' ) {
  my ( $portfile, $log ) = @ARGV;
  my $srv = IO::Socket::INET->new( Listen => 16, LocalAddr => '127.0.0.1', LocalPort => 0, ReuseAddr => 1 ) or die $!;
  open my $pf, '>', "$portfile.tmp" or die $!; print $pf $srv->sockport, "\n"; close $pf;
  rename "$portfile.tmp", $portfile or die $!;
  open my $lf, '>>', $log or die $!; $lf->autoflush(1);
  # One process per connection: knarr's startup probe, a sync model discovery
  # and the request under test can all be open against the fake at once.
  $SIG{CHLD} = 'IGNORE';
  while (1) {
    my $c = $srv->accept or next;
    my $pid = fork;
    if ( !defined $pid || $pid ) { close $c; next }
    close $srv;
    local $/ = "\r\n";
    my $line = <$c>; exit 0 unless defined $line;
    my ( $method, $path ) = split / /, $line;
    my %h;
    while ( my $l = <$c> ) {
      last if $l eq "\r\n";
      $l =~ s/\r\n$//;
      my ( $k, $v ) = split /:\s*/, $l, 2;
      $h{ lc $k } = $v;
    }
    my $body = '';
    if ( my $len = $h{'content-length'} ) { read $c, $body, $len }
    print $lf "$method $path\n";
    my $stream = $body =~ /"stream"\s*:\s*true/ ? 1 : 0;
    my $head = "HTTP/1.1 200 OK\r\nConnection: close\r\n";
    if ( $path =~ m{/models$} ) {
      my $j = '{"object":"list","data":[{"id":"fake-model","object":"model","owned_by":"fake"}]}';
      print $c $head, "Content-Type: application/json\r\nContent-Length: ", length($j), "\r\n\r\n", $j;
    }
    elsif ( $path =~ m{/chat/completions$} && $stream ) {
      print $c $head, "Content-Type: text/event-stream\r\n\r\n";
      for my $d ( '{"role":"assistant","content":"pong "}', '{"content":"from fake upstream"}' ) {
        print $c 'data: {"id":"chatcmpl-fake","object":"chat.completion.chunk","created":1700000000,"model":"fake-model","choices":[{"index":0,"delta":', $d, ',"finish_reason":null}]}', "\n\n";
      }
      print $c 'data: {"id":"chatcmpl-fake","object":"chat.completion.chunk","created":1700000000,"model":"fake-model","choices":[{"index":0,"delta":{},"finish_reason":"stop"}],"usage":{"prompt_tokens":3,"completion_tokens":4,"total_tokens":7}}', "\n\n";
      print $c "data: [DONE]\n\n";
    }
    elsif ( $path =~ m{/chat/completions$} ) {
      my $j = '{"id":"chatcmpl-fake","object":"chat.completion","created":1700000000,"model":"fake-model","choices":[{"index":0,"message":{"role":"assistant","content":"pong from fake upstream"},"finish_reason":"stop"}],"usage":{"prompt_tokens":3,"completion_tokens":4,"total_tokens":7},"system_fingerprint":"fake-upstream-bytes"}';
      print $c $head, "Content-Type: application/json\r\nContent-Length: ", length($j), "\r\n\r\n", $j;
    }
    elsif ( $path =~ m{^/api/public/} ) {
      my $j = '{"successes":[],"errors":[]}';
      print $c $head, "Content-Type: application/json\r\nContent-Length: ", length($j), "\r\n\r\n", $j;
    }
    else {
      print $c "HTTP/1.1 404 Not Found\r\nConnection: close\r\nContent-Length: 0\r\n\r\n";
    }
    close $c;
    exit 0;
  }
}

# Answers every connection with plain-HTTP bytes and hangs up: an https://
# upstream pointed here gets a TLS handshake failure right away.
if ( $cmd eq 'nottls' ) {
  my ($portfile) = @ARGV;
  my $srv = IO::Socket::INET->new( Listen => 16, LocalAddr => '127.0.0.1', LocalPort => 0, ReuseAddr => 1 ) or die $!;
  open my $pf, '>', "$portfile.tmp" or die $!; print $pf $srv->sockport, "\n"; close $pf;
  rename "$portfile.tmp", $portfile or die $!;
  while (1) {
    my $c = $srv->accept or next;
    print $c "HTTP/1.1 400 Bad Request\r\nConnection: close\r\nContent-Length: 0\r\n\r\n";
    close $c;
  }
}

if ( $cmd eq 'req' ) {
  my ( $port, $method, $path, $body ) = @ARGV;
  $body //= '';
  alarm 60;
  my $c = IO::Socket::INET->new( PeerAddr => '127.0.0.1', PeerPort => $port, Timeout => 5 ) or exit 2;
  print $c "$method $path HTTP/1.1\r\nHost: 127.0.0.1:$port\r\nConnection: close\r\n",
    "Authorization: Bearer sk-verify-dummy\r\nx-api-key: sk-verify-dummy\r\n",
    "anthropic-version: 2023-06-01\r\n",
    ( length $body ? "Content-Type: application/json\r\nContent-Length: " . length($body) . "\r\n" : () ),
    "\r\n", $body;
  # The server keeps the connection open after the response (Connection:
  # close notwithstanding), so read by Content-Length or by chunks, not to EOF.
  local $/ = "\r\n";
  my $head = <$c>;
  exit 3 unless defined $head;
  my %h;
  while ( my $l = <$c> ) {
    $head .= $l;
    last if $l eq "\r\n";
    $l =~ s/\r\n\z//;
    my ( $k, $v ) = split /:\s*/, $l, 2;
    $h{ lc $k } = $v;
  }
  my $res = '';
  if ( ( $h{'transfer-encoding'} // '' ) =~ /chunked/i ) {
    while ( defined( my $size = <$c> ) ) {
      $size = hex( ( split /[;\r]/, $size )[0] );
      last unless $size;
      my $buf;
      read $c, $buf, $size;
      $res .= $buf;
      <$c>;
    }
  }
  elsif ( defined $h{'content-length'} ) {
    read $c, $res, $h{'content-length'};
  }
  else {
    local $/;
    $res = <$c> // '';
  }
  print $head, $res;
  exit 0;
}
die "unknown command $cmd\n";
PERL
fake() { perl "$work/fake.pl" "$@"; }

# Trap 1: every command class MooX::Cmd loads by name from @ARGV.
kn --help >/dev/null || fail "knarr --help"
for cmd in start models check init container; do
  kn "$cmd" --help >/dev/null 2>&1 || fail "subcommand $cmd --help"
done
echo "trap1 (subcommand classes): OK"

# The fake upstream.
perl "$work/fake.pl" serve "$work/upstream.port" "$work/upstream.log" 2>"$work/fake.log" &
pids+=($!)
for _ in $(seq 50); do [ -s "$work/upstream.port" ] && break; sleep 0.1; done
up=$(cat "$work/upstream.port" 2>/dev/null) || fail "fake upstream did not start"
perl "$work/fake.pl" nottls "$work/nottls.port" 2>"$work/nottls.log" &
pids+=($!)
for _ in $(seq 50); do [ -s "$work/nottls.port" ] && break; sleep 0.1; done
nottls=$(cat "$work/nottls.port" 2>/dev/null) || fail "not-TLS listener did not start"
port=$(fake freeport)

cat > knarr.yaml <<YAML
listen:
  - "127.0.0.1:$port"
models:
  fake:
    engine: OpenAI
    model: fake-model
    url: http://127.0.0.1:$up/v1
    api_key: sk-verify-dummy
auto_discover: true
passthrough:
  openai: http://127.0.0.1:$up
  anthropic: https://127.0.0.1:$nottls
langfuse:
  url: http://127.0.0.1:$up
  public_key: pk-lf-verify
  secret_key: sk-lf-verify
logging:
  file: $work/cwd/requests.jsonl
YAML

# Trap 2: config commands. validate resolves engine classes through
# Module::Pluggable over the packed @INC; models auto-discovers over LWP.
kn check > "$work/check.log" 2>&1 || fail "knarr check"
grep -q 'Configuration OK' "$work/check.log" || fail "knarr check output"
# LOG_ANY_DEFAULT_ADAPTER: discovery errors are only logged at debug level.
env -i PATH=/usr/local/bin:/usr/bin:/bin HOME="$work/home" PAR_GLOBAL_TEMP="$cache" \
  LOG_ANY_DEFAULT_ADAPTER=Stderr "$BIN" models > "$work/models.log" 2>&1 || fail "knarr models"
grep -q '^fake ' "$work/models.log" || fail "knarr models: configured model missing"
grep -qE '^fake-model +OpenAI +fake-model +discovered' "$work/models.log" \
  || fail "knarr models: auto-discovered model missing (engine build or LWP failed?)"
kn models --format json > "$work/models-json.log" 2>&1 || fail "knarr models --format json"
grep -q '"id"' "$work/models-json.log" || fail "knarr models --format json output"
( cd "$work/home" \
  && env -i PATH=/usr/local/bin:/usr/bin:/bin HOME="$work/home" PAR_GLOBAL_TEMP="$cache" \
       OPENAI_API_KEY=sk-verify-dummy "$BIN" init -o gen.yaml ) > "$work/init.log" 2>&1 \
  || fail "knarr init"
grep -q 'OpenAI' "$work/home/gen.yaml" || fail "knarr init: generated config lacks OpenAI"
kn -c "$work/home/gen.yaml" check > "$work/check-gen.log" 2>&1 || fail "knarr check on init output"
echo "trap2 (check / models / init): OK"

# Trap 3: a real server, one request per wire format, routed and passthrough.
# exec: $! must be the server itself, not a subshell, for kill -0 and cleanup.
( exec env -i PATH=/usr/local/bin:/usr/bin:/bin HOME="$work/home" \
    PAR_GLOBAL_TEMP="$cache" "$BIN" --verbose start ) > "$work/start.log" 2>&1 &
server=$!
pids+=("$server")
ready=
for _ in $(seq 300); do
  kill -0 "$server" 2>/dev/null || fail "knarr start: server exited"
  if fake req "$port" GET /v1/models 2>/dev/null | grep -q '"fake"'; then ready=1; break; fi
  sleep 0.1
done
[ -n "$ready" ] || fail "knarr start: /v1/models never answered on port $port"

check_req() {
  local what=$1 want=$2 method=$3 path=$4 body=${5:-}
  local res
  res=$(fake req "$port" "$method" "$path" "$body") || fail "$what: no connection"
  grep -qF -- "$want" <<<"$res" || { echo "$res" > "$work/response.log"; fail "$what: expected '$want'"; }
}
check_req 'openai routed' 'pong from fake upstream' POST /v1/chat/completions \
  '{"model":"fake","messages":[{"role":"user","content":"ping"}]}'
check_req 'openai routed stream' 'data: [DONE]' POST /v1/chat/completions \
  '{"model":"fake","stream":true,"messages":[{"role":"user","content":"ping"}]}'
check_req 'anthropic routed stream' 'event: message_stop' POST /v1/messages \
  '{"model":"fake","max_tokens":16,"stream":true,"messages":[{"role":"user","content":"ping"}]}'
check_req 'ollama routed stream' '"done":true' POST /api/chat \
  '{"model":"fake","stream":true,"messages":[{"role":"user","content":"ping"}]}'
check_req 'ollama tags' '"models"' GET /api/tags
# Raw passthrough: the upstream's body comes back byte for byte, including a
# field no protocol formatter would carry over.
check_req 'openai passthrough' '"system_fingerprint":"fake-upstream-bytes"' POST /v1/chat/completions \
  '{"model":"not-configured","messages":[{"role":"user","content":"ping"}]}'
# TLS: the anthropic upstream is https:// on a listener that answers in plain
# HTTP, so the handshake must fail -- inside libssl, which proves
# IO::Socket::SSL, Net::SSLeay and libssl/libcrypto load from the binary. A
# load failure reads "Can't locate" instead.
fake req "$port" POST /v1/messages \
  '{"model":"not-configured","max_tokens":16,"messages":[{"role":"user","content":"ping"}]}' \
  > "$work/tls.log" 2>&1 || true
grep -qE 'SSL connect attempt failed|SSL routines' "$work/tls.log" \
  || fail "TLS: no SSL error for the https upstream -- did IO::Socket::SSL load?"
echo "trap3 (server: openai/anthropic/ollama routed, passthrough, TLS stack): OK"

# Langfuse flush and the JSONL request log: the decorators around the handler.
for _ in $(seq 100); do grep -q '/api/public/' "$work/upstream.log" && break; sleep 0.1; done
grep -q '/api/public/' "$work/upstream.log" || fail "tracing: no Langfuse ingestion reached the fake"
[ -s "$work/cwd/requests.jsonl" ] || fail "request log: requests.jsonl empty"
echo "trap4 (Langfuse tracing + request log): OK"

if grep -E "Can't locate|did not return a true value|Can't load" "$work"/*.log >&2; then
  fail "a module failed to load inside the binary"
fi
echo "verify: OK"
