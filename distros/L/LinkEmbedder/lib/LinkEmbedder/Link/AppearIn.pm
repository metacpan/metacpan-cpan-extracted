package LinkEmbedder::Link::AppearIn;
use Mojo::Base 'LinkEmbedder::Link';

has provider_name => 'AppearIn';
has provider_url  => sub { Mojo::URL->new('https://whereby.com') };

sub learn_p {
  my $self = shift;
  my $path = $self->url->path;
  return $self->SUPER::learn_p unless @$path == 1;

  $self->{iframe_src} = "https://whereby.com/$path->[0]";
  $self->height(390) unless $self->height;
  $self->width(740)  unless $self->width;
  $self->type('rich');
  $self->template->[1] = 'iframe.html.ep';
  $self->title("Join the room $path->[0]");

  return Mojo::Promise->new->resolve($self);
}

1;
