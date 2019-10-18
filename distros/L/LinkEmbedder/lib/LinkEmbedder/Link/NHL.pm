package LinkEmbedder::Link::NHL;
use Mojo::Base 'LinkEmbedder::Link';

has provider_name => 'NHL';
has provider_url => sub { Mojo::URL->new('https://www.nhl.com') };

sub learn_p {
  my $self = shift;
  my $path = $self->url->path->to_string;
  return $self->SUPER::learn_p unless $path =~ m!^/video!;

  $path =~ s!/video!video/embed!;
  $self->{iframe_src} = "https://www.nhl.com/$path?autostart=false";
  $self->height(360) unless $self->height;
  $self->width(540)  unless $self->width;
  $self->type('rich');
  $self->template->[1] = 'iframe.html.ep';
  $self->title("NHL Video");

  return Mojo::Promise->new->resolve($self);
}

1;
