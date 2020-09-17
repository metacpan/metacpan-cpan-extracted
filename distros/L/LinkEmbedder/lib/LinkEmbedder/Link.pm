package LinkEmbedder::Link;
use Mojo::Base -base;

use Mojo::Template;
use Mojo::Util 'trim';

use constant DEBUG => $ENV{LINK_EMBEDDER_DEBUG} || 0;

my %DOM_SEL = (
  ':desc'      => ['meta[property="og:description"]', 'meta[name="twitter:description"]', 'meta[name="description"]'],
  ':image'     => ['meta[property="og:image"]',       'meta[property="og:image:url"]',    'meta[name="twitter:image"]'],
  ':site_name' => ['meta[property="og:site_name"]',   'meta[property="twitter:site"]'],
  ':title' => ['meta[property="og:title"]', 'meta[name="twitter:title"]', 'title'],
);

my @JSON_ATTRS = (
  'author_name',      'author_url',    'cache_age',       'height', 'provider_name', 'provider_url',
  'thumbnail_height', 'thumbnail_url', 'thumbnail_width', 'title',  'type',          'url',
  'version',          'width'
);

has author_name     => undef;
has author_url      => undef;
has cache_age       => 0;
has description     => '';
has error           => undef;                                                # {message => "", code => ""}
has force_secure    => 0;
has height          => sub { $_[0]->type =~ /^photo|video$/ ? 0 : undef };
has placeholder_url => '';

has provider_name => sub {
  return undef unless my $name = shift->url->host;
  return $name =~ /([^\.]+)\.(\w+)$/ ? ucfirst $1 : $name;
};

has provider_url     => sub { $_[0]->url->host ? $_[0]->url->clone->path('/') : undef };
has template         => sub { [__PACKAGE__, sprintf '%s.html.ep', $_[0]->type] };
has thumbnail_height => undef;
has thumbnail_url    => undef;
has thumbnail_width  => undef;
has title            => undef;
has type             => 'link';
has ua               => undef;                                                             # Mojo::UserAgent object
has url              => sub { Mojo::URL->new };                                            # Mojo::URL
has version          => '1.0';
has width            => sub { $_[0]->type =~ /^photo|video$/ ? 0 : undef };

sub html {
  my $self     = shift;
  my $template = Mojo::Loader::data_section(@{$self->template}) or return '';
  my $output   = Mojo::Template->new({auto_escape => 1, prepend => 'my $l=shift'})->render($template, $self);
  die $output if ref $output;
  return $output;
}

sub learn_p {
  my $self = shift;
  return $self->_get_p($self->url)->then(sub { $self->_learn(shift) });
}

sub TO_JSON {
  my $self = shift;
  my %json;

  for my $attr (grep { defined $self->$_ } @JSON_ATTRS) {
    $json{$attr} = $self->$attr;
    $json{$attr} = "$json{$attr}" if $attr =~ /url$/;
  }

  $json{html} = $self->html unless $self->type eq 'link';

  return \%json;
}

sub _dump { Mojo::Util::dumper($_[0]->TO_JSON); }

