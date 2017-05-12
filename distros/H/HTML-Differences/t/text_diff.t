use strict;
use warnings;

use Test::More;

use HTML::Differences qw( html_text_diff );

{
    my $html1 = <<'EOF';
<!DOCTYPE html>
<html>
  <head>
    <title>Test1</title>
  </head>
  <body>
    <p>Paragraph</p>
  </body>
</html>
EOF

    ( my $html2 = $html1 ) =~ s/^ +//gm;

    is(
        html_text_diff( $html1, $html2 ),
        q{},
        'no diff between two HTML docs that only differ in whitespace'
    );
}

{
    my $html1 = <<'EOF';
<!DOCTYPE html>
<html>
  <head>
    <title>Test1</title>
  </head>
  <body>
    <p>Paragraph</p>
  </body>
</html>
EOF

    ( my $html2 = $html1 ) =~ s{</p>}{};

    like(
        html_text_diff( $html1, $html2 ),
        qr{\Q* 10|</p>             *   |                 |},
        'diff found when </p> closing tag is missing'
    );
}

{
    my $html1 = <<'EOF';
<!DOCTYPE html>
<html>
  <head>
    <title>Test1</title>
  </head>
  <body>
    <p>Paragraph</p>
  </body>
</html>
EOF

    ( my $html2 = $html1 ) =~ s{\Q<!DOCTYPE html>}{<!DOCTYPE html thingy>};

    like(
        html_text_diff( $html1, $html2 ),
        qr/\Q*  0|<!DOCTYPE html>  |<!DOCTYPE html thingy>  */,
        'diff found when doctype differs'
    );
}

{
    my $html1 = <<'EOF';
<!DOCTYPE html>
<html>
  <head>
    <title>Test1</title>
  </head>
  <body>
    <p>Paragraph</p>
  </body>
</html>
EOF

    ( my $html2 = $html1 ) =~ s{\Q<html>}{<html><! comment !>};

    like(
        html_text_diff( $html1, $html2 ),
        qr/\Q|   |                 *  2|<! comment !>    */,
        'diff found when comment differs'
    );

    is(
        html_text_diff( $html1, $html2, ignore_comments => 1 ),
        q{},
        'no diff found when comment differs and told to ignore comments'
    );
}

done_testing();
