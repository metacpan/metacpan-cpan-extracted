package LinkEmbedder::Link::OpenSUSE;
use Mojo::Base 'LinkEmbedder::Link';

use constant DEBUG => $ENV{LINK_EMBEDDER_DEBUG} || 0;

has provider_name => 'openSUSE';
has _paste        => undef;

sub learn {
  my ($self, $cb) = @_;
  my $url = $self->url;

  if ($url->host eq 'paste.opensuse.org' and @{$url->path} and $url->path->[-1] =~ /^(\d+)$/) {
    return $self->_fetch_paste($1, $cb);
  }

  return $self->SUPER::learn($cb);
}

sub _fetch_paste {
  my ($self, $paste_id, $cb) = @_;
  my $raw_url = $self->url->clone;

  $raw_url->path(sprintf '/view/raw/%s', $paste_id);
  warn "[LinkEmbedder] openSUSE paste URL $raw_url\n" if DEBUG;

  if ($cb) {
    $self->ua->get($raw_url => sub { $self->tap(_parse_paste => $_[1])->$cb });
  }
  else {
    $self->_parse_paste($self->ua->get($raw_url));
  }

  return $self->title("Paste $paste_id")->type("rich");
}

sub _parse_paste {
  my ($self, $tx) = @_;
  $self->{paste} = $tx->res->body;
  $self->template->[1] = 'paste.html.ep';
}

1;
