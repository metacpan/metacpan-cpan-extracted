package LinkEmbedder::Link::Basic;
use Mojo::Base 'LinkEmbedder::Link';

use Mojo::Util 'trim';

my $PHOTO_RE = qr!\.(?:jpg|png|gif)\b!i;
my $VIDEO_RE = qr!\.(?:mpg|mpeg|mov|mp4|ogv)\b!i;

sub learn {
  my ($self, $cb) = @_;
  my $url = $self->url;
  my $type = $url =~ $PHOTO_RE ? 'photo' : $url =~ $VIDEO_RE ? 'video' : 'link';

  $self->type($type);

  # Need to learn more from an http request
  if ($type eq 'link') {
    $self->SUPER::learn($cb);
  }
  else {
    $self->_learn_from_url;
    $self->$cb if $cb;
  }

  return $self;
}

sub _learn_from_dom {
  my ($self, $dom) = @_;
  my $tmp;

  $self->SUPER::_learn_from_dom($dom);

  # Mojopaste hack
  $tmp = $dom->at('body > pre');
  if ($tmp and !@{$tmp->children}) {
    $self->{paste} = $tmp->text;
    $self->template->[1] = 'paste.html.ep';
  }

  $tmp = $dom->at('.author-pic > a > img') || $dom->at('link[rel="apple-touch-icon"]') || $dom->at('[rel="icon"]');
  if (!$self->thumbnail_url and $tmp and $tmp->{src} ||= $tmp->{href}) {
    $self->thumbnail_url(Mojo::URL->new($tmp->{src})->to_abs(Mojo::URL->new($self->url))->to_string);
  }

  $tmp = $dom->at('p.about');
  if (!$self->description and $tmp) {
    $tmp = $tmp->all_text;
    $tmp =~ s!\s+! !g;
    $self->description(trim $tmp);
  }
}

1;
