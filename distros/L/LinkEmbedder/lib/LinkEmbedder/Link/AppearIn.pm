package LinkEmbedder::Link::AppearIn;
use Mojo::Base 'LinkEmbedder::Link';

has provider_name => 'AppearIn';
has provider_url => sub { Mojo::URL->new('https://appear.in') };

sub learn {
  my ($self, $cb) = @_;
  my $path = $self->url->path;

  return $self->SUPER::learn($cb) unless @$path == 1;

  $self->{iframe_src} = "https://appear.in/$path->[0]";
  $self->height(390) unless $self->height;
  $self->width(740)  unless $self->width;
  $self->type('rich');
  $self->template->[1] = 'iframe.html.ep';
  $self->title("Join the room $path->[0]");

  $self->$cb if $cb;
  return $self;
}

1;
