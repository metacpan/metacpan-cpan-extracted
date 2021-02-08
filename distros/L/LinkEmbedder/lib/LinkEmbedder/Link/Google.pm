package LinkEmbedder::Link::Google;
use Mojo::Base 'LinkEmbedder::Link';

has provider_name => 'Google';
has provider_url  => sub { Mojo::URL->new('https://google.com') };

sub learn_p {
  my $self = shift;
  my $url  = $self->url;
  return $self->_learn_from_meet_p if $url->host eq 'meet.google.com';

  my @path = @{$url->path};
  my ($iframe_src, @query);

  push @query, $url->query->param('q') if $url->query->param('q');

  while (my $path = shift @path) {
    if ($path =~ /^\@\d+/) {
      $path =~ s!,\w+[a-z]$!!;    # @59.9195858,10.7633821,17z
      push @query, $path;
    }
    elsif ($path eq 'place' and @path) {
      push @query, shift @path;
      my $title = $query[-1];
      $title = Mojo::Util::url_unescape($query[-1]);
      $title =~ s!\+! !g;
      $self->title($title);
    }
  }

  # Not a google maps link
  return $self->SUPER::learn_p if @query < 2;

  $iframe_src = Mojo::URL->new('https://www.google.com/maps');
  $iframe_src->query->param(q => join ' ', @query);
  $self->{iframe_src} = $iframe_src;
  $self->template->[1] = 'iframe.html.ep';
  $self->type('rich');

  return Mojo::Promise->new->resolve($self);
}

sub _learn {
  my ($self, $tx) = @_;
  my $js_redirect = $tx->res->dom->at('div[data-destination^="http"]');

  return $self->_get_p(Mojo::URL->new($js_redirect->{'data-destination'}))->then(sub { $self->_learn(shift) })
    if $js_redirect and !$self->{js_redirect}++;

  return $self->SUPER::_learn($tx);
}

sub _learn_from_meet_p {
  my $self = shift;
  my $url  = $self->url;
  return $self->SUPER::learn_p unless @{$url->path} == 1;

  $self->provider_url($url->clone->path('')->query(Mojo::Parameters->new));
  $self->template([__PACKAGE__, 'google-meet.html.ep']);
  $self->title("Join the room @{[$url->path->[0]]}");
  $self->type('rich');

  return Mojo::Promise->new->resolve($self);
}

1;

__DATA__
@@ google-meet.html.ep
<iframe allow="camera;microphone" class="le-rich le-video-chat le-provider-google" width="<%= $l->width || 600 %>" height="<%= $l->height || 400 %>" style="border:0;width:100%" frameborder="0" allowfullscreen src="<%= $l->url %>"></iframe>
