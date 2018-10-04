package LinkEmbedder::Link::Basic;
use Mojo::Base 'LinkEmbedder::Link';

use Mojo::Util 'trim';

my $PHOTO_RE = qr!\.(?:jpg|png|gif)\b!i;
my $VIDEO_RE = qr!\.(?:mpg|mpeg|mov|mp4|ogv)\b!i;

sub learn_p {
  my $self = shift;
  my $url  = $self->url;
  my $type = $url =~ $PHOTO_RE ? 'photo' : $url =~ $VIDEO_RE ? 'video' : 'link';

  $self->type($type);

  return $type eq 'link' ? $self->SUPER::learn_p : Mojo::Promise->new->resolve($self->_learn_from_url);
}

sub _learn_from_dom {
  my ($self, $dom) = @_;
  my $tmp;

  $self->SUPER::_learn_from_dom($dom);

  # Bitbucket hack
  $tmp = $dom->at('div.codehilite');
  if ($tmp) {
    $self->{paste} = $tmp->all_text;
    $self->template->[1] = 'paste.html.ep';
  }

  # Mojopaste and Perlbot hack
  $tmp = $dom->at('body > pre') || $dom->at('pre#paste') || $dom->at('pre.paste');
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

  return $self;
}

1;
