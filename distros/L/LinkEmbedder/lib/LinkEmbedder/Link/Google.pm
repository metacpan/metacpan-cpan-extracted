package LinkEmbedder::Link::Google;
use Mojo::Base 'LinkEmbedder::Link';

has provider_name => 'Google';
has provider_url => sub { Mojo::URL->new('https://google.com') };

sub learn {
  my ($self, $cb) = @_;
  my $url  = $self->url;
  my @path = @{$url->path};
  my ($iframe_src, @query);

  push @query, $url->query->param('q') if $url->query->param('q');

  while (my $path = shift @path) {
    if ($path =~ /^\@\d+/) {
      $path =~ s!,\w+[a-z]$!!;    # @59.9195858,10.7633821,17z
      push @query, $path;
    }
    elsif ($path eq 'place' and @path) {
      push @query, shift @path;
      my $title = $query[-1];
      $title = Mojo::Util::url_unescape($query[-1]);
      $title =~ s!\+! !g;
      $self->title($title);
    }
  }

  return $self->SUPER::learn($cb) unless @query;

  $iframe_src = Mojo::URL->new('https://www.google.com/maps');
  $iframe_src->query->param(q => join ' ', @query);
  $self->{iframe_src} = $iframe_src;
  $self->template->[1] = 'iframe.html.ep';
  $self->type('rich');
  $self->$cb if $cb;
  $self;
}

1;
