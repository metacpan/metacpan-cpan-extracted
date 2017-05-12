use strictures 1;
use Test::More qw(no_plan);

use HTML::Zoom;
my $template = <<HTML;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd"> 
<html></html>
HTML

my $output = HTML::Zoom
  ->from_html($template)->to_html;
my $expect = <<HTML;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd"> 
<html></html>
HTML
is($output, $expect, 'Synopsis code works ok');;
