package LinkEmbedder::Link::oEmbed;
use Mojo::Base 'LinkEmbedder::Link';

use constant DEBUG => $ENV{LINK_EMBEDDER_DEBUG} || 0;

require LinkEmbedder;

# please report back if you add more urls to this hash
our %API = (
  'ted.com'     => 'https://www.ted.com/services/v1/oembed.json',
  'vimeo.com'   => 'https://vimeo.com/api/oembed.json',
  'youtube.com' => 'https://www.youtube.com/oembed',
);

has html => sub { shift->SUPER::html };

sub learn_p {
  my $self = shift;
  return $self->SUPER::learn_p unless $self->url->path =~ /\w/;

  my $api_url = $self->_api_url;
  return $self->_get_p($api_url)->then(sub { $self->_learn_from_json(shift) }) if $api_url;

  $self->error({message => "Unknown oEmbed provider for @{[$self->url]}", code => 400});
  return $self;
}

sub _api_url {
  my $self    = shift;
  my $url     = $self->url->clone;
  my $api_url = LinkEmbedder::_host_in_hash($url->host, \%API) or return undef;

  $url->path->trailing_slash(0);
  $api_url = Mojo::URL->new($api_url);
  $api_url->query->param(url => $url->to_string);

  return $api_url;
}

1;
