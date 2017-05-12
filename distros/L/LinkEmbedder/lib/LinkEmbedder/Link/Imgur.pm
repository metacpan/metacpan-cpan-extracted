package LinkEmbedder::Link::Imgur;
use Mojo::Base 'LinkEmbedder::Link';

has provider_name => 'Imgur';
has provider_url => sub { Mojo::URL->new('http://imgur.com') };

sub _learn_from_dom {
  my ($self, $dom) = @_;
  $self->SUPER::_learn_from_dom($dom);

  my $el = $dom->at('[name="twitter:image"]') or return;
  $self->height(0)->width(0)->type('photo');
  $self->url(Mojo::URL->new($el->{content}));
}

1;
