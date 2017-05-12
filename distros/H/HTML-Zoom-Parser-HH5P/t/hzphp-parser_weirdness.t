use strictures 1;
use HTML::Zoom;
use Test::More skip_all => 'TODO';
{
my $html = <<EOHTML;
<body>
  <p><br/></p>
  <p><br /></p>
</body>
EOHTML

HTML::Zoom->from_html($html)
          ->select('body')
          ->collect_content({
              into => \my @body
            })
          ->run;

is(HTML::Zoom->from_events(\@body)->to_html, <<EOHTML,

  <p><br/></p>
  <p><br /></p>
EOHTML
  'Parses cuddled in place close ok');
}

{
my $html = <<EOHTML;
<body>
  <p><br/></p>
  <p><br /></p>
</body>
EOHTML

HTML::Zoom->new( { zconfig => { parser => 'HTML::Zoom::Parser::HH5P' } } )->from_html($html)
          ->select('body')
          ->collect_content({
              into => \my @body
            })
          ->run;

is(HTML::Zoom->new( { zconfig => { parser => 'HTML::Zoom::Parser::HH5P' } } )->from_events(\@body)->to_html, <<EOHTML,

  <p><br/></p>
  <p><br /></p>
EOHTML
  'Parses cuddled in place close ok');
}


done_testing;
