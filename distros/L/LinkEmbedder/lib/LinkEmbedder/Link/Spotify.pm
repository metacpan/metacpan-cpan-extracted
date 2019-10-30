package LinkEmbedder::Link::Spotify;
use Mojo::Base 'LinkEmbedder::Link';

has provider_name => 'Spotify';
has provider_url  => sub { Mojo::URL->new('https://spotify.com') };
has theme         => 'white';
has view          => '';                                              # list, coverart

sub learn_p {
  my $self = shift;
  my $url  = $self->url;
  my ($iframe_src, @path);

  if ($url =~ s!^spotify:!!) {                                        # spotify:track:5tv77MoS0TzE0sJ7RwTj34
    @path = split /:/, $url;
  }
  elsif (@{$url->path} == 2) {    # https://open.spotify.com/artist/6VKNnZIuu9YEOvLgxR6uhQ
    @path = @{$url->path};
  }

  return $self->SUPER::learn_p unless @path;

  $iframe_src = Mojo::URL->new('https://embed.spotify.com');
  $iframe_src->query(theme => $self->theme, uri => join(':', spotify => @path), view => $self->view);
  $self->{iframe_src} = $iframe_src;
  $self->template->[1] = 'iframe.html.ep';
  $self->type('rich');

  return Mojo::Promise->new->resolve($self);
}

1;
