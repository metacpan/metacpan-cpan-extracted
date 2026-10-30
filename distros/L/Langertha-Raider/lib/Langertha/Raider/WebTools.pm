package Langertha::Raider::WebTools;
our $VERSION = '0.504';
# ABSTRACT: MCP::Server factory with web search and fetch tools (Net::Async::WebSearch + Net::Async::HTTP)

use strict;
use warnings;
use Future;
use Future::AsyncAwait;
use HTTP::Request::Common qw( GET );
use MCP::Server;
use Net::Async::HTTP;
use Net::Async::WebSearch;
use Net::Async::WebSearch::Provider::DuckDuckGo;
use Net::Async::WebSearch::Provider::Brave;
use Net::Async::WebSearch::Provider::Serper;
use Net::Async::WebSearch::Provider::Google;
use HTML::TreeBuilder;
use URI;
use Langertha::Raider::ConnectCheck qw( connect_error );

use Exporter 'import';
our @EXPORT_OK = qw( build_web_tools_server );


# Redirects web_fetch follows on the same host, as Claude Code.
sub _max_redirects { 10 }

sub _flatten_html {
  my ($html) = @_;
  my $t = HTML::TreeBuilder->new_from_content($html);
  $_->delete for $t->look_down(_tag => qr/^(?:script|style|noscript)$/);
  my $text = $t->as_text;
  $t->delete;
  $text =~ s/[ \t]+/ /g;
  $text =~ s/\n{3,}/\n\n/g;
  return $text;
}

