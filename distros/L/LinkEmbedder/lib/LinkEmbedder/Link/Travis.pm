package LinkEmbedder::Link::Travis;
use Mojo::Base 'LinkEmbedder::Link';

has provider_name    => 'Travis';
has provider_url     => sub { Mojo::URL->new('https://travis-ci.org') };
has thumbnail_height => 501;
has thumbnail_url    => $ENV{LINK_EMBEDDER_TRAVIS_THUMBNAIL_URL}
  || 'https://cdn.travis-ci.org/images/logos/TravisCI-Mascot-1-20feeadb48fc2492ba741d89cb5a5c8a.png';
has thumbnail_width => 497;

sub learn_p {
  my $self     = shift;
  my $api_url  = $self->url->clone->host('api.travis-ci.org');
  my $api_path = $api_url->path;

  return $self->SUPER::learn_p unless $api_path =~ m!^/(.*/builds/\d+)$!;

  $api_url->path->parse("/repositories/$1");
  return $self->_get_p($api_url)->then(sub { $self->_learn_from_json(shift) });
}

sub _learn_from_json {
  my ($self, $tx) = @_;
  my $json = $tx->res->json;

  $self->type('rich');

  if (my $description = $json->{message}) {
    $description = "$json->{author_name}: $description" if $json->{author_name};
    $self->description($description);
  }

  if ($json->{finished_at}) {
    $self->title(sprintf 'Build %s at %s', $json->{status} ? 'failed' : 'succeeded', $json->{finished_at});
  }
  elsif ($json->{started_at}) {
    $self->title(sprintf 'Started building at %s.', $json->{started_at});
  }
  else {
    $self->title('Build has not been started.');
  }

  return $self;
}

1;
