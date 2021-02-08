package LinkEmbedder::Link::Webex;
use Mojo::Base 'LinkEmbedder::Link';

has provider_name => 'Webex';
has provider_url  => sub { Mojo::URL->new('https://webex.com') };

sub learn_p {
  my $self = shift;
  my $path = $self->url->path;
  return $self->SUPER::learn_p unless @$path == 2 and $path->[0] eq 'meet';

  $self->{iframe_src} = $self->url;
  $self->type('rich');
  $self->title("Join the room $path->[1]");
  $self->template([__PACKAGE__, 'webex.html.ep']);

  return Mojo::Promise->new->resolve($self);
}

1;

__DATA__
@@ webex.html.ep
<iframe allow="camera;microphone" class="le-rich le-video-chat le-provider-webex" width="<%= $l->width || 600 %>" height="<%= $l->height || 400 %>" style="border:0;width:100%" frameborder="0" allowfullscreen src="<%= $l->{iframe_src} %>"></iframe>
