package LinkEmbedder::Link::Imgur;
use Mojo::Base 'LinkEmbedder::Link';

has provider_name => 'Imgur';
has provider_url  => sub { Mojo::URL->new('https://imgur.com') };

sub learn_p {
  my $self = shift;
  my $url  = $self->url;
  return $self->SUPER::learn_p(@_) if @{$url->path} != 1 and $url->path->[0] !~ m!^\w+$!;

  $url = $url->clone;
  push @{$url->path}, 'embed';
  return $self->_get_p($url)->then(sub { $self->_learn(shift) });
}

sub _learn_from_dom {
  my ($self, $dom) = @_;
  $self->SUPER::_learn_from_dom($dom);
  $self->title('Attempt to sit still until cat decides to move.  via  #reddit') unless $self->title;

  my $el  = $dom->at('img.post[src]') or return;
  my $url = Mojo::URL->new($el->{src})->scheme('https');
  $self->height(0)->width(0)->type('photo');
  $self->thumbnail_url($url->to_string);
}

1;
