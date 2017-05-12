package LinkEmbedder::Link::Twitter;
use Mojo::Base 'LinkEmbedder::Link';

use Mojo::Util 'trim';

has lang => 'en';
has provider_url => sub { Mojo::URL->new('https://twitter.com') };

sub _learn_from_dom {
  my ($self, $dom) = @_;

  $self->SUPER::_learn_from_dom($dom);

  my $name = $self->title || '';
  if ($name =~ s! on twitter$!!i) {
    $self->url->path->trailing_slash(0);
    my $url = $self->url->clone;
    @{$url->path} = ($url->path->[0]);
    $self->author_name($name);
    $self->author_url($url);
    $self->cache_age(3153600000);
    $self->template([__PACKAGE__, 'rich.html.ep']);
  }

  if (!$self->thumbnail_url and my $e = $dom->at('.ProfileAvatar-image[src]')) {
    $self->author_name(trim($e->{alt} || ''));
    $self->author_url($self->url);
    $self->thumbnail_url($e->{src});
  }
}

1;

__DATA__
@@ rich.html.ep
<blockquote class="twitter-tweet le-card le-provider-twitter" data-cards="hidden">
  <h3><%= $l->title %></h3>
  <p lang="<%= $l->lang %>" dir="ltr" class="le-description"><%= $l->description %></p>
  <div class="le-meta">
    <span class="le-author-link"><a href="<%= $l->author_url || $l->url %>"><%= $l->author_name %></a></span>
    <span class="le-goto-link"><a href="<%= $l->url %>">@<%= $l->url->path->[0] %></a></span>
  </div>
</div>
</blockquote>
@@ helper.html.ep
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>
