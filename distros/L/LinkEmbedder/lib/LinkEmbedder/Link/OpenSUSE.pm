package LinkEmbedder::Link::OpenSUSE;
use Mojo::Base 'LinkEmbedder::Link';

use constant DEBUG => $ENV{LINK_EMBEDDER_DEBUG} || 0;

has provider_name => 'openSUSE';
has _paste        => undef;

sub learn_p {
  my $self  = shift;
  my $url   = $self->url;
  my $fetch = $url->host eq 'paste.opensuse.org' && @{$url->path} && $url->path->[-1] =~ /^(\d+)$/;

  return $fetch ? $self->_fetch_paste($1) : $self->SUPER::learn_p;
}

sub _fetch_paste {
  my ($self, $paste_id) = @_;
  my $raw_url = $self->url->clone;

  $raw_url->path(sprintf '/view/raw/%s', $paste_id);
  warn "[LinkEmbedder] openSUSE paste URL $raw_url\n" if DEBUG;
  return $self->title("Paste $paste_id")->type("rich")->_get_p($raw_url)->then(sub { $self->_parse_paste(shift) });
}

sub _parse_paste {
  my ($self, $tx) = @_;
  $self->{paste} = $tx->res->body;
  $self->template->[1] = 'paste.html.ep';
  return $self;
}

1;
