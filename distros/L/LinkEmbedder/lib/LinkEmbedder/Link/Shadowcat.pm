package LinkEmbedder::Link::Shadowcat;
use Mojo::Base 'LinkEmbedder::Link';

use constant DEBUG => $ENV{LINK_EMBEDDER_DEBUG} || 0;

has provider_name => 'Shadowcat';
has provider_url => sub { Mojo::URL->new('http://shadow.cat/') };

sub learn_p {
  my $self = shift;
  my $path = $self->url->path;

  return $self->_fetch_paste($1) if @$path and $path->[-1] =~ /^(\d+)$/;
  return $self->SUPER::learn_p;
}

sub _fetch_paste {
  my ($self, $paste_id) = @_;
  my $raw_url = $self->url->clone;

  $raw_url->query->param(tx => 'on');
  warn "[LinkEmbedder] Shadowcat paste URL $raw_url\n" if DEBUG;

  return $self->title("Paste $paste_id")->type("rich")->ua->get_p($raw_url)->then(sub { $self->_parse_paste(shift) });
}

sub _parse_paste {
  my ($self, $tx) = @_;
  $self->{paste} = $tx->res->body;
  $self->template->[1] = 'paste.html.ep';
  return $self;
}

1;
