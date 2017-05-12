use strict;
use warnings FATAL => 'all';

use HTML::Zoom;
use Test::More;

ok my $zoom = HTML::Zoom->new( { zconfig => { parser => 'HTML::Zoom::Parser::HH5P' } } )
    ->from_html(<<HTML);
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

ok ! eval { $zoom->non_method('.first-param' => 'First!'); 1},
  'Properly die on bad method';

ok my $title = sub {
  my ($z, $content) = @_;
  $z = $z->replace_content(title =>$content);
  return $z;
};

ok my $dwim = $zoom
  ->$title('Hello NYC')
  ->replace_content('.first-para' => 'First!')
  ->replace_content('.last-para' => 'Last!')
  ->add_to_attribute('p', class => 'para')
  ->prepend_content('.first-item' => [{type=>'TEXT', raw=>'FIRST: '}])
  ->prepend_content('.last-item' => [{type=>'TEXT', raw=>'LAST: '}])
  ->replace_content('title' => 'Hello World')
  ->repeat_content(
    '.items' => [ 
      map { 
        my $v = $_;
        sub {
          $_->replace_content('.first' => $v)
            ->replace_content('.second' => $v);
        },
      } (111,222)
    ]
  )
  ->to_html;

like(
  HTML::Zoom->new( { zconfig => { parser => 'HTML::Zoom::Parser::HH5P' } } )
    ->from_html(q[<title>Hi!</title>])
    ->$title('Hello NYC')
    ->to_html,
  qr/Hello NYC/,
  'Got correct title(custom subref)'
);

like(
  HTML::Zoom->new( { zconfig => { parser => 'HTML::Zoom::Parser::HH5P' } } )
    ->from_html(q[<p>Hi!</p>])
    ->replace_content(p=>'Ask not what your country can do for you...')
    ->to_html,
  qr/Ask not what your country can do for you\.\.\./,
  'Got correct from replace_content'
);

like(
  HTML::Zoom->new( { zconfig => { parser => 'HTML::Zoom::Parser::HH5P' } } )
    ->from_html(q[<p class="first">Hi!</p>])
    ->add_to_attribute('p', class => 'para')
    ->to_html,
  qr/first para/,
  'Got correct from add_to_attribute'
);

like(
  HTML::Zoom->new( { zconfig => { parser => 'HTML::Zoom::Parser::HH5P' } } )
    ->from_html(q[<p class="first">Hi!</p>])
    ->add_to_attribute('p', class => 'para')
    ->to_html,
  qr/first para/,
  'Got correct from add_to_attribute'
);

like(
  HTML::Zoom->new( { zconfig => { parser => 'HTML::Zoom::Parser::HH5P' } } )
    ->from_html(q[<p class="first">Hi!</p>])
    ->set_attribute('p', class => 'para')
    ->to_html,
  qr/class="para"/,
  'Got correct from set_attribute'
);

like(
  HTML::Zoom->new( { zconfig => { parser => 'HTML::Zoom::Parser::HH5P' } } )
    ->from_html(q[<p class="first">Hi!</p>])
    ->set_attribute('p', class => 'para')
    ->to_html,
  qr/class="para"/,
  'Got correct from set_attribute'
);

is(
  HTML::Zoom->new( { zconfig => { parser => 'HTML::Zoom::Parser::HH5P' } } )
    ->from_html(q[<p class="first">Hi!</p>])
    ->add_before(p=>[{type=>'TEXT', raw=>'added before'}])
    ->to_html,
  'added before<p class="first">Hi!</p>',
  'Got correct from add_before'
);

is(
  HTML::Zoom->new( { zconfig => { parser => 'HTML::Zoom::Parser::HH5P' } } )
    ->from_html(q[<p class="first">Hi!</p>])
    ->add_after(p=>[{type=>'TEXT', raw=>'added after'}])
    ->to_html,
  '<p class="first">Hi!</p>added after',
  'Got correct from add_after'
);

is(
  HTML::Zoom->new( { zconfig => { parser => 'HTML::Zoom::Parser::HH5P' } } )
    ->from_html(q[<p class="first">Hi!</p>])
    ->prepend_content(p=>[{type=>'TEXT', raw=>'prepend_content'}])
    ->to_html,
  '<p class="first">prepend_contentHi!</p>',
  'Got correct from prepend_content'
);

is(
  HTML::Zoom->new( { zconfig => { parser => 'HTML::Zoom::Parser::HH5P' } } )
    ->from_html(q[<p class="first">Hi!</p>])
    ->append_content(p=>[{type=>'TEXT', raw=>'append_content'}])
    ->to_html,
  '<p class="first">Hi!append_content</p>',
  'Got correct from append_content'
);

{
    my @body;
    ok my $body = HTML::Zoom->new( { zconfig => { parser => 'HTML::Zoom::Parser::HH5P' } } )
      ->from_html(q[<div>My Stuff Is Here</div>])
      ->collect_content(div => { into => \@body, passthrough => 1})
      ->to_html, 'Collected Content';

    is $body, "<div>My Stuff Is Here</div>", "Got expected";

    is(
      HTML::Zoom->from_events(\@body)->to_html,
      'My Stuff Is Here',
      'Collected the right stuff',
    );
}

like(
  HTML::Zoom->new( { zconfig => { parser => 'HTML::Zoom::Parser::HH5P' } } )
    ->from_html(q[<ul class="items"><li class="first">first</li><li class="second">second</li></ul>])
    ->repeat_content(
      '.items' => [ 
        map { 
          my $v = $_;
          sub {
            $_->replace_content('.first' => $v)
              ->replace_content('.second' => $v);
          },
        } (111,222)
      ]
    )
    ->to_html,
  qr[<ul class="items"><li class="first">111</li><li class="second">111</li><li class="first">222</li><li class="second">222</li></ul>],
  'Got correct list'
);

{
  ok my $z = HTML::Zoom->new( { zconfig => { parser => 'HTML::Zoom::Parser::HH5P' } } )
    ->from_html(q[<div>Life, whatever</div><p class="first">Hi!</p>])
    ->add_before(p=>'added before');

  is $z->to_html, '<div>Life, whatever</div>added before<p class="first">Hi!</p>',
    'Got correct from add_before';
}

{
  ok my $z = HTML::Zoom->new( { zconfig => { parser => 'HTML::Zoom::Parser::HH5P' } } )
    ->from_html(q[<div>Life, whatever</div><p class="first">Hi!</p>])
    ->add_after(p=>'added after');

  is $z->to_html, '<div>Life, whatever</div><p class="first">Hi!</p>added after',
    'Got correct from add_after';
}

{
  ok my $z = HTML::Zoom->new( { zconfig => { parser => 'HTML::Zoom::Parser::HH5P' } } )
    ->from_html(q[<div>Life, whatever</div><p class="first">Hi!</p>])
    ->append_content(p=>'appended');

  is $z->to_html, '<div>Life, whatever</div><p class="first">Hi!appended</p>',
    'Got correct from append_content';
}

{
  ok my $z = HTML::Zoom->new( { zconfig => { parser => 'HTML::Zoom::Parser::HH5P' } } )
    ->from_html(q[<div>Life, whatever</div><p class="first">Hi!</p>])
    ->prepend_content(p=>'prepended');
    

  is $z->to_html, '<div>Life, whatever</div><p class="first">prependedHi!</p>',
    'Got correct from prepend_content';
}

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
