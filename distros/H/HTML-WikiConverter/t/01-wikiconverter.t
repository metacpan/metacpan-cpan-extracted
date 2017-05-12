#!perl -T

package MyPerfectWiki;
use base 'HTML::WikiConverter';

sub rules {
  my $self = shift;

  my %rules = (
    b => { start => '**', end => '**' },
    i => { start => '//', end => '//' },
    a => { replace => \&_a },
    p => { block => 1 },
    blockquote => { trim => 'both', block => 1, line_format => 'multi', line_prefix => '>' },
    table => { block => 1, line_format => 'blocks' },
    strong => { alias => 'b' },
    em => { alias => 'i' },
    img => { replace => \&_img },
    funny => { start => '~~', end => '~~' },
    span => { preserve => 1 },
    UNKNOWN => { preserve => 1 },
  );

  $rules{i} = { preserve => 1 } if $self->preserve_italic;

  return \%rules;
}

sub attributes { {
  allow_html => { default => 0 },
  be_cool => { default => 1 },
  preserve_italic => { default => 0 },
} }

sub _a {
  my( $self, $node, $rules ) = @_;
  my $url = $node->attr('href') || '';
  my $title = $self->get_wiki_page($url) || '';
  my $text = $self->get_elem_contents($node) || '';
  return "[[$text]]" if $title eq $text;
  return "[[$text]]" if lcfirst $title eq $text;
  return "[[$title|$text]]" if $title;
  return $url if $url eq $text;
  return sprintf '[[%s|%s]]', $url, $text;
}

sub _img {
  my( $self, $node, $rules ) = @_;
  my $url = $node->attr('src') || '';
  my $title = $self->get_wiki_page($url) || '';
  return '' unless $url and $title;
  return '' unless $title =~ /^image/i;
  return sprintf '{{%s}}', $title;
}

package MySlimWiki;
use base 'HTML::WikiConverter';

sub rules { {
  b => { start => '**', end => '**' },
  i => { start => '//', end => '//' },
  strong => { alias => 'b' },
  em => { alias => 'i' },
  span => { preserve => 1 },
} }

sub attributes { {
  strip_tags => { default => [ qw/ strong em / ] },
  slim_attr => { default => 1 },
} }

package main;

use Test::More tests => 53;
use HTML::WikiConverter;

my $have_lwp = eval "use LWP::UserAgent; 1";
my $have_query_param = eval "use URI::QueryParam; 1";

my $wc = new HTML::WikiConverter(
  dialect => 'MyPerfectWiki',
  base_uri => 'http://www.example.com',
  wiki_uri => [ 'http://www.example.com/wiki/', 'http://www.example.com/images/', \&extract_wiki_page ],
  preprocess => \&preprocess_test,
);

sub extract_wiki_page {
  my( $wc, $url ) = @_;
  return $have_query_param ? $url->query_param('title') : $url =~ /title\=([^&]+)/ && $1;
}

my $preprocess_tested = 0;
sub preprocess_test {
  is( 1, 1, 'preprocess' ) unless $preprocess_tested++;
}

is( $wc->html2wiki('<b>text</b>'), '**text**', 'bold' );
is( $wc->html2wiki('<i>text</i>'), '//text//', 'ital' );
is( $wc->html2wiki('<a href="http://example.com">Example</a>'), '[[http://example.com|Example]]', 'link' );
is( $wc->html2wiki('<blockquote>text1</blockquote>'), '>text1', 'blockquote' );
is( $wc->html2wiki('<blockquote>text1<blockquote>text2</blockquote></blockquote>'), ">text1\n>>text2", 'blockquote nested' );
is( $wc->html2wiki('<a href="/">Example</a>'), '[[http://www.example.com/|Example]]', 'relative URL in link' );
is( $wc->html2wiki('<strong>text</strong>'), '**text**', 'strong' );
is( $wc->html2wiki('<em>text</em>'), '//text//', 'em' );
is( $wc->html2wiki('<a href="/wiki/Example">Example</a>'), '[[Example]]', 'wiki link' );
is( $wc->html2wiki('<img src="/images/Image:Thingy.png" />'), '{{Image:Thingy.png}}', 'image' );
is( $wc->html2wiki('<a href="/w/index.php?title=Thingy&amp;action=view">Text</a>'), '[[Thingy|Text]]', 'long wiki url' );
is( $wc->allow_html, 0, 'bool-false attr check' );

# API tests for backwards-compatibility with 0.51; will be removed in 0.60
is( $wc->html2wiki('<funny>text</funny>'), '~~text~~', '0.51-style rules' );
is( $wc->be_cool, 1, '0.51-style attributes' );

eval { my $wcx = new HTML::WikiConverter( dialect => 'MyPerfectWiki' ) };
ok( !$@, 'dialect class outside H::WC namespace' );

# API checks
eval { my $wcx = new HTML::WikiConverter( dialect => 'MyPerfectWiki', nonexistent_attrib => 1 ) };
ok( $@, 'non-existent attribute' );

is( $wc->html2wiki( html => '<i>text</i>', preserve_italic => 1 ), '<i>text</i>', "setup rules (pt. 1)" );
is( $wc->html2wiki( html => '<i>text</i>', preserve_italic => 0 ), '//text//', "setup rules (pt. 2)" );

