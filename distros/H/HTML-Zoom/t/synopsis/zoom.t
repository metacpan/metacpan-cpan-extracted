use strictures 1;
use Test::More qw(no_plan);

use HTML::Zoom;

my $template = <<HTML;
<html>
  <head>
    <title>Hello people</title>
  </head>
  <body>
    <h1 id="greeting">Placeholder</h1>
    <div id="list">
      <span>
        <p>Name: <span class="name">Bob</span></p>
        <p>Age: <span class="age">23</span></p>
      </span>
      <hr class="between" />
    </div>
  </body>
</html>
HTML

my $output = HTML::Zoom
  ->from_html($template)
  ->select('title, #greeting')->replace_content('Hello world & dog!')
  ->select('#list')->repeat_content(
      [
        sub {
          $_->select('.name')->replace_content('Matt')
            ->select('.age')->replace_content('26')
        },
        sub {
          $_->select('.name')->replace_content('Mark')
            ->select('.age')->replace_content('0x29')
        },
        sub {
          $_->select('.name')->replace_content('Epitaph')
            ->select('.age')->replace_content('<redacted>')
        },
      ],
      { repeat_between => '.between' }
    )
  ->to_html;


my $expect = <<HTML;
<html>
  <head>
    <title>Hello world &amp; dog!</title>
  </head>
  <body>
    <h1 id="greeting">Hello world &amp; dog!</h1>
    <div id="list">
      <span>
        <p>Name: <span class="name">Matt</span></p>
        <p>Age: <span class="age">26</span></p>
      </span>
      <hr class="between" />
      <span>
        <p>Name: <span class="name">Mark</span></p>
        <p>Age: <span class="age">0x29</span></p>
      </span>
      <hr class="between" />
      <span>
        <p>Name: <span class="name">Epitaph</span></p>
        <p>Age: <span class="age">&lt;redacted&gt;</span></p>
      </span>
      
    </div>
  </body>
</html>
HTML
is($output, $expect, 'Synopsis code works ok');

