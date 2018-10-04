package LinkEmbedder;
use Mojo::Base -base;

use LinkEmbedder::Link;
use Mojo::JSON;
use Mojo::Loader 'load_class';
use Mojo::Promise;
use Mojo::UserAgent;

use constant DEBUG => $ENV{LINK_EMBEDDER_DEBUG} || 0;

our $VERSION = '1.01';

my $PROTOCOL_RE = qr!^(\w+):\w+!i;    # Examples: mail:, spotify:, ...

has ua => sub { Mojo::UserAgent->new->max_redirects(3); };

has url_to_link => sub {
  return {
    'default'                 => 'LinkEmbedder::Link::Basic',
    'appear.in'               => 'LinkEmbedder::Link::AppearIn',
    'git.io'                  => 'LinkEmbedder::Link::Github',
    'github.com'              => 'LinkEmbedder::Link::Github',
    'google'                  => 'LinkEmbedder::Link::Google',
    'imgur.com'               => 'LinkEmbedder::Link::Imgur',
    'ix.io'                   => 'LinkEmbedder::Link::Ix',
    'instagram.com'           => 'LinkEmbedder::Link::oEmbed',
    'metacpan.org'            => 'LinkEmbedder::Link::Metacpan',
    'paste.fedoraproject.org' => 'LinkEmbedder::Link::Fpaste',
    'paste.opensuse.org'      => 'LinkEmbedder::Link::OpenSUSE',
    'paste.scsys.co.uk'       => 'LinkEmbedder::Link::Shadowcat',
    'pastebin.com'            => 'LinkEmbedder::Link::Pastebin',
    'spotify'                 => 'LinkEmbedder::Link::Spotify',
    'ted.com'                 => 'LinkEmbedder::Link::oEmbed',
    'travis-ci.org'           => 'LinkEmbedder::Link::Travis',
    'twitter.com'             => 'LinkEmbedder::Link::Twitter',
    'vimeo.com'               => 'LinkEmbedder::Link::oEmbed',
    'xkcd.com'                => 'LinkEmbedder::Link::Xkcd',
    'youtube.com'             => 'LinkEmbedder::Link::oEmbed',
  };
};

sub get_p {
  my ($self, $args) = @_;
  my ($e, $link);

  $args = ref $args eq 'HASH' ? {%$args} : {url => $args};
  $args->{url} = Mojo::URL->new($args->{url} || '') unless ref $args->{url};
  $args->{ua} = $self->ua;

  $link ||= delete $args->{class};
  $link ||= ucfirst $1 if $args->{url} =~ $PROTOCOL_RE;
  return $self->_invalid_input($args, 'Invalid URL') unless $link or $args->{url}->host;

  $link ||= _host_in_hash($args->{url}->host, $self->url_to_link);
  $link = $link =~ /::/ ? $link : "LinkEmbedder::Link::$link";
  return $self->_invalid_input($args, "Could not find $link") unless _load($link);

  warn "[LinkEmbedder] $link->new($args->{url})\n" if DEBUG;
  $link = $link->new($args);
  return $link->learn_p->then(sub { return $link });
}

sub serve {
  my ($self, $c, $args) = @_;
  my $format = $c->stash('format') || $c->param('format') || 'json';
  my $log_level;

  $args ||= {url => $c->param('url')};
  $log_level = delete $args->{log_level} || 'debug';

  $c->render_later;
  $self->get_p($args)->then(sub {
    my $link = shift;
    my $err  = $link->error;

    $c->stash(status => $err->{code} || 500) if $err;
    return $c->render(data => $link->html) if $format eq 'html';

    my $json = $err ? {err => $err->{code} || 500} : $link->TO_JSON;
    $c->render(json => $json) unless $format eq 'jsonp';

    my $name = $c->param('callback') || 'oembed';
    $c->render(data => sprintf '%s(%s)', $name, Mojo::JSON::to_json($json));
  })->catch(sub { $c->reply->exception(shift) });

  return $self;
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
  die $@ if ref $@;
  return $@ ? 0 : 1;
}

1;

=encoding utf8

=head1 NAME

LinkEmbedder - Embed / expand oEmbed resources and other URL / links

=head1 SYNOPSIS

  use LinkEmbedder;

  my $embedder = LinkEmbedder->new;
  $embedder->get_p("http://xkcd.com/927")->then(sub {
    my $link = shift;
    print $link->html;
  })->wait;

=head1 DESCRIPTION

L<LinkEmbedder> is a module that can expand an URL into a rich HTML snippet or
simply to extract information about the URL.

Note that this module is currently EXPERIMENTAL. It will replace
L<Mojolicious::Plugin::LinkEmbedder> when it gets stable.

These web pages are currently supported:

=over 2

=item * L<http://imgur.com/>

Example: L<http://home.thorsen.pm/demo/link-embedder?url=http://imgur.com/gallery/ohL3e>

=item * L<https://instagram.com/>

