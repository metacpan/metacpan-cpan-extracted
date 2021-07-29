package LinkEmbedder::Link::Github;
use Mojo::Base 'LinkEmbedder::Link';

use Mojo::Util qw(html_unescape trim);

use constant DEBUG => $ENV{LINK_EMBEDDER_DEBUG} || 0;

has provider_name => 'GitHub';
has provider_url  => sub { Mojo::URL->new('https://github.com') };

sub learn_p {
  my $self = shift;
  return $self->url =~ m!gist\.github\.com/(.+)! ? $self->_learn_from_gist_p($1) : $self->SUPER::learn_p;
}

sub _learn_from_dom {
  my ($self, $dom) = @_;
  my $e;

  $self->SUPER::_learn_from_dom($dom);

  # Sometimes the og:title is less informative than <title>
  $e = $dom->at('title');
  $self->title($e->all_text) if $e and length($e->all_text) > length($self->title);

  # Pages with readme
  $e = $dom->find('#readme p');
  $self->_learn_from_readme($e) if $e;

  # Pages with source code
  $e = $dom->find('table.highlight');
  $self->_learn_from_code($e->first, $dom) if $e->size == 1;

  # Clean up title
  my $title = $self->title;
  $title =~ s!^\s*GitHub\W+!!si;
  $title =~ s![^\w\)\]\}]+GitHub\s*$!!si;
  $self->title($title);
}

sub _learn_from_code {
  my ($self, $e, $dom) = @_;
  my $selector = '';

  # Handle line number possibly with range
  my $fragment = $self->url->fragment;
  if ($fragment =~ /L(\d+)(?:-L(\d+))?/) {
    my $from = $1;
    my $to   = $2 // $from + 10;
    $selector .= '.blob-num:is(' . join(', ', map {qq([data-line-number="$_"])} $from .. $to) . ') + ';
  }

  $selector .= '.blob-code';
  return unless my @code = $e->find($selector)->map('all_text')->each;

  $self->{paste}       = join '', map { $_ .= "\n" unless /\n$/; $_ } @code;
  $self->template->[1] = 'paste.html.ep';

  if ($e = $dom->at('#blob-path')) {
    $self->title(trim html_unescape $e->all_text) if $e->all_text;
  }
}

sub _learn_from_gist_p {
  my ($self, $gist_id) = @_;
  my @gist_id = split '/', $gist_id;

  $gist_id = $gist_id[1] if @gist_id >= 2;
  my $gist_url = Mojo::URL->new(sprintf 'https://api.github.com/gists/%s', $gist_id);
  return $self->_get_p($gist_url)->then(sub { $self->_parse_gist(shift) });
}

sub _learn_from_readme {
  my ($self, $p) = @_;
  my $skip = $self->title;

  for my $e ($p->each) {
    my $text = $e->all_text || '';
    next unless $text =~ /\w/ and $text =~ /\.\s*$/;
    next unless index($text, $skip) == -1;
    $self->description($text);
    last;
  }
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
