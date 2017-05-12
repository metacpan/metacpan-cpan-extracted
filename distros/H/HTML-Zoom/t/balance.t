use strictures 1;
use Test::More;
use HTML::Zoom;

my $z = HTML::Zoom->from_html(q{<html>
  <body>
    <div class="outer">
      <div class="inner"><span /></div>
    </div>
  </body>
</html>});

is(
  $z->select('.outer')
    ->collect_content({
       filter => sub { $_->select('.inner')->replace_content('bar!') },
       passthrough => 1
      })
    ->to_html,
  q{<html>
  <body>
    <div class="outer">
      <div class="inner">bar!</div>
    </div>
  </body>
</html>},
  "filter within collect works ok"
);

done_testing;
