package LinkEmbedder::Link::oEmbed;
use Mojo::Base 'LinkEmbedder::Link';

use constant DEBUG => $ENV{LINK_EMBEDDER_DEBUG} || 0;

require LinkEmbedder;

# please report back if you add more urls to this hash
our %API = (
  'instagram.com' => 'https://api.instagram.com/oembed?omitscript=1',
  'ted.com'       => 'https://www.ted.com/services/v1/oembed.json',
  'vimeo.com'     => 'https://vimeo.com/api/oembed.json',
  'youtube.com'   => 'https://www.youtube.com/oembed',
);

has html => sub { shift->SUPER::html };

sub learn {
  my ($self, $cb) = @_;

  unless ($self->url->path =~ /\w/) {
    return $self->SUPER::learn($cb);
  }

  my $api_url = $self->_api_url;
  unless ($api_url) {
    $self->error({message => "Unknown oEmbed provider for @{[$self->url]}", code => 400});
    $self->$cb if $cb;
    return $self;
  }

  warn "[LinkEmbedder] oembed URL $api_url\n" if DEBUG;

  if ($cb) {
    $self->ua->get($api_url => sub { $self->tap(_learn_from_json => $_[1])->$cb });
  }
  else {
    $self->_learn_from_json($self->ua->get($api_url));
  }

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
