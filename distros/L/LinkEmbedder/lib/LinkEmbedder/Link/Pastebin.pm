package LinkEmbedder::Link::Pastebin;
use Mojo::Base 'LinkEmbedder::Link';

has provider_name => 'Pastebin';
has provider_url => sub { Mojo::URL->new('https://pastebin.com') };

sub _learn_from_dom {
  my ($self, $dom) = @_;
  $self->SUPER::_learn_from_dom($dom);

  if (my $e = $dom->at('textarea#paste_code')) {
    $self->{paste} = $e->text;
    $self->template->[1] = 'paste.html.ep';
  }
}

1;
