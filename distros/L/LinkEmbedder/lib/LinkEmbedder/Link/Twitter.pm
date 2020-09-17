package LinkEmbedder::Link::Twitter;
use Mojo::Base 'LinkEmbedder::Link';

use Mojo::Util;

has provider_name => 'Twitter';
has provider_url  => sub { Mojo::URL->new('https://twitter.com') };

sub learn_p {
  my $self = shift;
  my $path = $self->url->path;
  return $self->SUPER::learn_p(@_) unless @$path >= 3 and $path->[1] eq 'status';

  $self->author_name($path->[0]);
  $self->author_url($self->provider_url->clone->path("/$path->[0]"));
  $self->template([__PACKAGE__, 'twitframe.html.ep']);
  $self->url($self->provider_url->clone->path("/$path->[0]/status/$path->[2]"));
  $self->type('rich');
  return Mojo::Promise->resolve($self);
}

1;

__DATA__
@@ twitframe.html.ep
<iframe class="le-rich le-provider-twitter" width="430" height="220" style="border:0;width:100%" frameborder="0" src="https://twitframe.com/show?url=<%== Mojo::Util::url_escape($l->url) %>"></iframe>