# A domain of allowed_domains / blocked_domains as a bare lower-case host:
# a scheme, path, port and a leading "*." or "." are dropped.
sub _domain {
  my ($entry) = @_;
  return unless defined $entry && !ref $entry;
  my $d = lc $entry;
  $d =~ s{\A\s+|\s+\z}{}g;
  $d =~ s{\A[a-z][a-z0-9+.-]*://}{};
  $d =~ s{[/?#].*\z}{}s;
  $d =~ s{:\d+\z}{};
  $d =~ s{\A\*?\.}{};
  return length $d ? $d : ();
}

sub _domains {
  my ($list) = @_;
  return [ map { _domain($_) } ref $list eq 'ARRAY' ? @$list : () ];
}

# True when the host of $url is one of @$domains or below one.
sub _on_domain {
  my ( $url, $domains ) = @_;
  my $uri = URI->new($url // '');
  my $host = $uri->can('host') ? lc( $uri->host // '' ) : '';
  return 0 unless length $host;
  for my $d (@$domains) {
    return 1 if $host eq $d || substr( $host, -( length($d) + 1 ) ) eq '.'.$d;
  }
  return 0;
}

# Claude Code follows a redirect itself only on the same host (with or
# without www.), scheme and port, and without credentials in the URL.
sub _permitted_redirect {
  my ( $from, $to ) = @_;
  my ( $old, $new ) = map { URI->new($_) } $from, $to;
  return 0 unless $old->can('host') && $new->can('host');
  return 0 unless lc( $old->scheme // '' ) eq lc( $new->scheme // '' ) && ( $old->port // 0 ) == ( $new->port // 0 );
  return 0 if defined $new->userinfo;
  my ( $ho, $hn ) = map { my $h = lc( $_->host // '' ); $h =~ s/\Awww\.//; $h } $old, $new;
  return length $ho && $ho eq $hn ? 1 : 0;
}

# Claude Code's text for a redirect it does not follow, with raider's tool
# name.
sub _redirect_text {
  my ( $url, $location, $status, $prompt ) = @_;
  return "REDIRECT DETECTED: The URL redirects to a location that was not fetched automatically.\n\n"
    ."    Original URL: ".$url."\n"
    ."    Redirect URL (from the server's Location header \x{2014} server-supplied, not verified): ".$location."\n"
    ."    Status: ".$status."\n\n"
    ."    To complete your request, I need to fetch content from the redirected URL. Please use web_fetch again with these parameters:\n"
    .'    - url: "'.$location.'"'
    .( defined $prompt && length $prompt ? "\n".'    - prompt: "'.$prompt.'"' : '' );
}

# Claude Code's text for a response that is not a success (not an error
# result there either).
sub _http_status_text {
  my ($status) = @_;
  return 'The server returned HTTP '.$status.".\n\n"
    .'The response body was not retrieved. If this URL requires authentication, use an authenticated '
    .'tool (e.g. `gh` for GitHub, or an MCP-provided fetch tool) instead of web_fetch.';
}

# What the answer call of web_fetch's prompt gets: the page between ---,
# then the prompt.
sub _prompt_text {
  my ( $content, $prompt, $max ) = @_;
  if ( length $content > $max ) {
    $content = substr( $content, 0, $max )."\n\n[Content truncated: the page is longer than ".$max.' characters.]';
  }
  return "Web page content:\n---\n".$content."\n---\n\n".$prompt."\n\n"
    .'Answer from the content above only, and concisely. Quote only short passages, word for word. '
    .'If the content does not say, answer that it does not.';
}

sub build_web_tools_server {
  my %args = @_;
  my $loop             = $args{loop} or die "loop is required\n";
  my $max_fetch_bytes  = $args{max_fetch_bytes}  // 2_000_000;
  my $fetch_timeout    = $args{fetch_timeout}    // 60;
  my $stall_timeout    = $args{stall_timeout}    // 20;
  my $answer           = $args{answer};
  my $max_prompt_chars = $args{max_prompt_chars} // 100_000;

  my $http = $args{http} // Net::Async::HTTP->new(
    user_agent    => 'raider/'.$VERSION,
    max_in_flight => 4,
    # Defaults of every request the search providers make (k148); web_fetch
    # passes its own per request.
    timeout       => $fetch_timeout,
    stall_timeout => $stall_timeout,
  );
  $loop->add($http);

  my $ws = $args{web_search} // Net::Async::WebSearch->new(http => $http);
  $loop->add($ws);

  $ws->add_provider(Net::Async::WebSearch::Provider::DuckDuckGo->new)
    unless $args{web_search};

  if (!$args{web_search} && $ENV{BRAVE_API_KEY}) {
    $ws->add_provider(Net::Async::WebSearch::Provider::Brave->new(
      api_key => $ENV{BRAVE_API_KEY},
    ));
  }
  if (!$args{web_search} && $ENV{SERPER_API_KEY}) {
    $ws->add_provider(Net::Async::WebSearch::Provider::Serper->new(
      api_key => $ENV{SERPER_API_KEY},
    ));
  }
  if (!$args{web_search} && $ENV{GOOGLE_API_KEY} && $ENV{GOOGLE_CSE_ID}) {
    $ws->add_provider(Net::Async::WebSearch::Provider::Google->new(
      api_key => $ENV{GOOGLE_API_KEY},
      cx      => $ENV{GOOGLE_CSE_ID},
    ));
  }

  my $server = MCP::Server->new(name => 'raider-web', version => '1.0');

  $server->tool(
    name         => 'web_search',
    description  => 'Search the web across multiple providers (DuckDuckGo always; Brave/Serper/Google added when their API keys are in the environment). Returns ranked merged results. allowed_domains keeps only results on those domains, blocked_domains drops them (not both at once).',
    input_schema => {
      type       => 'object',
      properties => {
        query => { type => 'string',  description => 'Search query' },
        limit => { type => 'integer', description => 'Max results (default 8)' },
        allowed_domains => { type => 'array', items => { type => 'string' },
          description => 'Only include results from these domains (and their subdomains)' },
        blocked_domains => { type => 'array', items => { type => 'string' },
          description => 'Never include results from these domains (and their subdomains)' },
      },
      required => ['query'],
    },
    code => sub {
      my ($tool, $in) = @_;
      my $query = $in->{query};
      my $limit = $in->{limit} // 8;
      my ( $allowed, $blocked ) = map { _domains($in->{$_}) } qw( allowed_domains blocked_domains );
      return $tool->text_result('<tool_use_error>Error: Cannot specify both allowed_domains and blocked_domains '
        .'in the same request</tool_use_error>', 1)
        if @$allowed && @$blocked;
      my $filter = @$allowed || @$blocked;
      # The filter on the results is what holds; the operators only help the
      # providers bring results that survive it.
      $query .= ' site:'.$allowed->[0] if @$allowed == 1;
      $query .= join '', map { ' -site:'.$_ } @$blocked;
      # Every search provider is https (see connect_error for why a failed
      # load must not reach Net::Async::HTTP).
      if (my $error = connect_error('https:')) {
        return $tool->text_result("Error: $error", 1);
      }
      # The whole search ends within fetch_timeout, whatever http the
      # providers use: a provider that never answers is a tool error.
      my $f = $ws->search(query => $query, limit => $filter ? ( $limit * 3 > 50 ? 50 : $limit * 3 ) : $limit);
      my $out = eval {
        my $race = Future->wait_any(
          $f,
          $loop->delay_future( after => $fetch_timeout )
            ->then_fail('web_search timed out after '.$fetch_timeout."s\n"),
        );
        $loop->await($race);
        $race->get;
      };
      return $tool->text_result("Error: $@", 1) if $@;
      my @results = @{$out->{results} // []};
      @results = grep { _on_domain( $_->url, $allowed ) } @results if @$allowed;
      @results = grep { !_on_domain( $_->url, $blocked ) } @results if @$blocked;
      splice @results, $limit if @results > $limit;
      my @lines;
      my $i = 0;
      for my $r (@results) {
        $i++;
        my $title = $r->title // '(no title)';
        my $url   = $r->url   // '';
        my $sn    = $r->snippet // '';
        $sn =~ s/\s+/ /g;
        push @lines, "[$i] $title";
        push @lines, "    $url";
        push @lines, "    $sn" if length $sn;
      }
      if (my $errs = $out->{errors}) {
        for my $e (@$errs) {
          push @lines, "(error from $e->{provider}: $e->{error})";
        }
      }
      return $tool->text_result(@lines ? join("\n", @lines) : "No results.");
    },
  );

  # One request of web_fetch, without following a redirect: ( $response )
  # or ( undef, $error ). The body is read through on_header and cut off at
  # max_fetch_bytes: the request is cancelled instead of buffering the whole
  # download. The abort runs on the loop's next tick, closing the connection
  # from inside the read handler is not safe (as Langertha's body cap).
  my $get = sub {
    my ($url) = @_;
    my $req = GET($url);
    $req->header('User-Agent' => 'raider/'.$VERSION);
    my ( $too_big, $seen );
    my $abort = Future->new;
    my $trip = sub {
      return if $too_big++;
      $loop->later( sub { $abort->done unless $abort->is_ready } );
    };
    my $f = $http->do_request(
      request       => $req,
      timeout       => $fetch_timeout,
      stall_timeout => $stall_timeout,
      max_redirects => 0,
      on_header     => sub {
        my ($header) = @_;
        $seen = $header;
        return sub {
          return $header unless @_;
          return if $too_big;
          $header->add_content( $_[0] ) if defined $_[0];
          $trip->() if $header->is_success
            && length( ${ $header->content_ref } ) > $max_fetch_bytes;
          return;
        };
      },
    );
    my $resp = eval {
      my $race = Future->wait_any( $f, $abort );
      $loop->await($race);
      $race->get;
    };
    my $err = $@;
    return ( $seen ) if $too_big && $seen;
    return ( undef, $err ) if $err;
    return ( $resp );
  };

  $server->tool(
    name         => 'web_fetch',
    description  => 'Fetch a URL. With prompt, the page is read by a model and the tool returns its answer to the prompt; without, it returns the body (HTML flattened to readable text, large bodies truncated). A redirect to another host is not followed: the result says where it points.',
    input_schema => {
      type       => 'object',
      properties => {
        url     => { type => 'string',  description => 'URL to fetch' },
        prompt  => { type => 'string',  description => 'What to find out from the page; the tool answers it from the page content' },
        as_html => { type => 'boolean', description => 'Keep raw HTML instead of flattening to text (default false)' },
      },
      required => ['url'],
    },
    code => sub {
      my ($tool, $in) = @_;
      my $url = $in->{url};
      my $prompt = defined $in->{prompt} && !ref $in->{prompt} && $in->{prompt} =~ /\S/ ? $in->{prompt} : undef;
      my ( $at, $resp ) = ( $url );
      for my $hop ( 0 .. _max_redirects() ) {
        # A module Net::Async::HTTP fails to load while connecting leaves the
        # host's connection slot taken: every later fetch from it would hang
        # (karr k107). The same holds for every redirect followed.
        if (my $error = connect_error($at)) {
          return $tool->text_result("Error: $error", 1);
        }
        my $err;
        ( $resp, $err ) = $get->($at);
        return $tool->text_result("Error: $err", 1) if defined $err && length $err;
        my $location = $resp->is_redirect ? $resp->header('Location') : undef;
        last unless defined $location && length $location;
        my $next = URI->new_abs( $location, $at )->as_string;
        return $tool->text_result( _redirect_text( $url, $next, $resp->status_line, $prompt ) )
          unless _permitted_redirect( $at, $next );
        return $tool->text_result('Error: too many redirects (more than '._max_redirects().')', 1)
          if $hop == _max_redirects();
        $at = $next;
      }
      return $tool->text_result( _http_status_text( $resp->status_line ) ) unless $resp->is_success;
      my $body = eval { $resp->decoded_content } // $resp->content // '';
      if (length($body) > $max_fetch_bytes) {
        $body = substr($body, 0, $max_fetch_bytes) . "\n[truncated]\n";
      }
      my $ctype = $resp->header('Content-Type') // '';
      if (!$in->{as_html} && $ctype =~ m{text/html}i) {
        $body = _flatten_html($body);
      }
      if ( defined $prompt && $answer ) {
        my $f = $answer->( _prompt_text( $body, $prompt, $max_prompt_chars ) );
        my $text = eval { $loop->await($f); $f->get };
        my $error = $@;
        return $tool->text_result('Error: the model call for the prompt failed: '.$error, 1) unless defined $text;
        return $tool->text_result($text);
      }
      my $header = sprintf("URL: %s\nStatus: %s\nContent-Type: %s\n\n",
        $at, $resp->status_line, $ctype);
      return $tool->text_result($header . $body);
    },
  );

  return $server;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::WebTools - MCP::Server factory with web search and fetch tools (Net::Async::WebSearch + Net::Async::HTTP)

=head1 VERSION

version 0.504

=head1 DESCRIPTION

The web tools of L<raider>: an L<MCP::Server> with C<web_search> and
C<web_fetch>, run on the caller's L<IO::Async::Loop>. They answer the way
Claude Code's WebSearch and WebFetch do where raider has the same feature
(ADR 0026).

=head2 build_web_tools_server

    my $server = Langertha::Raider::WebTools::build_web_tools_server(
        loop             => $loop,         # required
        max_fetch_bytes  => 2_000_000,
        fetch_timeout    => 60,            # whole web_fetch request or web_search, seconds
        stall_timeout    => 20,            # seconds without data
        answer           => sub { my ( $text ) = @_; ...; return $future_of_text },
        max_prompt_chars => 100_000,       # page text the answer call gets
    );

Returns an L<MCP::Server> instance with two tools:

=over

=item * C<web_search(query, [limit], [allowed_domains], [blocked_domains])>
-- multi-provider search via L<Net::Async::WebSearch>. DuckDuckGo is always
enabled (keyless). Brave, Serper and Google are auto-added when
C<BRAVE_API_KEY>, C<SERPER_API_KEY>, or both C<GOOGLE_API_KEY> +
C<GOOGLE_CSE_ID> are set in the environment. The whole search ends within
C<fetch_timeout> (default 60 s) -- a provider that never answers is a tool
error -- and the requests of the default HTTP client stop at
C<fetch_timeout> and after C<stall_timeout> (default 20 s) without data, as
for C<web_fetch>.

C<allowed_domains> keeps only results on these domains, C<blocked_domains>
drops results on them; a domain covers its subdomains (C<example.com>
covers C<docs.example.com>), and an entry may be written as a URL. The
filter is applied to the results -- that is the guarantee -- and goes into
the query too (C<site:> for a single allowed domain, C<-site:> for each
blocked one), and three times C<limit> results (at most 50) are asked for,
so filtering still leaves results. Both at once is an error, as in Claude
Code.

=item * C<web_fetch(url, [prompt], [as_html])> -- fetch a URL via
L<Net::Async::HTTP>. Without C<prompt> it returns the URL, the status, the
content type and the body, cut at C<max_fetch_bytes> (default 2_000_000);
HTML is flattened to readable text unless C<as_html> is true. With
C<prompt> and an C<answer> callback the page text (at most
C<max_prompt_chars>, default 100_000 characters) and the prompt go to
C<answer>, and the tool returns what it answers -- Claude Code's WebFetch,
which puts the prompt to a small model. Without C<answer> the prompt is
ignored and the page returned. The body is read in chunks and the request
is cancelled once C<max_fetch_bytes> is exceeded; a request that exceeds
C<fetch_timeout> (default 60 s) or stalls for C<stall_timeout> (default
20 s) without data is a tool error.

A redirect is followed (up to 10) only when it stays on the same host
(C<www.> aside), scheme and port; one to another host is not fetched: the
tool says where it points and how to fetch it (Claude Code's
C<REDIRECT DETECTED> text), so the permission rules (C<WebFetch(domain:...)>)
see the new host when the model asks for it. A response that is not a
success is Claude Code's C<The server returned HTTP ...> text -- like
Claude Code, not an error result.

C<limit> of C<web_search> defaults to 8.

=back

C<answer> gets the whole text for the model call (the page between
C<--->, then the prompt) and returns a L<Future> of the answer text; the
application runs it on the run's engine (L<Langertha::Raider::Application>).

Both tools return a tool error, and send nothing, when a module
L<Net::Async::HTTP> needs to connect does not load
(L<IO::Async::Internals::Connector>; for https L<IO::Async::SSL>, which
needs L<IO::Socket::SSL>, L<Net::SSLeay> and the system libssl). The error
names the module. For C<web_fetch> that holds for every redirect it follows
as well: an http URL that redirects to https on the same host is the same
tool error.

=head1 ENVIRONMENT

=head2 BRAVE_API_KEY

Adds Brave to C<web_search>.

=head2 SERPER_API_KEY

Adds Serper to C<web_search>.

=head2 GOOGLE_API_KEY

With L</GOOGLE_CSE_ID>, adds Google Custom Search to C<web_search>.

=head2 GOOGLE_CSE_ID

The Custom Search engine id for L</GOOGLE_API_KEY>.

=head1 SEE ALSO

=over

=item * L<MCP::Server>

=item * L<Net::Async::WebSearch>

=item * L<Net::Async::HTTP>

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/langertha-raider/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

L<https://raudssus.de/>

=cut
