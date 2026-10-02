use strict;
use warnings;
use Test::More;
use Future;

use Langertha::Raider::WebTools qw( build_web_tools_server );

{
  package TestLoop;
  sub new { bless { awaited => 0 }, shift }
  sub add { }
  sub await {
    my ($self, $f) = @_;
    $self->{awaited}++;
    return $f->get;
  }
}

{
  package TestResult;
  sub new { bless {}, shift }
  sub title { 'Example' }
  sub url { 'https://example.test/' }
  sub snippet { 'Snippet text' }
}

{
  package TestSearch;
  sub new { bless {}, shift }
  sub add_provider { }
  sub search {
    return Future->done({ results => [TestResult->new] });
  }
}

{
  package TestHTTP;
  sub new { bless {}, shift }
  sub do_request {
    return Future->done(TestHTTPResponse->new);
  }
}

{
  package TestHTTPResponse;
  sub new { bless {}, shift }
  sub is_success { 1 }
  sub status_line { '200 OK' }
  sub decoded_content { '<html><body><p>Hello</p><script>bad()</script></body></html>' }
  sub header { 'text/html' }
}

my $loop = TestLoop->new;
my $server = build_web_tools_server(
  loop => $loop,
  web_search => TestSearch->new,
  http => TestHTTP->new,
);

sub call_tool {
  my ($name, $args) = @_;
  my ($tool) = grep { $_->name eq $name } @{ $server->tools };
  die "no tool $name" unless $tool;
  return $tool->code->($tool, $args);
}

subtest 'web_search waits on loop future' => sub {
  my $res = call_tool('web_search', { query => 'example' });
  like($res->{content}[0]{text}, qr/Example/, 'search result returned');
  is($loop->{awaited}, 1, 'loop awaited search future');
};

subtest 'web_fetch waits on loop future' => sub {
  my $res = call_tool('web_fetch', { url => 'https://example.test/' });
  like($res->{content}[0]{text}, qr/Hello/, 'fetch body returned');
  unlike($res->{content}[0]{text}, qr/bad/, 'html flattened');
  is($loop->{awaited}, 2, 'loop awaited fetch future');
};

done_testing;
