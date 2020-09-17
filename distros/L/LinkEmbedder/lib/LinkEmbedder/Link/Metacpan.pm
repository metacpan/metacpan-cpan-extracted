package LinkEmbedder::Link::Metacpan;
use Mojo::Base 'LinkEmbedder::Link';

has provider_name => 'Metacpan';
has provider_url  => sub { Mojo::URL->new('https://metacpan.org') };

sub _learn_from_dom {
  my ($self, $dom) = @_;
  $self->SUPER::_learn_from_dom($dom);

  my $img = $dom->at('.author-pic > a > img') || $dom->at('link[rel="apple-touch-icon"]') or return;
  my $url = $img->{src}                       || $img->{href};
  $self->thumbnail_url(Mojo::URL->new($url =~ /^https?:/ ? $url : "//metacpan.org$url"));
}

1;