sub _el {
  my ($self, $dom, @sel) = @_;
  @sel = @{$DOM_SEL{$sel[0]}} if $DOM_SEL{$sel[0]};

  for my $sel (@sel) {
    my $e = $dom->at($sel) or next;
    my ($val) = grep {$_} map { trim($_ // '') } $e->{content}, $e->{value}, $e->{href}, $e->text, $e->all_text;
    return $val if defined $val;
  }

  return '';
}

sub _get_p {
  my ($self, $url) = @_;
  $url = $url->clone->scheme('https') if $self->force_secure;
  warn sprintf "[%s] GET %s\n", ref($self), $url if DEBUG;
  return $self->ua->get_p($url)->then(sub {
    my $tx = shift;
    $self->url->scheme('https') if $self->force_secure and $tx->res->is_success;
    return $tx;
  });
}

sub _learn {
  my ($self, $tx) = @_;
  my $h = $tx->res->headers;

  my $name = $h->header('X-Provider-Name');
  $self->provider_name($name) if $name;

  my $ct = $h->content_type || '';
  $self->type('photo')->_learn_from_url               if $ct =~ m!^image/!;
  $self->type('video')->_learn_from_url               if $ct =~ m!^video/!;
  $self->type('rich')->_learn_from_text($tx)          if $ct =~ m!^text/plain!;
  $self->type('rich')->_learn_from_dom($tx->res->dom) if $ct =~ m!^text/html!;

  return $self;
}

sub _learn_from_dom {
  my ($self, $dom) = @_;
  my $v;

  $self->author_name($v)      if $v = $self->_el($dom, '[itemprop="author"] [itemprop="name"]');
  $self->author_url($v)       if $v = $self->_el($dom, '[itemprop="author"] [itemprop="email"]');
  $self->description($v)      if $v = $self->_el($dom, ':desc');
  $self->thumbnail_height($v) if $v = $self->_el($dom, 'meta[property="og:image:height"]');
  $self->thumbnail_url($v)    if $v = $self->_el($dom, ':image');
  $self->thumbnail_width($v)  if $v = $self->_el($dom, 'meta[property="og:image:width"]');
  $self->title($v)            if $v = $self->_el($dom, ':title');

  return $self;
}

sub _learn_from_json {
  my ($self, $tx) = @_;
  my $json = $tx->res->json;

  warn "[LinkEmbedder] " . $tx->res->text . "\n" if DEBUG;
  $self->{$_} ||= $json->{$_} for keys %$json;
  $self->{error}       = {message => $self->{error}} if defined $self->{error} and !ref $self->{error};
  $self->{error}{code} = $self->{status}             if $self->{status}        and $self->{status} =~ /^\d+$/;

  return $self;
}

sub _learn_from_text {
  my ($self, $tx) = @_;
  $self->_learn_from_url;

  $self->{paste} = $tx->res->text;
  $self->template->[1] = 'paste.html.ep';

  my $title = substr $self->{paste}, 0, 20;
  $title =~ s![\r\n]+! !g;
  $self->title($title);
}

sub _learn_from_url {
  my $self = shift;
  my $path = $self->url->path;

  return $self->title(@$path ? $path->[-1] : 'Image');
}

1;

=encoding utf8

=head1 NAME

LinkEmbedder::Link - Meta information for an URL

=head1 SYNOPSIS

See L<LinkEmbedder>.

=head1 DESCRIPTION

L<LinkEmbedder::Link> is a class representing an expanded URL.

=head1 ATTRIBUTES

=head2 author_name

  $str = $self->author_name;

Might hold the name of the author of L</url>.

=head2 author_url

  $str = $self->author_name;

Might hold an URL to the author.

=head2 cache_age

  $int = $self->cache_age;

The suggested cache lifetime for this resource, in seconds.

=head2 description

  $str = $self->description;

Description of the L</url>. Might be C<undef()>.

=head2 error

  $hash_ref = $self->author_name;

C<undef()> on success, hash-ref on error. Example:

  {message => "Oops!", code => 500};

=head2 force_secure

  $bool = $self->force_secure;
  $self = $self->force_secure(1);

This attribute will translate any unknown http link to https.

This attribute is EXPERIMENTAL. Feeback appreciated.

=head2 height

  $int = $self->height;

The height of L</html> in pixels. Might be C<undef>.

=head2 provider_name

  $str = $self->provider_name;

Name of the provider of L</url>.

=head2 provider_url

  $str = $self->provider_name;

Main URL to the provider's home page.

=head2 template

  $array_ref = $self->provider_name;

Used to figure out which template to use to render L</html>. Example:

  ["LinkEmbedder::Link", "rich.html.ep];

=head2 thumbnail_height

  $int = $self->thumbnail_height;

The height of the L</thumbnail_url> in pixels. Might be C<undef>.

=head2 thumbnail_url

  $str = $self->thumbnail_url;

URL to the thumbnail which can be used in L</html>.

=head2 thumbnail_width

  $int = $self->thumbnail_width;

The width of the L</thumbnail_url> in pixels. Might be C<undef>.

=head2 title

  $str = $self->title;

Title/heading of the L</url>. Might be C<undef()>.

=head2 type

  $str = $self->title;

oEmbed type of URL: link, photo, rich or video.

=head2 ua

  $ua = $self->ua;

Holds a L<Mojo::UserAgent> object.

=head2 url

  $str = $self->url;

The resource to fetch.

=head2 version

  $str = $self->version;

oEmbed version. Example: "1.0".

=head2 width

  $int = $self->width;

The width in pixels. Might be C<undef>.

=head1 METHODS

=head2 html

  $str = $self->html;

Returns the L</url> as rich markup, if possible.

=head2 learn_p

  $promise = $self->learn_p->then(sub { my $self = shift; });

Used to learn about the L</url>.

=head1 AUTHOR

Jan Henning Thorsen

=head1 SEE ALSO

L<LinkEmbedder>

=cut

__DATA__
@@ iframe.html.ep
<iframe class="le-<%= $l->type %> le-provider-<%= lc $l->provider_name %>" width="<%= $l->width || 600 %>" height="<%= $l->height || 400 %>" style="border:0;width:100%" frameborder="0" allowfullscreen src="<%= $l->{iframe_src} %>"></iframe>
@@ link.html.ep
<a class="le-<%= $l->type %>" href="<%= $l->url %>" title="<%= $l->title || '' %>"><%= Mojo::Util::url_unescape($l->url) %></a>
@@ paste.html.ep
<div class="le-paste le-provider-<%= lc $l->provider_name %> le-<%= $l->type %>">
  <div class="le-meta">
    <span class="le-provider-link"><a href="<%= $l->provider_url %>"><%= $l->provider_name %></a></span>
    <span class="le-goto-link"><a href="<%= $l->url %>" title="<%= $l->title %>"><%= $l->{paste_name} || $l->author_name || 'View' %></a></span>
  </div>
  <pre><%= $l->{paste} || '' %></pre>
</div>
@@ photo.html.ep
<div class="le-<%= $l->type %> le-provider-<%= lc $l->provider_name %>">
  % my $thumbnail_url = $l->thumbnail_url || $l->url;
  <img src="<%= $thumbnail_url %>" alt="<%= $l->title %>">
</div>
@@ rich.html.ep
% if ($l->title) {
  % if (my $thumbnail_url = $l->thumbnail_url || $l->placeholder_url) {
<div class="le-card le-image-card le-<%= $l->type %> le-provider-<%= lc $l->provider_name %>">
    <a href="<%= $l->url %>" class="le-thumbnail<%= $l->thumbnail_url ? '' : '-placeholder' %>">
      <img src="<%= $thumbnail_url %>" alt="<%= $l->author_name || 'Placeholder' %>">
    </a>
  % } else {
<div class="le-card le-<%= $l->type %> le-provider-<%= lc $l->provider_name %>">
  % }
  <h3><%= $l->title %></h3>
    % if ($l->description) {
  <p class="le-description"><%= $l->description %></p>
    % }
  <div class="le-meta">
    % if ($l->author_name) {
    <span class="le-author-link"><a href="<%= $l->author_url || $l->url %>"><%= $l->author_name %></a></span>
    % }
    <span class="le-goto-link"><a href="<%= $l->url %>"><span><%= $l->url %></span></a></span>
  </div>
</div>
% } else {
<a class="le-<%= $l->type %> le-provider-<%= lc $l->provider_name %>" href="<%= $l->url %>"><%= Mojo::Util::url_unescape($l->url) %></a>
% }
@@ video.html.ep
<video class="le-<%= $l->type %> le-provider-<%= lc $l->provider_name %>" height="640" width="480" preload="metadata" controls>
% for my $s (@{$l->{sources} || []}) {
  <source src="<%= $s->{url} %>" type="<%= $s->{type} || '' %>">
% }
  <p>Your browser does not support the video tag.</p>
</video>