# Test that attributes containing references don't clobber each other
my $wc3 = new HTML::WikiConverter( dialect => 'MySlimWiki' );
is_deeply( $wc3->strip_tags, ['strong','em'], 'attr w/ ref (pt 1)' );
is_deeply( $wc->strip_tags, ['~comment','head','script','style'], 'attr w/ ref (pt 2)' );

is( $wc->html2wiki( strip_tags => [], html => '<!--comment-->'), '<!--comment-->', "don't strip" );
is_deeply( $wc->strip_tags, ['~comment','head','script','style'], "attrs revert after html2wiki()" );

eval { $wc->slim_attr };
ok( $@, 'attributes do not overlap' );

#
# Test attribute assignment
#

my $wc4 = new HTML::WikiConverter( dialect => 'MySlimWiki', strip_empty_tags => 1 );
is( $wc4->strip_empty_tags, 1, 'set attribute via new()' );

$wc4->strip_empty_tags(0);
is( $wc4->strip_empty_tags, 0, 'set attribute via object method' );

$wc4->strip_empty_tags(1); # revert
is( $wc4->html2wiki( '<span></span><b>t</b>' ), '**t**', 'attribute set via object method is used in html2wiki()' );
is( $wc4->html2wiki( '<span></span><b>t</b>', strip_empty_tags => 0 ), '<span></span>**t**', 'attribute set in html2wiki() overrides default' );
is( $wc4->strip_empty_tags, 1, 'attribute set via html2wiki() only lasts for the duration of the call' );

is( $wc4->html2wiki('<em>e</em>'), '', 'attribute set via new() has original value' );
is( $wc4->html2wiki('<em>e</em>', strip_tags => ['strong'] ), '//e//', 'assign ref to attr inside html2wiki()' );
is( $wc4->html2wiki('<em>e</em>'), '', 'ref attr returns to original value after call to html2wiki()' );

is( $wc4->html2wiki( html => '&lt;', escape_entities => 0 ), '<', "don't escape entities" );
is( $wc4->html2wiki( html => '&lt;', escape_entities => 1 ), '&lt;', "escape entities" );
is( $wc4->html2wiki( html => '&lt;' ), '&lt;', "escape_entities is enabled by default" );

SKIP: {
  skip "LWP::UserAgent required for testing how content is fetched from URIs" => 4 unless $have_lwp;
  skip "Couldn't fetch test website http://www.perl.org. Perhaps you don't have internet access?" => 4 unless LWP::UserAgent->new->get('http://www.perl.org')->is_success;

  is( $wc4->html2wiki( uri => 'http://diberri.dyndns.org/wikipedia/html2wiki-old/test.html', strip_tags => ['head'] ), '**test**', 'fetch uri, no ua' );
  is( $wc4->user_agent->agent, $wc4->__default_ua_string, 'using default ua' );

  my $ua_agent = 'html2wiki-test/0.5x';
  my $ua = new LWP::UserAgent( agent => $ua_agent );
  $wc4->user_agent($ua);

  is( $wc4->html2wiki( uri => 'http://diberri.dyndns.org/wikipedia/html2wiki-old/test.html', strip_tags => ['head'] ), '**test**', 'fetch uri w/ ua' );
  is( $wc4->user_agent->agent, $ua_agent, 'using user-specified ua' );
};

eval { $wc4->html2wiki( url => '...' ) };
ok( $@ =~ /not a valid argument/, 'url not a valid argument to html2wiki()' );

eval { $wc4->base_url('...') };
ok( $@ =~ /'base_url' is not a valid attribute/, 'base_url not a valid attribute' );

eval { $wc4->wiki_url('...') };
ok( $@ =~ /'wiki_url' is not a valid attribute/, 'wiki_url not a valid attribute' );

is( $wc4->html2wiki( html => "<i>\n<p>\n</p>\n</b>", strip_empty_tags => 1 ), '', 'remove empty <i>' );
is( $wc4->html2wiki( html => "<i>\n<p>\n</p>\n</b>", strip_empty_tags => 0 ), '// //', 'do not remove empty <i>' );

is( $wc4->html2wiki( html => '<font style="font-weight:bold">text</font>' ), '**text**', 'normalize bold css' );
is( $wc4->html2wiki( html => '<font style="font-style:italic">text</font>' ), '//text//', 'normalize italic css' );

is( $wc4->html2wiki( html => '<span>text</span>', passthrough_naked_tags => ['span'] ), 'text', 'passthrough naked tags (ie, tags without attrs)' );

is( $wc->html2wiki( html => '<unknowntag>text</unknowntag>' ), '<unknowntag>text</unknowntag>', 'UNKNOWN preserve' );

is( $wc->html2wiki( html => '<div>text</div>' ), 'text', "known html tags that have no rule are passed through automatically by __wikify" );

is( $wc->html2wiki( html => '<sold>text</sold>', passthrough_naked_tags => 0 ), '<sold>text</sold>', "keep naked html tags" );

is( $wc->html2wiki( html => '<span>text</span>' ), '<span>text</span>', 'hmm' );

is( $wc->html2wiki( html => qq{
<table><tr><td><p>p1</p><p>p2</p></td></tr></table>
} ), "p1\n\np2", 'table p1 p2' );

is( $wc->html2wiki( html => '<a href="/wiki/Test">Test page</a>', base_uri => 'http://www.example.com', wiki_uri => '/wiki/' ), '[[Test|Test page]]', 'absolute wiki_uri from relative wiki_uri and base_uri' );
