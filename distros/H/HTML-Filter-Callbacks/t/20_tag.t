use strict;
use warnings;
use Test::More;
use HTML::Filter::Callbacks;

my $filter = HTML::Filter::Callbacks->new;

my @callbacks = (
  foo => {
    start => sub {
      my $tag = shift;
      is $tag->name => 'foo', 'tag name is correct';
    },
  },
  foo => {
    start => sub {
      my $tag = shift;
      is $tag->attr('name') => 'bar', 'got an attribute by name';
    },
  },
  foo => {
    start => sub {
      my $tag = shift;
      like $tag->text => qr/comment/, 'got the right text including the comment';
    },
  },
  script => {
    end => sub {
      my $tag = shift;
      like $tag->text => qr/javascript/, 'got the right text including the script';
    },
  },
  ul => {
    end => sub {
      my $tag = shift;
      like $tag->text => qr/list 3/, 'note that this kind of thing may happen...';
    },
  },
  img => {
    start => sub {
      my $tag = shift;
      $tag->add_attr(alt => 'alternative text');
      like $tag->as_string => qr/<img [^>]*alt="alternative text"/, 'added an attribute';
    },
  },
  img => {
    start => sub {
      my $tag = shift;
      $tag->add_attr(src => 'bar');
      my $html = $tag->as_string;
      like $html => qr/<img [^>]*src="bar"/, 'replaced an attribute';
      unlike $html => qr/<img [^>]*src=[^>]*src=/, 'and not duped';
    },
  },
  a => {
    start => sub {
      my $tag = shift;
      $tag->remove_attr('bad_attr');
      my $html = $tag->as_string;
      unlike $html => qr/bad_attr/, 'removed an attribute by name';
    },
  },
  a => {
    start => sub {
      my $tag = shift;
      $tag->remove_attr(qr/^on_/);
      my $html = $tag->as_string;
      unlike $html => qr/on_click/, 'removed an attribute by regexp';
    },
  },
  a => {
    start => sub {
      my $tag = shift;
      $tag->replace_attr(href => 'http://example.com/?foo=bar&hoo=ver');
      my $html = $tag->as_string;
      like $html => qr{\Qhttp://example.com/?foo=bar&amp;hoo=ver}, 'replaced an attribute by name';
    },
  },
  a => {
    start => sub {
      my $tag = shift;
      $tag->replace_attr(qr/^n/ => 'name');
      my $html = $tag->as_string;
      like $html => qr/name="name"/, 'replaced an attribute by regexp';
    },
  },
  div => {
    start => sub {
      my $tag = shift;
      $tag->remove_tag;
      my $html = $tag->as_string;
      unlike $html => qr/<div/, 'removed the tag';
      like $html => qr/<!--div/, 'but still text is left';
    },
  },
  div => {
    end => sub {
      my $tag = shift;
      $tag->remove_text_and_tag;
      my $html = $tag->as_string;
      unlike $html => qr{</div}, 'removed the tag';
      unlike $html => qr/<!--div/, 'and text is gone';
    },
  },
  p => {
    end => sub {
      my $tag = shift;
      $tag->remove_text;
      my $html = $tag->as_string;
      unlike $html => qr/text/, 'text is gone';
      like $html => qr{</p}, 'but the tag is left';
    },
  },
  form => {
    start => sub {
      my $tag = shift;
      $tag->append(qq/<input type="text" name="foo">\n/);
      my $html = $tag->as_string;
      like $html => qr/<form><input type="text"/, 'text is appended';
    },
  },
  form => {
    end => sub {
      my $tag = shift;
      $tag->prepend(qq/<input type="submit">\n/);
      my $html = $tag->as_string;
      like $html => qr{<input type="submit">\n</form>}, 'text is prepended';
    },
  },
  hr => {
    start => sub {
      my $tag = shift;
      $tag->remove_attr('clear');
      my $html = $tag->as_string;
      like $html => qr{<hr />}, 'stays empty';
    },
  },
  hoge => {
    start => sub {
      my $tag = shift;
      is $tag->attr('fuga') => 'piyo', 'got an attribute by fuga (original FuGa)';
      $tag->replace_attr('fuga' => 'hoge');
      is $tag->attr('fuga') => 'hoge', 'replaced value';
      $tag->remove_attr('fuga');
      ok !$tag->attr('fuga'), 'removed';
    },
  },
  custom => {
    start => sub {
      my $tag = shift;
      is $tag->attr('id') => 'my_custom', 'got an attribute';
      $tag->replace_tag('div');
      is $tag->name => 'div', 'replaced tag';
      my $html = $tag->as_string;
      like $html => qr{<div id="my_custom" />}, 'replaced tag. keep attribute';
    },
  },
);

plan tests => (scalar @callbacks / 2) + 8;
$filter->add_callbacks(@callbacks);
$filter->process(<<'HTML');
<html>
<head>
<script>
<!-- javascript
//-->
</script>
</head>
<body>
<!--comment-->
<foo name="bar">
<ul>
<li>list 1
<li>list 2
<li>list 3
</ul>
<img src="foo" name="foo">
<a href="foo" name="bar" on_click="bar" bad_attr>
<!--div-->
<div>
div body
</div>
<p>text</p>
</body>
<form>
</form>
<hr clear="all" />
<hoge FuGa="piyo" />
<custom id="my_custom" />
</html>

HTML
