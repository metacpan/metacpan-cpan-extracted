package LinkEmbedder;
use Mojo::Base -base;

use LinkEmbedder::Link;
use Mojo::JSON;
use Mojo::Loader 'load_class';
use Mojo::Promise;
use Mojo::UserAgent;

use constant TLS => eval { require IO::Socket::SSL; IO::Socket::SSL->VERSION('2.009'); 1 };

use constant DEBUG => $ENV{LINK_EMBEDDER_DEBUG} || 0;

our $VERSION = '1.15';

my $PROTOCOL_RE = qr!^(\w+):\w+!i;    # Examples: mail:, spotify:, ...

has force_secure => sub { $ENV{LINK_EMBEDDER_FORCE_SECURE} || 0 };

has ua => sub { Mojo::UserAgent->new->max_redirects(3); };

has url_to_link => sub {
  return {
    'default'            => 'LinkEmbedder::Link::Basic',
    'dropbox.com'        => 'LinkEmbedder::Link::Dropbox',
    'git.io'             => 'LinkEmbedder::Link::Github',
    'github.com'         => 'LinkEmbedder::Link::Github',
    'google'             => 'LinkEmbedder::Link::Google',
    'goo.gl'             => 'LinkEmbedder::Link::Google',
    'imgur.com'          => 'LinkEmbedder::Link::Imgur',
    'instagram.com'      => 'LinkEmbedder::Link::Instagram',
    'ix.io'              => 'LinkEmbedder::Link::Ix',
    'meet.jit.si'        => 'LinkEmbedder::Link::Jitsi',
    'metacpan.org'       => 'LinkEmbedder::Link::Metacpan',
    'nhl.com'            => 'LinkEmbedder::Link::NHL',
    'paste.opensuse.org' => 'LinkEmbedder::Link::OpenSUSE',
    'paste.scsys.co.uk'  => 'LinkEmbedder::Link::Shadowcat',
    'pastebin.com'       => 'LinkEmbedder::Link::Pastebin',
    'spotify'            => 'LinkEmbedder::Link::Spotify',
    'ted.com'            => 'LinkEmbedder::Link::oEmbed',
    'travis-ci.org'      => 'LinkEmbedder::Link::Travis',
    'twitter.com'        => 'LinkEmbedder::Link::Twitter',
    'vimeo.com'          => 'LinkEmbedder::Link::oEmbed',
    'xkcd.com'           => 'LinkEmbedder::Link::Xkcd',
    'whereby.com'        => 'LinkEmbedder::Link::AppearIn',
    'youtube.com'        => 'LinkEmbedder::Link::oEmbed',
  };
};

sub get {
  my ($self, $args, $cb) = @_;

  $self->get_p($args)->then(sub {
    $self->$cb(shift);
  })->catch(sub {
    my $err = pop // 'Unknown error.';
    $err = {message => "$err", code => 500} unless ref $err eq 'HASH';
    $self->$cb(LinkEmbedder::Link->new(error => $err, force_secure => $self->force_secure));
  });

  return $self;
}

sub get_p {
  my ($self, $args) = @_;
  my ($e, $link);

  $args                 = ref $args eq 'HASH' ? {%$args} : {url => $args};
  $args->{force_secure} = $self->force_secure;
  $args->{url}          = Mojo::URL->new($args->{url} || '') unless ref $args->{url};
  $args->{ua}           = $self->ua;

  $link ||= delete $args->{class};
  $link ||= ucfirst $1 if $args->{url} =~ $PROTOCOL_RE;
  return $self->_invalid_input($args, 'Invalid URL') unless $link or $args->{url}->host;

  $link ||= _host_in_hash($args->{url}->host, $self->url_to_link);
  $link = $link =~ /::/ ? $link : "LinkEmbedder::Link::$link";
  return $self->_invalid_input($args, "Could not find $link") unless _load($link);

  warn "[$link] url=$args->{url})\n" if DEBUG;
  $link = $link->new($args);
  return $link->learn_p->then(sub { return $link });
}

sub serve {
  my ($self, $c, $args) = @_;
  my $format = $c->stash('format') || $c->param('format') || 'json';
  my $log_level;

  $args ||= {url => $c->param('url')};
  $log_level = delete $args->{log_level} || 'debug';

  # Some websites will not render complete pages without a proper User-Agent
  my $user_agent = $c->req->headers->user_agent;
  $self->ua->transactor->name($user_agent) if $user_agent;

  $c->render_later;
  $self->get_p($args)->then(sub {
    my $link = shift;
    my $err  = $link->error;

    $c->stash(status => $err->{code} || 500) if $err;
    return $c->render(data => $link->html)   if $format eq 'html';

    my $json = $err ? {err => $err->{code} || 500} : $link->TO_JSON;
    return $c->render(json => $json) unless $format eq 'jsonp';

    my $name = $c->param('callback') || 'oembed';
    return $c->render(data => sprintf '%s(%s)', $name, Mojo::JSON::to_json($json));
  })->catch(sub { $c->reply->exception(shift) });

  return $self;
}

