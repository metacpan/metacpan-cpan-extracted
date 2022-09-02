use strict; use warnings;
use HTML::Tiny;
use Test::More tests => 18;

ok my $h = HTML::Tiny->new, 'Create succeeded';
ok my $h_html = HTML::Tiny->new( mode => 'html' ),
 'Create succeeded (mode HTML)';

common_checks( $h );
common_checks( $h_html, ' (mode HTML)' );

is $h->stringify( [ \'br' ] ), '<br />', 'br OK';
is $h->stringify( [ \'input', { name => 'myfield', type => 'text' } ] ),
 '<input name="myfield" type="text" />', 'input OK';
is $h->stringify( [ \'img', { src => 'pic.jpg' } ] ),
 '<img src="pic.jpg" />',
 'img OK';

is $h_html->stringify( [ \'br' ] ), '<br>', 'br OK (mode HTML)';
is $h_html->stringify(
  [ \'input', { name => 'myfield', type => 'text' } ]
 ),
 '<input name="myfield" type="text">', 'input OK (mode HTML)';
is $h_html->stringify( [ \'img', { src => 'pic.jpg' } ] ),
 '<img src="pic.jpg">', 'img OK (mode HTML)';

sub common_checks {
  my $h = shift;
  my $mode = shift || '';

  is $h->stringify( [ \'p', 'hello, world' ] ),
   "<p>hello, world</p>\n",
   'p OK' . $mode;

  is $h->stringify(
    [
      \'a', { href => 'http://hexten.net', title => 'Hexten' },
      'Hexten'
    ]
   ),
   '<a href="http://hexten.net" title="Hexten">Hexten</a>',
   'a OK' . $mode;

  is $h->stringify( [ \'textarea' ] ), '<textarea></textarea>',
   'empty tag OK' . $mode;

  is $h->stringify(
    [
      \'table',
      [
        \'tr',
        [ \'th', 'Name',     'Score', 'Position' ],
        [ \'td', 'Therese',  90,      1 ],
        [ \'td', 'Chrissie', 85,      2 ],
        [ \'td', 'Andy',     50,      3 ]
      ]
    ]
   ),
   "<table><tr><th>Name</th><th>Score</th><th>Position</th></tr>\n"
   . "<tr><td>Therese</td><td>90</td><td>1</td></tr>\n"
   . "<tr><td>Chrissie</td><td>85</td><td>2</td></tr>\n"
   . "<tr><td>Andy</td><td>50</td><td>3</td></tr>\n"
   . "</table>\n", 'table OK' . $mode;

  is $h->stringify(
    [
      \'html',
      [
        [ \'head', [ \'title', 'Sample page' ] ],
        [
          \'body',
          [
            [ \'h1', { class => 'main' }, 'Sample page' ],
            [
              \'p',
              'Hello, World',
              { class => 'detail' },
              'Second para'
            ]
          ]
        ]
      ]
    ]
   ),
   "<html><head><title>Sample page</title>"
   . "</head>\n<body><h1 class=\"main\">Sample page</h1>"
   . "<p>Hello, World</p>\n<p class=\"detail\">Second para</p>\n"
   . "</body>\n</html>\n", 'complex HTML OK' . $mode;
}

