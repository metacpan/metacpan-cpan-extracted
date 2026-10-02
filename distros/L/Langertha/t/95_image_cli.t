#!/usr/bin/env perl
# ABSTRACT: Tests for the langertha_image CLI

use strict;
use warnings;

use Test2::Bundle::More;

# bin/langertha_image spends money at a provider, so the properties that
# protect the user are pinned here against a local daemon (never a real
# provider): the two backends never leak configuration into each other, every
# target is checked before the first request, malformed provider output never
# leaves a finished-looking file, and no secret (key, signed URL token, raw
# payload) reaches stdout or stderr. (karr k368)

use lib 't/lib';
use Test::LocalHTTPDaemon;

use File::Temp qw( tempdir );
use Encode ();
use HTTP::Response;
use IPC::Open3 qw( open3 );
use JSON::MaybeXS qw( decode_json encode_json );
use MIME::Base64 qw( encode_base64 );
use Path::Tiny qw( path );
use Symbol qw( gensym );

my $root   = path(__FILE__)->absolute->parent->parent;
my $script = $root->child('bin/langertha_image');

# 1x1 transparent PNG.
my $png = MIME::Base64::decode_base64(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==');
my $png2 = $png . "\0";   # a second, distinguishable "image"

sub run_cli {
  my (%request) = @_;
  my @include = map { ( '-I', "$_" ) } grep { !ref } @INC;

  local %ENV = (
    HOME   => $request{home},
    LANG   => 'C.UTF-8',
    LC_ALL => 'C.UTF-8',
    %{ $request{environment} // {} },
  );

  my $stderr = gensym;
  my $pid = open3( my $stdin, my $stdout, $stderr,
    $^X, @include, "$script", @{ $request{arguments} // [] } );
  close $stdin;
  my $stdout_text = do { local $/; <$stdout> // '' };
  my $stderr_text = do { local $/; <$stderr> // '' };
  waitpid $pid, 0;

  return { stdout => $stdout_text, stderr => $stderr_text, exit => $? >> 8, signal => $? & 127 };
}

sub json_response {
  my ($data) = @_;
  return HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'application/json' ],
    encode_json( { model => 'gpt-image-2',
      usage => { input_tokens => 5, output_tokens => 7, total_tokens => 12 }, %{$data} } ) );
}

sub b64_item { return { b64_json => encode_base64( $_[0], '' ) } }

# A daemon whose /v1/images/generations answer comes from $images (an ArrayRef
# of data items, or a CODE ref returning the whole response) and which serves
# /img/* downloads from %$files. Every request is logged to a file the parent
# reads back, since the handler runs in the forked daemon.
sub image_server {
  my ( $log, $images, $files ) = @_;
  $files //= {};
  return Test::LocalHTTPDaemon->start( sub {
    my ($req) = @_;
    my $entry = { method => $req->method, path => $req->uri->path,
      authorization => scalar $req->header('Authorization'),
      body => $req->method eq 'POST' ? decode_json( $req->content ) : undef };
    $log->append( encode_json($entry) . "\n" );
    if ( $req->uri->path eq '/v1/images/generations' ) {
      return ref $images eq 'CODE' ? $images->($req) : json_response( { data => $images } );
    }
    if ( $req->uri->path =~ m{\A/img/(\w+)} ) {
      my $file = $files->{$1};
      return HTTP::Response->new( 404, 'Not Found', [], 'nope' ) unless defined $file;
      return HTTP::Response->new( 200, 'OK', [ 'Content-Type' => $file->[0] ], $file->[1] );
    }
    return HTTP::Response->new( 404, 'Not Found', [], '' );
  } );
}

sub requests_of { my ($log) = @_; return -e $log ? map { decode_json($_) } $log->lines : () }

sub leftovers { my ($dir) = @_; return grep { /\A\.langertha_image-/ } map { $_->basename } path($dir)->children }

# --- Task 1: contract ---

subtest 'help and executable contract' => sub {
  my $home = tempdir( CLEANUP => 1 );
  my $run = run_cli( home => $home, arguments => ['--help'] );
  is $run->{exit}, 0, 'help exits 0';
  is $run->{stderr}, '', 'help writes nothing to stderr';
  like $run->{stdout}, qr/--backend\s+proxy\|openai/, 'help names the backends';
  like $run->{stdout}, qr/--prompt-file/, 'help names --prompt-file';
  like $run->{stdout}, qr/--prompt-prefix/, 'help names --prompt-prefix';
  like $run->{stdout}, qr/LANGERTHA_IMAGE_PROXY_URL/, 'help names the proxy URL variable';
  like $run->{stdout}, qr/LANGERTHA_IMAGE_OPENAI_URL/, 'help names the Platform URL variable';
  ok -x "$script", 'CLI is executable';
};

subtest 'prompt source validation' => sub {
  my $home = tempdir( CLEANUP => 1 );
  isnt run_cli( home => $home, arguments => [] )->{exit}, 0, 'no prompt';
  isnt run_cli( home => $home, arguments => [ '', '--output', "$home/x.png" ] )->{exit}, 0, 'empty prompt';
  isnt run_cli( home => $home, arguments => [ 'one', 'two' ] )->{exit}, 0, 'two prompts';

  my $prompt = path($home)->child('prompt.txt');
  $prompt->spew_utf8("Main prompt\n");
  isnt run_cli( home => $home, arguments => [ '--prompt-file', "$prompt", 'duplicate' ] )->{exit}, 0,
    'prompt file plus positional prompt';
};

subtest 'backend and scalar option validation' => sub {
  my $home = tempdir( CLEANUP => 1 );
  for my $arguments (
    [ '--backend', 'auto', 'prompt' ],
    [ '--backend', 'unknown', 'prompt' ],
    [ '--backend', 'proxy', 'prompt' ],
    [ '--n', '0', 'prompt' ],
    [ '--n', '11', 'prompt' ],
    [ '--n', 'many', 'prompt' ],
    [ '--backend', 'proxy', '--url', 'http://user:pass@host/v1', 'prompt' ],
    [ '--backend', 'proxy', '--url', 'http://host/v1?token=secret', 'prompt' ],
    [ '--backend', 'proxy', '--url', 'http://host/not-v1', 'prompt' ],
  ) {
    my $run = run_cli( home => $home, arguments => $arguments );
    isnt $run->{exit}, 0, "rejected: @{$arguments}";
    unlike $run->{stdout} . $run->{stderr}, qr/pass\@|token=secret/, 'and does not echo the secret';
  }

  my $secret = 'SHOULD_NOT_APPEAR';
  my $run = run_cli( home => $home, arguments => [ "--api-key=$secret", 'prompt' ] );
  isnt $run->{exit}, 0, 'an API key option is unknown';
  unlike $run->{stdout} . $run->{stderr}, qr/\Q$secret\E/, 'and its value is not echoed';
};

subtest 'backend precedence and isolation of the URL variables' => sub {
  my $home = tempdir( CLEANUP => 1 );
  my $log  = path($home)->child('log');
  my $server = image_server( $log, [ b64_item($png) ] );
  my $dead   = 'http://127.0.0.1:1/v1';

  # CLI beats environment: the environment says proxy (with a dead URL), the option says openai.
  my $target = path($home)->child('a.png');
  my $run = run_cli( home => $home,
    arguments   => [ '--backend', 'openai', '--url', $server->url . '/v1', '--output', "$target", 'p' ],
    environment => { LANGERTHA_IMAGE_BACKEND => 'proxy', LANGERTHA_IMAGE_PROXY_URL => $dead,
      LANGERTHA_OPENAI_API_KEY => 'fake-platform-key' } );
  is $run->{exit}, 0, 'CLI backend wins over LANGERTHA_IMAGE_BACKEND' or diag $run->{stderr};
  like $run->{stderr}, qr/^backend: openai$/m, 'backend reported';

  # environment beats the built-in default; the proxy variable is not used by openai.
  my $target2 = path($home)->child('b.png');
  $run = run_cli( home => $home,
    arguments   => [ '--output', "$target2", 'p' ],
    environment => { LANGERTHA_IMAGE_BACKEND => 'proxy', LANGERTHA_IMAGE_PROXY_URL => $server->url . '/v1' } );
  is $run->{exit}, 0, 'environment backend used' or diag $run->{stderr};
  like $run->{stderr}, qr/^backend: proxy$/m, 'proxy backend reported';

  my $proxy_connections = $server->connection_count;

  # openai mode never touches the proxy URL variable: with a Platform key and its own URL,
  # the proxy daemon must see zero connections and the Platform daemon the request.
  my $platform_log = path($home)->child('platform-log');
  my $platform = image_server( $platform_log, [ b64_item($png) ] );
  my $target3 = path($home)->child('c.png');
  $run = run_cli( home => $home,
    arguments   => [ '--backend', 'openai', '--output', "$target3", 'p' ],
    environment => { LANGERTHA_IMAGE_OPENAI_URL => $platform->url . '/v1',
      LANGERTHA_IMAGE_PROXY_URL => $server->url . '/v1', LANGERTHA_OPENAI_API_KEY => 'fake-platform-key' } );
  is $run->{exit}, 0, 'openai backend used its own URL variable' or diag $run->{stderr};
  is $platform->connection_count, 1, 'Platform daemon got the request';
  is scalar( @{ [ requests_of($platform_log) ] } ), 1, 'exactly one Platform request';
  is $server->connection_count, $proxy_connections, 'proxy daemon saw no new connection';
};

subtest '_resolve_backend_url unit: the two URL variables never cross' => sub {
  my $loaded = do "$script";
  ok $loaded, 'script loads without running main' or diag $@;
  my $proxy_url  = 'http://proxy.example/v1';
  my $openai_url = 'http://platform.example/v1';

  is_deeply [ main::_resolve_backend_url( 'openai', undef, { LANGERTHA_IMAGE_PROXY_URL => $proxy_url } ) ],
    [ 'openai', undef ], 'openai ignores the proxy variable';
  is_deeply [ main::_resolve_backend_url( 'openai', undef,
      { LANGERTHA_IMAGE_PROXY_URL => $proxy_url, LANGERTHA_IMAGE_OPENAI_URL => $openai_url } ) ],
    [ 'openai', $openai_url ], 'openai takes its own variable';
  ok !eval { main::_resolve_backend_url( 'proxy', undef, { LANGERTHA_IMAGE_OPENAI_URL => $openai_url } ); 1 },
    'proxy does not accept the openai variable';
  like $@, qr/proxy backend requires/, 'and says why';
  is_deeply [ main::_resolve_backend_url( 'proxy', undef,
      { LANGERTHA_IMAGE_PROXY_URL => $proxy_url, LANGERTHA_IMAGE_OPENAI_URL => $openai_url } ) ],
    [ 'proxy', $proxy_url ], 'proxy takes its own variable';
  is_deeply [ main::_resolve_backend_url( 'proxy', 'http://cli.example/v1/', { LANGERTHA_IMAGE_PROXY_URL => $proxy_url } ) ],
    [ 'proxy', 'http://cli.example/v1' ], '--url wins, trailing slash trimmed';

  is_deeply [ main::_resolve_backend_url( undef, undef, {} ) ], [ 'openai', undef ], 'default backend is openai';
  is_deeply [ main::_resolve_backend_url( undef, undef,
      { LANGERTHA_IMAGE_BACKEND => 'proxy', LANGERTHA_IMAGE_PROXY_URL => $proxy_url } ) ],
    [ 'proxy', $proxy_url ], 'environment backend beats the default';
  is_deeply [ main::_resolve_backend_url( 'openai', undef,
      { LANGERTHA_IMAGE_BACKEND => 'proxy', LANGERTHA_IMAGE_PROXY_URL => $proxy_url } ) ],
    [ 'openai', undef ], 'CLI backend beats the environment backend';

  is main::_redacted_url('http://h/x?sig=SECRET#f'), 'http://h/x', 'http URL loses query and fragment';
  is main::_redacted_url('data:image/png;base64,AAAA'), '<data: URL>', 'data: URL does not die';

  my $home = tempdir( CLEANUP => 1 );
  my $target = path($home)->child('t.png');
  $target->spew_raw('KEEP');
  ok !eval { main::_write_image_bytes( $png, $target, 0 ); 1 }, 'no-clobber write refuses an existing target';
  is $target->slurp_raw, 'KEEP', 'existing file untouched';
  is_deeply [ leftovers($home) ], [], 'no temp file';
  main::_write_image_bytes( $png, $target, 1 );
  is $target->slurp_raw, $png, 'forced write replaces';
};

# --- Task 2: provider request, Base64, atomic output ---

subtest 'proxy backend: no Authorization header, request body, stdout/stderr split' => sub {
  my $home = tempdir( CLEANUP => 1 );
  my $log  = path($home)->child('log');
  my $server = image_server( $log, [ b64_item($png) ] );
  my $target = path($home)->child('out.png');

  my $run = run_cli( home => $home,
    arguments => [ '--backend', 'proxy', '--url', $server->url . '/v1', '--output', "$target",
      '--model', 'gpt-image-2', '--size', '1024x1024', '--quality', 'high', '--background', 'opaque',
      '--prompt-prefix', 'STYLE', 'Main prompt' ],
    environment => { LANGERTHA_OPENAI_API_KEY => 'fake-ambient-key' } );

  is $run->{exit}, 0, 'exit 0' or diag $run->{stderr};
  is $run->{stdout}, "$target\n", 'stdout is only the path';
  unlike $run->{stdout} . $run->{stderr}, qr/fake-ambient-key|b64_json|Main prompt/, 'no key, payload or prompt echoed';
  is path($target)->slurp_raw, $png, 'file holds the decoded image';
  like $run->{stderr}, qr/^backend: proxy$/m, 'backend on stderr';
  like $run->{stderr}, qr/^model: gpt-image-2$/m, 'model on stderr';
  like $run->{stderr}, qr/^usage: input_tokens=5 output_tokens=7 total_tokens=12$/m, 'usage on stderr';
  like $run->{stderr}, qr/^runtime: \d+(?:\.\d+)? seconds$/m, 'runtime on stderr';

  my @requests = requests_of($log);
  is scalar(@requests), 1, 'one request';
  is $requests[0]{path}, '/v1/images/generations', 'images route';
  ok !defined $requests[0]{authorization}, 'no Authorization header';
  is $requests[0]{body}{prompt}, "STYLE\n\nMain prompt", 'prefix is its own paragraph before the prompt';
  is $requests[0]{body}{$_->[0]}, $_->[1], "body $_->[0]" for
    [ model => 'gpt-image-2' ], [ n => 1 ], [ size => '1024x1024' ], [ quality => 'high' ],
    [ background => 'opaque' ];
  is( ( stat $target )[2] & 0777, 0666 & ~umask, 'final file has ordinary permissions' );
};

subtest 'openai backend: normal key resolution' => sub {
  my $home = tempdir( CLEANUP => 1 );
  my $log  = path($home)->child('log');
  my $server = image_server( $log, [ b64_item($png) ] );
  my $target = path($home)->child('out.png');

  my $run = run_cli( home => $home,
    arguments   => [ '--backend', 'openai', '--url', $server->url . '/v1', '--output', "$target", 'p' ],
    environment => { LANGERTHA_OPENAI_API_KEY => 'fake-platform-key', LANGERTHA_IMAGE_PROXY_URL => 'http://127.0.0.1:1/v1' } );
  is $run->{exit}, 0, 'exit 0' or diag $run->{stderr};
  my @requests = requests_of($log);
  is $requests[0]{authorization}, 'Bearer fake-platform-key', 'Bearer from LANGERTHA_OPENAI_API_KEY';
  unlike $run->{stdout} . $run->{stderr}, qr/fake-platform-key/, 'key never printed';
};

subtest 'prompt file, prompt prefix from environment, default output path' => sub {
  my $home = tempdir( CLEANUP => 1 );
  my $log  = path($home)->child('log');
  my $server = image_server( $log, [ b64_item($png) ] );
  my $file = path($home)->child('prompt.txt');
  $file->spew_utf8("Ein Lama am Werk \x{fc}ber Nacht\n");

  my $run = run_cli( home => $home,
    arguments   => [ '--backend', 'proxy', '--url', $server->url . '/v1', '--prompt-file', "$file" ],
    environment => { LANGERTHA_IMAGE_PROMPT_PREFIX => 'ENVSTYLE' } );
  is $run->{exit}, 0, 'exit 0' or diag $run->{stderr};
  my ($printed) = split /\n/, $run->{stdout};
  like $printed, qr{\A\Q$home\E/langertha-image-ein-lama-am-werk-ber-nacht\.png\z}, 'default name under HOME';
  ok -f $printed, 'default file written';
  my ($request) = requests_of($log);
  like $request->{body}{prompt}, qr/\AENVSTYLE\n\nEin Lama/, 'environment prefix used';

  # the option overrides the environment
  my $log2 = path($home)->child('log2');
  my $server2 = image_server( $log2, [ b64_item($png) ] );
  $run = run_cli( home => $home,
    arguments   => [ '--backend', 'proxy', '--url', $server2->url . '/v1', '--force',
      '--prompt-prefix', 'OPTSTYLE', 'x' ],
    environment => { LANGERTHA_IMAGE_PROMPT_PREFIX => 'ENVSTYLE' } );
  is $run->{exit}, 0, 'second run ok' or diag $run->{stderr};
  ($request) = requests_of($log2);
  like $request->{body}{prompt}, qr/\AOPTSTYLE\n\nx\z/, 'option prefix overrides environment';
};

# --- Task 3: URL results, multi image, failure safety ---

sub proxy_args {
  my ( $server, @rest ) = @_;
  return [ '--backend', 'proxy', '--url', $server->url . '/v1', @rest ];
}

subtest 'URL result is downloaded' => sub {
  my $home = tempdir( CLEANUP => 1 );
  my $log  = path($home)->child('log');
  my $server = image_server( $log, sub {
    my ($req) = @_;
    return json_response( { data => [ { url => 'http://' . $req->header('Host') . '/img/ok?sig=SECRETTOKEN' } ] } ) },
    { ok => [ 'image/png', $png ] } );
  my $target = path($home)->child('u.png');
  my $run = run_cli( home => $home, arguments => proxy_args( $server, '--output', "$target", 'p' ) );
  is $run->{exit}, 0, 'exit 0' or diag $run->{stderr};
  is $run->{stdout}, "$target\n", 'stdout path';
  is path($target)->slurp_raw, $png, 'downloaded bytes';
  is_deeply [ leftovers($home) ], [], 'no temp leftovers';
};

subtest 'n=2 writes suffixed files in data order' => sub {
  my $home = tempdir( CLEANUP => 1 );
  my $log  = path($home)->child('log');
  my $server = image_server( $log, [ b64_item($png), b64_item($png2) ] );
  my $target = path($home)->child('base.png');
  my $run = run_cli( home => $home, arguments => proxy_args( $server, '--n', 2, '--output', "$target", 'p' ) );
  is $run->{exit}, 0, 'exit 0' or diag $run->{stderr};
  my @paths = map { path($home)->child($_) } 'base-1.png', 'base-2.png';
  is $run->{stdout}, join( '', map { "$_\n" } @paths ), 'both paths on stdout in order';
  is path( $paths[0] )->slurp_raw, $png, 'first image first';
  is path( $paths[1] )->slurp_raw, $png2, 'second image second';
  ok !-e $target, 'unsuffixed path not created';
  my ($request) = requests_of($log);
  is $request->{body}{n}, 2, 'n sent';
};

subtest 'existing targets stop everything before any request' => sub {
  my $home = tempdir( CLEANUP => 1 );
  my $log  = path($home)->child('log');
  my $server = image_server( $log, [ b64_item($png), b64_item($png) ] );

  my $target = path($home)->child('exists.png');
  $target->spew_raw('KEEP');
  my $run = run_cli( home => $home, arguments => proxy_args( $server, '--output', "$target", 'p' ) );
  isnt $run->{exit}, 0, 'existing target refused';
  is $target->slurp_raw, 'KEEP', 'existing file untouched';
  is scalar(@{[ requests_of($log) ]}), 0, 'no provider request';
  is $server->connection_count, 0, 'no connection at all';

  my $base = path($home)->child('m.png');
  path($home)->child('m-2.png')->spew_raw('KEEP2');
  $run = run_cli( home => $home, arguments => proxy_args( $server, '--n', 2, '--output', "$base", 'p' ) );
  isnt $run->{exit}, 0, 'one existing target among two refused';
  ok !-e path($home)->child('m-1.png'), 'the free target was not written';
  is $server->connection_count, 0, 'still no connection';

  # a dangling symlink counts as existing
  my $link = path($home)->child('link.png');
  symlink '/nonexistent/x', "$link";
  $run = run_cli( home => $home, arguments => proxy_args( $server, '--output', "$link", 'p' ) );
  isnt $run->{exit}, 0, 'dangling symlink refused';
  is $server->connection_count, 0, 'no connection for the symlink';

  # missing parent directory is refused before the request, and not created
  $run = run_cli( home => $home, arguments => proxy_args( $server, '--output', "$home/nodir/x.png", 'p' ) );
  isnt $run->{exit}, 0, 'missing parent refused';
  ok !-e "$home/nodir", 'not created';
  is $server->connection_count, 0, 'no connection for the missing directory';
};

subtest '--force replaces only with a valid result' => sub {
  my $home = tempdir( CLEANUP => 1 );
  my $target = path($home)->child('f.png');

  my $log = path($home)->child('log');
  my $good = image_server( $log, [ b64_item($png2) ] );
  $target->spew_raw('OLD');
  my $run = run_cli( home => $home, arguments => proxy_args( $good, '--force', '--output', "$target", 'p' ) );
  is $run->{exit}, 0, 'forced run ok' or diag $run->{stderr};
  is $target->slurp_raw, $png2, 'file replaced';

  my $bad = image_server( path($home)->child('log2'), [ { b64_json => encode_base64( 'not an image', '' ) } ] );
  $target->spew_raw('OLD');
  $run = run_cli( home => $home, arguments => proxy_args( $bad, '--force', '--output', "$target", 'p' ) );
  isnt $run->{exit}, 0, 'malformed result fails';
  is $target->slurp_raw, 'OLD', 'existing file unchanged';
  is_deeply [ leftovers($home) ], [], 'no temp leftovers';
};

subtest 'malformed responses leave no file' => sub {
  my $good_b64 = encode_base64( $png, '' );
  my @cases = (
    [ 'wrong count'            => [ b64_item($png), b64_item($png) ] ],
    [ 'non-hash item'          => [ 'string' ] ],
    [ 'neither source'         => [ {} ] ],
    [ 'both sources'           => [ { b64_json => $good_b64, url => 'http://127.0.0.1:1/x.png' } ] ],
    [ 'empty b64'              => [ { b64_json => '' } ] ],
    [ 'invalid base64'         => [ { b64_json => '!!!notbase64!!!' } ] ],
    [ 'non-canonical base64'   => [ { b64_json => do { (my $copy = $good_b64) =~ s{gg==\z}{gh==}; $copy } } ] ],
    [ 'non-image bytes'        => [ b64_item('<html>nope</html>') ] ],
    [ 'ref b64'                => [ { b64_json => [] } ] ],
  );
  for my $case (@cases) {
    my ( $name, $data ) = @{$case};
    my $home = tempdir( CLEANUP => 1 );
    my $server = image_server( path($home)->child('log'), $data );
    my $target = path($home)->child('x.png');
    my $run = run_cli( home => $home, arguments => proxy_args( $server, '--output', "$target", 'p' ) );
    isnt $run->{exit}, 0, "$name: fails";
    ok !-e $target, "$name: no final file";
    is_deeply [ leftovers($home) ], [], "$name: no temp file";
    is $run->{stdout}, '', "$name: nothing on stdout";
  }
};

subtest 'bad downloads leave no file and hide the signed URL' => sub {
  for my $case (
    [ 'HTML body' => [ 'text/html', '<html>login</html>' ] ],
    [ 'empty body' => [ 'image/png', '' ] ],
    [ 'missing' => undef ],
  ) {
    my ( $name, $file ) = @{$case};
    my $home = tempdir( CLEANUP => 1 );
    my $server = image_server( path($home)->child('log'), sub {
      my ($req) = @_;
      return json_response( { data => [ { url => 'http://' . $req->header('Host') . '/img/thing?sig=SECRETTOKEN' } ] } ) },
      defined $file ? { thing => $file } : {} );
    my $target = path($home)->child('x.png');
    my $run = run_cli( home => $home, arguments => proxy_args( $server, '--output', "$target", 'p' ) );
    isnt $run->{exit}, 0, "$name: fails";
    ok !-e $target, "$name: no final file";
    is_deeply [ leftovers($home) ], [], "$name: no temp file";
    unlike $run->{stdout} . $run->{stderr}, qr/SECRETTOKEN/, "$name: signed token not printed";
  }
};

subtest 'partial multi-image failure keeps finished images and names them' => sub {
  my $home = tempdir( CLEANUP => 1 );
  my $server = image_server( path($home)->child('log'), sub {
    my ($req) = @_;
    return json_response( { data => [ b64_item($png),
      { url => 'http://' . $req->header('Host') . '/img/gone?sig=SECRETTOKEN' } ] } ) }, {} );
  my $base = path($home)->child('p.png');
  my $run = run_cli( home => $home, arguments => proxy_args( $server, '--n', 2, '--output', "$base", 'p' ) );
  isnt $run->{exit}, 0, 'fails';
  my ( $first, $second ) = map { path($home)->child($_) } 'p-1.png', 'p-2.png';
  is $first->slurp_raw, $png, 'first image kept';
  ok !-e $second, 'second image absent';
  is_deeply [ leftovers($home) ], [], 'no temp file';
  like $run->{stderr}, qr/^already finalized: \Q$first\E$/m, 'stderr names the finished image';
  is $run->{stdout}, "$first\n", 'stdout lists exactly the finished image';
  unlike $run->{stdout} . $run->{stderr}, qr/SECRETTOKEN/, 'signed token not printed';
};

subtest 'provider HTTP error is a failure without a file' => sub {
  my $home = tempdir( CLEANUP => 1 );
  my $server = image_server( path($home)->child('log'), sub {
    return HTTP::Response->new( 500, 'Boom', [ 'Content-Type' => 'application/json' ],
      encode_json( { error => { message => 'provider exploded' } } ) ) } );
  my $target = path($home)->child('x.png');
  my $run = run_cli( home => $home, arguments => proxy_args( $server, '--output', "$target", 'p' ) );
  isnt $run->{exit}, 0, 'fails';
  ok !-e $target, 'no file';
  is $run->{stdout}, '', 'nothing on stdout';
};

subtest 'non-ASCII prompt, prefix and output path are not double-encoded' => sub {
  my $home = tempdir( CLEANUP => 1 );
  my $log  = path($home)->child('log');
  my $server = image_server( $log, [ b64_item($png) ] );
  my $name = Encode::encode( 'UTF-8', "bild-\x{fc}ber.png" );
  my $target = path($home)->child($name);

  my $run = run_cli( home => $home,
    arguments => proxy_args( $server, '--output', "$target",
      '--prompt-prefix', Encode::encode( 'UTF-8', "Stil \x{e4}" ), Encode::encode( 'UTF-8', "Lama \x{fc}ber" ) ) );
  is $run->{exit}, 0, 'exit 0' or diag $run->{stderr};
  is $run->{stdout}, "$target\n", 'stdout is the real byte path';
  ok -f $run->{stdout} =~ s/\n\z//r, 'the printed path exists on disk';
  my ($request) = requests_of($log);
  is $request->{body}{prompt}, "Stil \x{e4}\n\nLama \x{fc}ber", 'provider got the characters, not their bytes';

  my $run2 = run_cli( home => $home, arguments => proxy_args( $server, '--force', '--output', "$target", "bad \xff" ) );
  isnt $run2->{exit}, 0, 'invalid UTF-8 prompt is refused';
  like $run2->{stderr}, qr/not valid UTF-8/, 'with a reason';
};

subtest 'LANGERTHA_IMAGE_* defaults reach the request; options override them' => sub {
  my $home = tempdir( CLEANUP => 1 );
  my $log  = path($home)->child('log');
  my $server = image_server( $log, [ b64_item($png), b64_item($png) ] );
  my %env = ( LANGERTHA_IMAGE_N => 2, LANGERTHA_IMAGE_MODEL => 'env-model', LANGERTHA_IMAGE_SIZE => '512x512',
    LANGERTHA_IMAGE_QUALITY => 'low', LANGERTHA_IMAGE_BACKGROUND => 'transparent' );

  my $run = run_cli( home => $home, environment => \%env,
    arguments => proxy_args( $server, '--output', "$home/e.png", 'p' ) );
  is $run->{exit}, 0, 'env run ok' or diag $run->{stderr};
  my ($request) = requests_of($log);
  is $request->{body}{$_->[0]}, $_->[1], "env default $_->[0]" for
    [ n => 2 ], [ model => 'env-model' ], [ size => '512x512' ], [ quality => 'low' ], [ background => 'transparent' ];

  my $log2 = path($home)->child('log2');
  my $server2 = image_server( $log2, [ b64_item($png) ] );
  $run = run_cli( home => $home, environment => \%env,
    arguments => proxy_args( $server2, '--output', "$home/o.png", '--n', 1, '--model', 'cli-model',
      '--size', '1024x1024', '--quality', 'high', '--background', 'opaque', 'p' ) );
  is $run->{exit}, 0, 'override run ok' or diag $run->{stderr};
  ($request) = requests_of($log2);
  is $request->{body}{$_->[0]}, $_->[1], "option overrides $_->[0]" for
    [ n => 1 ], [ model => 'cli-model' ], [ size => '1024x1024' ], [ quality => 'high' ], [ background => 'opaque' ];
};

subtest 'data: URL result is materialized without dying in redaction' => sub {
  my $home = tempdir( CLEANUP => 1 );
  my $server = image_server( path($home)->child('log'),
    [ { url => 'data:image/png;base64,' . encode_base64( $png, '' ) } ] );
  my $target = path($home)->child('d.png');
  my $run = run_cli( home => $home, arguments => proxy_args( $server, '--output', "$target", 'p' ) );
  is $run->{exit}, 0, 'exit 0' or diag $run->{stderr};
  is $target->slurp_raw, $png, 'decoded bytes';
};

subtest 'a failed move leaves no temp file' => sub {
  my $home = tempdir( CLEANUP => 1 );
  my $server = image_server( path($home)->child('log'), [ b64_item($png) ] );
  my $target = path($home)->child('dir.png');
  $target->mkpath;   # rename of a file onto a directory fails
  my $run = run_cli( home => $home, arguments => proxy_args( $server, '--force', '--output', "$target", 'p' ) );
  isnt $run->{exit}, 0, 'fails';
  ok -d "$target", 'directory untouched';
  is_deeply [ leftovers($home) ], [], 'no temp file remains';
  is $run->{stdout}, '', 'nothing on stdout';
};

subtest 'usage is reported even when the paid response is malformed' => sub {
  my $home = tempdir( CLEANUP => 1 );
  my $server = image_server( path($home)->child('log'), [ {} ] );
  my $run = run_cli( home => $home, arguments => proxy_args( $server, '--output', "$home/x.png", 'p' ) );
  isnt $run->{exit}, 0, 'fails';
  like $run->{stderr}, qr/^usage: input_tokens=5 output_tokens=7 total_tokens=12$/m, 'tokens still reported';
  ok !-e "$home/x.png", 'no file';
};

done_testing;
