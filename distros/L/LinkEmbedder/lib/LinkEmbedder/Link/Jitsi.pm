package LinkEmbedder::Link::Jitsi;
use Mojo::Base 'LinkEmbedder::Link';

has provider_name => 'Jitsi';
has provider_url  => sub { shift->url->clone->path('') };

sub learn_p {
  my $self = shift;
  my $path = $self->url->path;
  return Mojo::Promise->new->resolve($self) if $self->{provider_name} and @$path != 1;
  return $self->SUPER::learn_p unless @$path == 1;

  $self->{iframe_src} = $self->url;
  $self->type('rich');
  $self->template([__PACKAGE__, 'jitsi.html.ep']);
  $self->title("Join the room $path->[0]");

  return Mojo::Promise->new->resolve($self);
}

1;

__DATA__
@@ jitsi.html.ep
<iframe allow="camera;microphone" class="le-rich le-video-chat le-provider-jitsi" width="<%= $l->width || 600 %>" height="<%= $l->height || 400 %>" style="border:0;width:100%" frameborder="0" allowfullscreen src="<%= $l->{iframe_src} %>"></iframe>
