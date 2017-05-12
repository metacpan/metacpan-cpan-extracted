#!/usr/bin/perl

use strict;
use warnings;

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 5;

BEGIN
{
    use_ok('HTML::Strip::Whitespace', "html_strip_whitespace"); # TEST
}

sub get_html
{
    my $source = shift;
    my $buffer = "";
    html_strip_whitespace(
        'source' => \$source,
        'out' => \$buffer,
        @_
        );
    return $buffer;
}


{
    my $in = "<html><body><p>Hello world!</p></body></html>";

    my $expected_with_newlines = $in;

    my $expected_wo_newlines = $in;

    my $result_with_newlines = get_html($in, 'strip_newlines' => 0);
    my $result_wo_newlines = get_html($in, 'strip_newlines' => 1);

    # TEST
    is($result_with_newlines, $expected_with_newlines, "Do Nothing - w Newlines");

    # is($result_wo_newlines, $expected_wo_newlines, "Do Nothing - wo Newlines");
}

{
    my $in = <<"EOF";
<html>
    <body>
        <p>
        Hello world!
        </p>
    </body>
</html>
EOF

    my $expected_with_newlines = <<"EOF";
<html>
<body>
<p>
Hello world!
</p>
</body>
</html>
EOF

    my $expected_wo_newlines = <<"EOF";
<html><body><p>Hello world!</p></body></html>
EOF

    my $result_with_newlines = get_html($in, 'strip_newlines' => 0);
    my $result_wo_newlines = get_html($in, 'strip_newlines' => 1);

    # TEST
    is($result_with_newlines, $expected_with_newlines, "Simple Test #1 - w Newlines");
    # is($result_wo_newlines, $expected_wo_newlines, "Simple Test #1 - wo Newlines");
}


{
    my $in = <<"EOF";
<html>
<body>
<p>Hello world!</p>
</body>
</html>
EOF

    my $expected_with_newlines = $in;

    my $expected_wo_newlines = $in;
    $expected_wo_newlines =~ s/\n//g;

    my $result_with_newlines = get_html($in, 'strip_newlines' => 0);
    my $result_wo_newlines = get_html($in, 'strip_newlines' => 1);

    # TEST
    is($result_with_newlines, $expected_with_newlines, "Simple #1 - w Newlines");

    # is($result_wo_newlines, $expected_wo_newlines, "Simple #2 - wo Newlines");
}

{
    my $in = <<"EOF";
<html>
    <body>
        <p>
        Hello world!
        </p>
        <pre>
Hello y'all! <b>Good</b>
        </pre>
    </body>
</html>
EOF

    my $expected_with_newlines = <<"EOF";
<html>
<body>
<p>
Hello world!
</p>
<pre>
Hello y'all! <b>Good</b>
        </pre>
</body>
</html>
EOF

    my $expected_wo_newlines = <<"EOF";
<html><body><p>Hello world!</p><pre>
Hello y'all! <b>Good</b>
        </pre></body></html>
EOF

    my $result_with_newlines = get_html($in, 'strip_newlines' => 0);
    my $result_wo_newlines = get_html($in, 'strip_newlines' => 1);

    # TEST
    is($result_with_newlines, $expected_with_newlines,  "Pre Test #1 - w Newlines");

    # is($result_wo_newlines, $expected_wo_newlines, "Pre Test #1 - wo Newlines");
}

