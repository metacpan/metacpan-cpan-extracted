use strict;
use warnings FATAL => 'all';

use HTML::Zoom;
use Test::More;

ok my $zoom = HTML::Zoom->new( { zconfig => { parser => 'HTML::Zoom::Parser::HH5P' } } )->from_html(<<HTML);
<html>
  <head>
    <title>Hi!</title>
  </head>
  <body id="content-area">
    <h1>Test</h1>
    <div>
      <p class="first-para">Some Stuff</p>
      <p class="body-para">More Stuff</p>
      <p class="body-para">Even More Stuff</p>
      <ol>
        <li class="first-item odd">First</li>
        <li class="body-items even">Stuff A</li>
        <li class="body-items odd">Stuff B</li>
        <li class="body-items even">Stuff C</li>
        <li class="last-item odd">Last</li>
      </ol>
      <ul class="items">
        <li class="first">space</li>
        <li class="second">space</li>
      </ul>
      <p class="body-para">Even More stuff</p>
      <p class="last-para">Some Stuff</p>
    </div>
    <div id="blocks">
      <h2 class="h2-item">Sub Item</h2>
    </div>
    <ul id="people">
        <li class="name">name</li>
        <li class="email">email</li>
    </ul>
    <ul id="people2">
        <li class="name">name</li>
        <li class="email">email</li>
    </ul>
    <ul id="object">
        <li class="aa">AA</li>
        <li class="bb">BB</li>
    </ul>
    <p id="footer">Copyright 2222</p>
  </body>
</html>
HTML

## Stub for testing the fill method to be

ok my $title = sub {
  my ($z, $content) = @_;
  $z = $z->select('title')->replace_content($content);
  return $z;
};

{
  ok my $z = HTML::Zoom->new( { zconfig => { parser => 'HTML::Zoom::Parser::HH5P' } } )
    ->from_html(q[<ul><li>Test</li></ul>])
    ->select('ul')
    ->repeat_content(
      [
        sub { $_->select('li')->replace_content('Real Life1') },
        sub { $_->select('li')->replace_content('Real Life2') },
        sub { $_->select('li')->replace_content('Real Life3') },
      ],
    )
    ->to_html;

  is $z, '<ul><li>Real Life1</li><li>Real Life2</li><li>Real Life3</li></ul>',
    'Got correct from repeat_content';
}

{
  ok my $z = HTML::Zoom->new( { zconfig => { parser => 'HTML::Zoom::Parser::HH5P' } } )
    ->from_html(q[<ul><li>Test</li></ul>])
    ->select('ul')
    ->repeat_content([
      map { my $i = $_; +sub {$_->select('li')->replace_content("Real Life$i")} } (1,2,3)
    ])
    ->to_html;

  is $z, '<ul><li>Real Life1</li><li>Real Life2</li><li>Real Life3</li></ul>',
    'Got correct from repeat_content';
}


use HTML::Zoom::CodeStream;
sub code_stream (&) {
  my $code = shift;
  return sub {
    HTML::Zoom::CodeStream->new({
      code => $code,
    });
  }
}

{
  my @list = qw(foo bar baz);
  ok my $z = HTML::Zoom->new( { zconfig => { parser => 'HTML::Zoom::Parser::HH5P' } } )
    ->from_html(q[<ul><li>Test</li></ul>])
    ->select('ul')
    ->repeat_content(code_stream {
      if (my $name = shift @list) {
        return sub { $_->select('li')->replace_content($name) };
      } else {
        return
      }
    })
    ->to_html;
  
  is $z, '<ul><li>foo</li><li>bar</li><li>baz</li></ul>',
    'Got correct from repeat_content';
}

{
  my @list = qw(foo bar baz);
  ok my $z = HTML::Zoom->new( { zconfig => { parser => 'HTML::Zoom::Parser::HH5P' } } )
    ->from_html(q[<ul><li>Test</li></ul>])
    ->select('ul')
    ->repeat_content(sub {
      HTML::Zoom::CodeStream->new({
        code => sub {
          if (my $name = shift @list) {
            return sub { $_->select('li')->replace_content($name) };
          } else {
            return
          }
        }
      });
    })
    ->to_html;
  
  is $z, '<ul><li>foo</li><li>bar</li><li>baz</li></ul>',
    'Got correct from repeat_content';
}

done_testing;
