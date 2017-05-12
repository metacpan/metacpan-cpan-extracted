package LinkEmbedder::Link::Shadowcat;
use Mojo::Base 'LinkEmbedder::Link';

use constant DEBUG => $ENV{LINK_EMBEDDER_DEBUG} || 0;

has provider_name => 'Shadowcat';
has provider_url => sub { Mojo::URL->new('http://shadow.cat/') };

sub learn {
  my ($self, $cb) = @_;
  my $path = $self->url->path;

  return $self->_fetch_paste($1, $cb) if @$path and $path->[-1] =~ /^(\d+)$/;
  return $self->SUPER::learn($cb);
}

sub _fetch_paste {
  my ($self, $paste_id, $cb) = @_;
  my $raw_url = $self->url->clone;

  $raw_url->query->param(tx => 'on');
  warn "[LinkEmbedder] Shadowcat paste URL $raw_url\n" if DEBUG;

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
