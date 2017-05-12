use strictures 1;
use HTML::Zoom;
use Test::More skip_all => "Totally doesn't work yet";

# Test that contant of elements defined as containing intrinsic CDATA are not
# selected as elements

# NB: This tests HTML parsing rules. XHTML is different.

my $template = <<HTML;
<!DOCTYPE html>
<html lang=en-gb>
    <meta charset=utf-8>
    <title>Test</title>
    <style>
        /* <textarea>Unmodified</textarea> */
    </style>
    </head>
    <body>
        <p>Unmodified</p>
        <textarea>Unmodified</textarea>
        <script>
            if (1) {
                document.write('<p>');
            } else {
                document.write('<div>');
            }
            document.write('hello, world');
            if (1) {
                document.write('</p>');
            } else {
                document.write('</div>');
            }
        </script>
HTML

my $expected_p = <<HTML;
<!DOCTYPE html>
<html lang=en-gb>
    <meta charset=utf-8>
    <title>Test</title>
    <style>
        /* <textarea>Unmodified</textarea> */
    </style>
    </head>
    <body>
        <p>Unmodified</p>
        <textarea>Unmodified</textarea>
        <script>
            if (1) {
                document.write('<p>');
            } else {
                document.write('<div>');
            }
            document.write('hello, world');
            if (1) {
                document.write('</p>');
            } else {
                document.write('</div>');
            }
        </script>
HTML

my $expected_t = <<HTML;
<!DOCTYPE html>
<html lang=en-gb>
    <meta charset=utf-8>
    <title>Test</title>
    <style>
        /* <textarea>Unmodified</textarea> */
    </style>
    </head>
    <body>
        <p>Unmodified</p>
        <textarea>Replaced</textarea>
        <script>
            if (1) {
                document.write('<p>');
            } else {
                document.write('<div>');
            }
            document.write('hello, world');
            if (1) {
                document.write('</p>');
            } else {
                document.write('</div>');
            }
        </script>
HTML

my $replaced_p = HTML::Zoom->from_html($template)->select('p')->replace_content('Replaced')->to_html;
is($replaced_p, $expected_p, "Script element parsed as CDATA");

my $replaced_t = HTML::Zoom->from_html($template)->select('textarea')->replace_content('Replaced')->to_html;
is($replaced_t, $expected_t, "Style element parsed as CDATA");

done_testing;
