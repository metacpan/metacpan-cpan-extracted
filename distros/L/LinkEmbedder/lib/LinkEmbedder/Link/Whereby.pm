package LinkEmbedder::Link::Whereby;
use Mojo::Base 'LinkEmbedder::Link';

has provider_name => 'Whereby';
has provider_url  => sub { Mojo::URL->new('https://whereby.com') };

sub learn_p {
  my $self = shift;
  my $path = $self->url->path;
  return $self->SUPER::learn_p unless @$path == 1;

  $self->{iframe_src} = "https://whereby.com/$path->[0]?embed";
  $self->height(390) unless $self->height;
  $self->width(740)  unless $self->width;
  $self->type('rich');
  $self->template([__PACKAGE__, 'appearin.html.ep']);
  $self->title("Join the room $path->[0]");

  return Mojo::Promise->new->resolve($self);
}

1;

__DATA__
@@ appearin.html.ep
<iframe allow="camera;microphone" class="le-rich le-video-chat le-provider-whereby" width="<%= $l->width || 600 %>" height="<%= $l->height || 400 %>" style="border:0;width:100%" frameborder="0" allowfullscreen src="<%= $l->{iframe_src} %>"></iframe>
