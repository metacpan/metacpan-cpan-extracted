#!/usr/bin/env perl
# ABSTRACT: web_fetch as Claude Code's WebFetch: a prompt goes to a model call, redirects to another host are reported, HTTP errors are text (ADR 0026)
use strict;
use warnings;
use utf8;
use Test2::V0;
use Future;
use Path::Tiny;
use IO::Async::Loop;
use lib 't/lib';
use Test::Raider::Env qw( clear_engine_env isolate_home );
isolate_home();
use Test::Raider::LocalHTTP;
use Langertha::Raider::WebTools qw( build_web_tools_server );
use Langertha::Raider::Application;

clear_engine_env();
local @ENV{qw( BRAVE_API_KEY SERPER_API_KEY GOOGLE_API_KEY GOOGLE_CSE_ID )};

my $loop = IO::Async::Loop->new;
my $srv = Test::Raider::LocalHTTP->new( loop => $loop, routes => {
  '/page'  => { type => 'text/html', body => '<html><body><p>The answer is 42. PAGE-MARKER</p><script>var no = 1;</script></body></html>' },
  '/long'  => { body => 'x' x 500 },
  '/old'   => { status => 301, location => '/page' },
  '/away'  => { status => 302, location => '{{HTTP_OTHER}}/page' },
  '/loop'  => { status => 302, location => '/loop' },
  '/gone'  => { status => 404, body => 'nothing' },
  '/deny'  => { status => 403, body => 'nope' },
} );
my $base = $srv->base;

