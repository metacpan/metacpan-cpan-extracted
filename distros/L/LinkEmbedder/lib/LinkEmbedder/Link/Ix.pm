package LinkEmbedder::Link::Ix;
use Mojo::Base 'LinkEmbedder::Link';

sub force_secure {0}
has provider_name => 'Ix';
has provider_url  => sub { Mojo::URL->new('http://ix.io') };

sub _learn {
  my ($self, $tx) = @_;

  if ($self->url->path =~ m!^/\w+$!) {
    $self->{paste} = $tx->res->text;
    $self->{paste} =~ s![\r\n]+$!!i;
    $self->type('rich');
    $self->template->[1] = 'paste.html.ep';
  }
  else {
    $self->SUPER::_learn($tx);
  }

  return $self;
}

1;
