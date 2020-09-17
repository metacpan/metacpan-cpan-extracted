package LinkEmbedder::Link::Instagram;
use Mojo::Base 'LinkEmbedder::Link::oEmbed';

use Mojo::Util;

has provider_name => 'Instagram';
has provider_url  => sub { Mojo::URL->new('https://instagram.com') };

sub _learn_from_json {
  my ($self, $tx) = @_;
  $self->SUPER::_learn_from_json($tx);

  my $path = $self->url->path;
  return unless $path->[0] and $path->[1] and $path->[0] eq 'p';

  $path->trailing_slash(1);
  $self->template([__PACKAGE__, 'instaframe.html.ep']);
  $self->type('rich');
  delete $self->{html};
}

1;

__DATA__
@@ instaframe.html.ep
<iframe class="le-rich le-provider-instagram" width="400" height="480" style="border:0;width:100%" frameborder="0" src="<%= $l->url %>embed"></iframe>