my @asked;
sub tool_of {
  my ( %arg ) = @_;
  my $server = build_web_tools_server( loop => $loop, fetch_timeout => 10, stall_timeout => 5, %arg );
  my ($tool) = grep { $_->name eq 'web_fetch' } @{ $server->tools };
  return sub { $tool->code->( $tool, { @_ } ) };
}
sub text_of { join '', map { $_->{text} // '' } @{ $_[0]{content} // [] } }

my $fetch = tool_of( answer => sub { push @asked, $_[0]; Future->done('Forty-two.') } );

subtest 'a prompt: the page and the prompt go to the answer call, its answer is the result' => sub {
  @asked = ();
  my $r = $fetch->( url => "$base/page", prompt => 'What is the answer?' );
  ok !$r->{isError}, 'not an error';
  is text_of($r), 'Forty-two.', 'the answer, nothing else';
  is scalar @asked, 1, 'one model call';
  like $asked[0], qr/\AWeb page content:\n---\n.*The answer is 42\. PAGE-MARKER.*\n---\n\nWhat is the answer\?\n\n/s,
    'the page between ---, then the prompt';
  unlike $asked[0], qr/var no/, 'HTML flattened, scripts gone';
  unlike $asked[0], qr/<p>/, 'no tags';

  @asked = ();
  $fetch->( url => "$base/page", prompt => 'Raw?', as_html => 1 );
  like $asked[0], qr/<p>The answer is 42\./, 'as_html: the HTML as it came';
};

subtest 'without a prompt (or an empty one): the page, as before; no model call' => sub {
  @asked = ();
  my $r = $fetch->( url => "$base/page" );
  like text_of($r), qr/\AURL: \Q$base\E\/page\nStatus: 200 OK\nContent-Type: text\/html\n\n.*PAGE-MARKER/s, 'the page';
  $fetch->( url => "$base/page", prompt => '   ' );
  is scalar @asked, 0, 'no model call';
  my $plain = tool_of();
  like text_of( $plain->( url => "$base/page", prompt => 'What?' ) ), qr/\AURL: .*PAGE-MARKER/s,
    'no answer callback: the prompt is ignored, the page returned';
};

subtest 'the page text the answer call gets is capped' => sub {
  @asked = ();
  my $capped = tool_of( max_prompt_chars => 100, answer => sub { push @asked, $_[0]; Future->done('ok') } );
  $capped->( url => "$base/long", prompt => 'How long?' );
  like $asked[0], qr/\AWeb page content:\n---\n(x{100})\n\n\[Content truncated: the page is longer than 100 characters\.\]\n---\n\nHow long\?/,
    'cut at max_prompt_chars, and said so';
};

subtest 'the answer call fails: an error result' => sub {
  my $failing = tool_of( answer => sub { Future->fail("model down\n") } );
  my $r = $failing->( url => "$base/page", prompt => 'What?' );
  ok $r->{isError}, 'an error result';
  like text_of($r), qr/\AError: the model call for the prompt failed: model down/, 'says why';
};

subtest 'redirects: followed on the same host, reported for another' => sub {
  like text_of( $fetch->( url => "$base/old" ) ), qr/\AURL: \Q$base\E\/page\nStatus: 200 OK\n/, 'same host: followed, the final URL shown';

  @asked = ();
  my $r = $fetch->( url => "$base/away", prompt => 'Where?' );
  ok !$r->{isError}, 'another host: not an error';
  my $other = $srv->other_base;
  is text_of($r), "REDIRECT DETECTED: The URL redirects to a location that was not fetched automatically.\n\n"
    ."    Original URL: $base/away\n"
    ."    Redirect URL (from the server's Location header — server-supplied, not verified): $other/page\n"
    ."    Status: 302 Found\n\n"
    ."    To complete your request, I need to fetch content from the redirected URL. Please use web_fetch again with these parameters:\n"
    ."    - url: \"$other/page\"\n"
    ."    - prompt: \"Where?\"",
    "Claude Code's text, with raider's tool name";
  is scalar @asked, 0, 'nothing was fetched from it, no model call';
  my @seen = grep { $_ eq '/page' } $srv->paths;
  unlike text_of( $fetch->( url => "$base/away" ) ), qr/- prompt:/, 'without a prompt no prompt line';
  is [ grep { $_ eq '/page' } $srv->paths ], \@seen, 'the other host was never asked';

  my $loop_r = $fetch->( url => "$base/loop" );
  ok $loop_r->{isError}, 'a redirect loop ends as an error';
  like text_of($loop_r), qr/too many redirects \(more than 10\)/, 'says so';
};

subtest '_permitted_redirect: host (www. aside), scheme, port, no credentials' => sub {
  my $ok = \&Langertha::Raider::WebTools::_permitted_redirect;
  ok $ok->( 'https://example.com/a', 'https://example.com/b' ), 'same host';
  ok $ok->( 'https://example.com/a', 'https://www.example.com/b' ), 'www. added';
  ok $ok->( 'https://www.example.com/a', 'https://example.com/b' ), 'www. dropped';
  ok !$ok->( 'https://example.com/a', 'https://docs.example.com/b' ), 'a subdomain is another host';
  ok !$ok->( 'http://example.com/a', 'https://example.com/b' ), 'another scheme';
  ok !$ok->( 'https://example.com/a', 'https://example.com:8443/b' ), 'another port';
  ok !$ok->( 'https://example.com/a', 'https://user:pw@example.com/b' ), 'credentials';
};

subtest 'a response that is not a success: Claude Code\'s text, no error result' => sub {
  my $r = $fetch->( url => "$base/gone", prompt => 'What?' );
  ok !$r->{isError}, 'not an error, as in Claude Code';
  is text_of($r), "The server returned HTTP 404 Not Found.\n\nThe response body was not retrieved. If this URL requires "
    ."authentication, use an authenticated tool (e.g. `gh` for GitHub, or an MCP-provided fetch tool) instead of web_fetch.",
    'the text';
  like text_of( $fetch->( url => "$base/deny" ) ), qr/\AThe server returned HTTP 403 Forbidden\.\n\n/, '403 too';
};

subtest 'the application: the run\'s engine answers, its tokens are model.usage' => sub {
  my $root = Path::Tiny->tempdir;
  my @events;
  my $app = Langertha::Raider::Application->new( root => "$root", engine => 'openai', api_key => 'test',
    model => 'gpt-4o', on_event => sub { my ( $t, %p ) = @_; push @events, { type => $t, %p } } );
  ref_is $app->web_fetch_engine, $app->_engine, 'without web_fetch_model: the run\'s engine';

  my $small = Langertha::Raider::Application->new( root => "$root", engine => 'openai', api_key => 'test',
    model => 'gpt-4o', engine_options => { web_fetch_model => 'gpt-4o-mini' } );
  ref_is_not $small->web_fetch_engine, $small->_engine, 'with web_fetch_model: an engine of its own';
  is $small->web_fetch_engine->chat_model, 'gpt-4o-mini', 'with that model';
  is ref $small->web_fetch_engine, ref $small->_engine, 'of the same engine class';
  is $small->_engine->chat_model, 'gpt-4o', 'the run keeps its model';

  SKIP: {
    skip 'needs Langertha::Engine::Virtual', 3 unless eval { require Langertha::Engine::Virtual; require Langertha::Virtual::Rules; 1 };
    my $virtual = Langertha::Engine::Virtual->new( langfuse_enabled => 0, script => [
      Langertha::Virtual::Rules::answer( 'It says 42.', usage => { prompt_tokens => 50, completion_tokens => 4 } ),
    ] );
    my $mocked = Langertha::Raider::Application->new( root => "$root", engine => 'openai', api_key => 'test',
      on_event => sub { my ( $t, %p ) = @_; push @events, { type => $t, %p } } );
    $mocked->meta->get_attribute('web_fetch_engine')->set_value( $mocked, $virtual );
    my $f = $mocked->_web_fetch_answer_f("Web page content:\n---\n42\n---\n\nWhat?");
    is $loop->await($f)->get, 'It says 42.', 'the answer text';
    like [ grep { $_->{type} eq 'model.usage' } @events ],
      [ { purpose => 'web_fetch', model => T(), input_tokens => 50, output_tokens => 4 } ], 'model.usage';
    is $virtual->requests->[0]{body}{messages}, [ { role => 'user', content => "Web page content:\n---\n42\n---\n\nWhat?" } ],
      'one user message, no tools, no system prompt';
  }
};

done_testing;