# This should probably be in a different test-module, but keeping it here for now
sub test_ok {
  my ($self, $url, $expect) = @_;

  my $subtest = sub {
    my $link = shift;
    my $json = $link->TO_JSON;
    Test::More::isa_ok($link, $expect->{isa}) if $expect->{isa};

    for my $key (sort keys %$expect) {
      next if $key eq 'isa';
      for my $exp (ref $expect->{$key} eq 'ARRAY' ? @{$expect->{$key}} : ($expect->{$key})) {
        my $test_name = ref $exp eq 'Regexp' ? 'like' : 'is';
        Test::More->can($test_name)->($json->{$key}, $exp, $key);
      }
    }
  };

  my $ok;
  $self->get_p($url)->then(
    sub {
      my $link = shift;
      $ok = Test::More::subtest($link->url, sub { $subtest->($link) });
      Test::More::diag(Test::More::explain($link->TO_JSON)) unless $ok;
    },
    sub { Test::More::diag(shift) }
  )->wait;

  return $ok;
}

sub _host_in_hash {
  my ($host, $hash) = @_;
  return $hash->{$host} if $hash->{$host};

  $host = $1 if $host =~ m!([^\.]+\.\w+)$!;
  return $hash->{$host} if $hash->{$host};

  $host = $1 if $host =~ m!([^\.]+)\.\w+$!;
  return $hash->{$host} || $hash->{default};
}

sub _invalid_input {
  my ($self, $args, $msg) = @_;
  $args->{error} = {message => $msg, code => 400};
  return Mojo::Promise->new->resolve(LinkEmbedder::Link->new($args));
}

sub _load {
  $@ = load_class $_[0];
  warn "[LinkEmbedder] load $_[0]: @{[$@ || 'Success']}\n" if DEBUG;
  die $@                                                   if ref $@;
  return $@ ? 0 : 1;
}

1;

=encoding utf8

=head1 NAME

LinkEmbedder - Embed / expand oEmbed resources and other URL / links

=head1 SYNOPSIS

  use LinkEmbedder;

  my $embedder = LinkEmbedder->new(force_secure => 1);

  # In some cases, you have to set a proper user_agent to get complete
  # pages. This is done automatically by $embedder->serve()
  $embedder->ua->transactor->name("Mozilla...");

  $embedder->get_p("https://xkcd.com/927")->then(sub {
    my $link = shift;
    print $link->html;
  })->wait;

=head1 DESCRIPTION

L<LinkEmbedder> is a module that can expand an URL into a rich HTML snippet or
simply to extract information about the URL.

This module replaces L<Mojolicious::Plugin::LinkEmbedder>.

Go to L<https://thorsen.pm/linkembedder> to see a demo of how it works.

These web pages are currently supported:

=over 2

=item * L<https://dropbox.com/>

=item * L<https://imgur.com/>

=item * L<https://instagram.com/>

Instagram need some additional JavaScript. Please look at
L<https://github.com/jhthorsen/linkembedder/blob/master/examples/embedder.pl> and
L<https://www.instagram.com/developer/embedding/>
for more information.

=item * L<https://appear.in/>

=item * L<https://gist.github.com>

=item * L<https://github.com>

=item * L<http://ix.io>

=item * L<https://maps.google.com>

=item * L<https://metacpan.org>

=item * L<https://paste.fedoraproject.org/>

=item * L<https://paste.opensuse.org>

=item * L<http://paste.scsys.co.uk>

=item * L<https://pastebin.com>

=item * L<https://www.spotify.com/>

=item * L<https://ted.com>

=item * L<https://travis-ci.org>

=item * L<https://twitter.com>

Twitter need some additional JavaScript. Please look at
L<https://github.com/jhthorsen/linkembedder/blob/master/examples/embedder.pl> and
L<https://dev.twitter.com/web/javascript/initialization>
for more information.

=item * L<https://vimeo.com>

=item * L<https://youtube.com>

=item * L<https://www.xkcd.com/>

=item * HTML

Any web page will be parsed, and "og:", "twitter:", meta tags and other
significant elements will be used to generate a oEmbed response.

=item * Images

URLs that looks like an image is automatically converted into an img tag.

=item * Video

URLs that looks like a video resource is automatically converted into a video tag.

=back

=head1 ATTRIBUTES

=head2 force_secure

  $bool = $self->force_secure;
  $self = $self->force_secure(1);

This attribute will translate any unknown http link to https.

This attribute is EXPERIMENTAL. Feeback appreciated.

=head2 ua

  $ua = $self->ua;

Holds a L<Mojo::UserAgent> object.

=head2 url_to_link

  $hash_ref = $self->url_to_link;

Holds a mapping between host names and L<link class|LinkEmbedder::Link> to use.

=head1 METHODS

=head2 get

  $self = $self->get_p($url, sub { my ($self, $link) = @_ });

Same as L</get_p>, but takes a callback instead of returning a L<Mojo::Promise>.

=head2 get_p

  $promise = $self->get_p($url)->then(sub { my $link = shift });

Used to construct a new L<LinkEmbedder::Link> object and retrieve information
about the URL.

=head2 serve

  $self = $self->serve(Mojolicious::Controller->new, $url);

Used as a helper for L<Mojolicious> web applications to reply to an oEmbed
request. Will also set L<Mojo::UserAgent::Transactor/name> for L</ua> if
the incoming request contains a "User-Agent" header.

=head1 AUTHOR

Jan Henning Thorsen

=head1 COPYRIGHT AND LICENSE

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
