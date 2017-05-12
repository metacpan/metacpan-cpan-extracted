use strict;
use warnings FATAL => 'all';
use Test::More 'no_plan';

use HTML::Zoom;

my $template = <<HTML;
<html>
  <body></body>
</html>
HTML

my $expect = <<HTML;
<html>
  <body>Hello</body>
</html>
HTML

my $output = HTML::Zoom
  ->from_html($template)
  ->apply_if(1, sub { $_->select('body')->replace_content('Hello') })
  ->to_html;

is( $output => $expect, 'apply_if with a true predicate' );

$output = HTML::Zoom
  ->from_html($template)
  ->apply_if(0, sub { $_->select('body')->replace_content('Hello') })
  ->to_html;

is( $output => $template, 'apply_if with a false predicate' );
