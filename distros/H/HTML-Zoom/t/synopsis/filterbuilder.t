use strictures 1;
use Test::More qw(no_plan);



use HTML::Zoom;
my $root = HTML::Zoom
    ->from_html(<<MAIN);
<html>
  <head>
    <title>Default Title</title>
  </head>
  <body bad_attr='junk'>
    Default Content
  </body>
</html>
MAIN



$root = $root
  ->select('body')
  ->set_attribute(class=>'main');



$root = $root
  ->select('body')
  ->add_to_attribute(class=>'one-column');



$root = $root
  ->select('title')
  ->replace_content('Hello World');



my $body = HTML::Zoom
    ->from_html(<<BODY);
<div id="stuff">
    <p>Well Now</p>
    <p id="p2">Is the Time</p>
</div>
BODY

$root = $root
  ->select('body')
  ->replace_content($body);



$root = $root
  ->select('p')
  ->set_attribute(class=>'para');



$root = $root
  ->select('body')
  ->remove_attribute('bad_attr');


my $output = $root->to_html;
my $expect = <<HTML;
<html>
  <head>
    <title>Hello World</title>
  </head>
  <body class="main one-column"><div id="stuff">
    <p class="para">Well Now</p>
    <p id="p2" class="para">Is the Time</p>
</div>
</body>
</html>
HTML
is($output, $expect, 'Synopsis code works ok');

