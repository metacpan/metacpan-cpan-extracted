# CHANGES: added chomps because HTML::HTML5::Parser considers trailing
# whitespace (after </html>) to be part of the body text. Removed
# space character after the <!doctype> declaration.
#

use strictures 1;
use Test::More qw(no_plan);

use HTML::Zoom;
chomp(my $template = <<HTML);
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html></html>
HTML

my $output = HTML::Zoom->new( { zconfig => { parser => 'HTML::Zoom::Parser::HH5P' } } )
  ->from_html($template)->to_html;
chomp(my $expect = <<HTML);
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html></html>
HTML
is($output, $expect, 'Synopsis code works ok');;