Example: L<http://home.thorsen.pm/demo/link-embedder?url=https://www.instagram.com/p/BSRYg_Sgbqe/>

Instagram need some additional JavaScript. Please look at
L<https://github.com/jhthorsen/linkembedder/blob/master/examples/embedder.pl> and
L<https://www.instagram.com/developer/embedding/>
for more information.

=item * L<https://appear.in/>

Example: L<http://home.thorsen.pm/demo/link-embedder?url=https://appear.in/link-embedder-demo>

=item * L<https://gist.github.com>

Example: L<http://home.thorsen.pm/demo/link-embedder?url=https://gist.github.com/jhthorsen/3738de6f44f180a29bbb>

=item * L<https://github.com>

Example: L<http://home.thorsen.pm/demo/link-embedder?url=https://github.com/jhthorsen/linkembedder/blob/master/t/basic.t>

=item * L<https://ix.io>

Example: L<http://home.thorsen.pm/demo/link-embedder?url=http://ix.io/fpW>

=item * L<https://maps.google.com>

Example: L<http://home.thorsen.pm/demo/link-embedder?url=https%3A%2F%2Fwww.google.no%2Fmaps%2Fplace%2FOslo%2C%2BNorway%2F%4059.8937806%2C10.645035…m4!1s0x46416e61f267f039%3A0x7e92605fd3231e9a!8m2!3d59.9138688!4d10.7522454>

=item * L<https://metacpan.org>

Example: L<http://home.thorsen.pm/demo/link-embedder?url=https://metacpan.org/pod/Mojolicious>

=item * L<https://paste.fedoraproject.org/>

Example: L<http://home.thorsen.pm/demo/link-embedder?https://paste.fedoraproject.org/paste/9qkGGjN-D3fL2M-bimrwNQ>

=item * L<http://paste.opensuse.org>

Example: L<http://home.thorsen.pm/demo/link-embedder?url=http://paste.opensuse.org/2931429>

=item * L<http://paste.scsys.co.uk>

Example: L<http://home.thorsen.pm/demo/link-embedder?url=http://paste.scsys.co.uk/557716>

=item * L<http://pastebin.com>

Example: L<http://home.thorsen.pm/demo/link-embedder?url=https://pastebin.com/V5gZTzhy>

=item * L<https://www.spotify.com/>

Example: L<http://home.thorsen.pm/demo/link-embedder?url=spotify:track:0aBi2bHHOf3ZmVjt3x00wv>

=item * L<https://ted.com>

Example: L<http://home.thorsen.pm/demo/link-embedder?url=https://www.ted.com/talks/jill_bolte_taylor_s_powerful_stroke_of_insight>

=item * L<https://travis-ci.org>

Example: L<http://home.thorsen.pm/demo/link-embedder?url=https://travis-ci.org/Nordaaker/convos/builds/47421379>

=item * L<https://twitter.com>

Example: L<http://home.thorsen.pm/demo/link-embedder?url=https://twitter.com/jhthorsen/status/786688349536972802>

Twitter need some additional JavaScript. Please look at
L<https://github.com/jhthorsen/linkembedder/blob/master/examples/embedder.pl> and
L<https://dev.twitter.com/web/javascript/initialization>
for more information.

=item * L<https://vimeo.com>

Example: L<http://home.thorsen.pm/demo/link-embedder?url=https://vimeo.com/154038415>

=item * L<https://youtube.com>

Example: L<http://home.thorsen.pm/demo/link-embedder?url=https%3A%2F%2Fwww.youtube.com%2Fwatch%3Fv%3DOspRE1xnLjE>

=item * L<https://www.xkcd.com/>

Example: L<http://home.thorsen.pm/demo/link-embedder?url=http://xkcd.com/927>

=item * HTML

Any web page will be parsed, and "og:", "twitter:", meta tags and other
significant elements will be used to generate a oEmbed response.

Example: L<http://home.thorsen.pm/demo/link-embedder?url=http://www.aftenposten.no/kultur/Kunstig-intelligens-ma-ikke-lenger-trenes-av-mennesker-617794b.html>

=item * Images

URLs that looks like an image is automatically converted into an img tag.

=item * Video

URLs that looks like a video resource is automatically converted into a video tag.

=back

=head1 ATTRIBUTES

=head2 ua

  $ua = $self->ua;

Holds a L<Mojo::UserAgent> object.

=head2 url_to_link

  $hash_ref = $self->url_to_link;

Holds a mapping between host names and L<link class|LinkEmbedder::Link> to use.

=head1 METHODS

=head2 get_p

  $promise = $self->get_p($url)->then(sub { my $link = shift });

Used to construct a new L<LinkEmbedder::Link> object and retrieve information
about the URL.

=head2 serve

  $self = $self->serve(Mojolicious::Controller->new, $url);

Used as a helper for L<Mojolicious> web applications to reply to an oEmbed
request.

=head1 AUTHOR

Jan Henning Thorsen

=head1 COPYRIGHT AND LICENSE

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
