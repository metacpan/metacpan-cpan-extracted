package LinkEmbedder::Link::Xkcd;
use Mojo::Base 'LinkEmbedder::Link';

has provider_name => 'Xkcd';
has provider_url => sub { Mojo::URL->new('http://xkcd.com') };

sub _learn_from_dom {
  my ($self, $dom) = @_;
  $self->SUPER::_learn_from_dom($dom);

  my $img = $dom->at('#comic img') or return;
  $self->description($img->{title}) if $img->{title};
  $self->height(0)->width(0)->type('photo');
  $self->title($img->{alt} || $img->{title}) if $img->{alt} or $img->{title};
  $self->url(Mojo::URL->new($img->{src}));
}

1;
