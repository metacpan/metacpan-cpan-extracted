package LinkEmbedder::Link::Github;
use Mojo::Base 'LinkEmbedder::Link';

use constant DEBUG => $ENV{LINK_EMBEDDER_DEBUG} || 0;

has provider_name => 'GitHub';
has provider_url => sub { Mojo::URL->new('https://github.com') };

sub learn_p {
  my $self = shift;
  return $self->url =~ m!gist\.github\.com/(.+)! ? $self->_learn_from_gist($1) : $self->SUPER::learn_p;
}

sub _learn_from_dom {
  my ($self, $dom) = @_;
  my $e;

  $self->SUPER::_learn_from_dom($dom);

  # Clean up title
  if ($e = $dom->at('title')) {
    $e = $e->all_text;
    $e =~ s!^\s*GitHub\W+!!si;
    $e =~ s![^\w\)\]\}]+GitHub\s*$!!si;
    $self->title($e);
  }

  # Pages with a readme file
  my $skip = $self->title;
  $skip =~ s!\S+:\s+(\w)!$1!;    # remove "username/repo:"
  for my $e ($dom->find('#readme p')->each) {
    my $text = $e->all_text || '';
    next unless $text =~ /\w/;
    next unless index($text, $skip) == -1;
    $self->description($text);
    last;
  }
}

sub _learn_from_gist {
  my ($self, $gist_id) = @_;
  my @gist_id = split '/', $gist_id;

  $gist_id = $gist_id[1] if @gist_id >= 2;
  my $raw_url = sprintf 'https://api.github.com/gists/%s', $gist_id;
  warn "[LinkEmbedder] Gist URL $raw_url\n" if DEBUG;

  return $self->ua->get_p($raw_url)->then(sub { $self->_parse_gist(shift) });
}

sub _parse_gist {
  my ($self, $tx) = @_;
  $self->_learn_from_json($tx);
  return $self unless $self->{files};
  return $self->type('rich')->template([__PACKAGE__, 'gist.html.ep']);
}

1;

__DATA__
@@ gist.html.ep
% for my $p (sort { $a->{filename} cmp $b->{filename} } values %{$l->{files} || {}}) {
<div class="le-paste le-rich le-provider-github<%= $p->{truncated} ? ' le-paste-truncated' : '' %>">
  <div class="le-meta">
    <span class="le-provider-link"><a href="<%= $l->provider_url %>"><%= $l->provider_name %></a></span>
    <span class="le-goto-link"><a href="<%= $l->url %>" title="<%= $l->description %>"><%= $p->{filename} || 'View' %></a></span>
  </div>
  <pre data-language="<%= $p->{language} || '' %>" data-size="<%= $p->{size} || 0 %>"><%= $p->{content} || '' %></pre>
</div>
% }
