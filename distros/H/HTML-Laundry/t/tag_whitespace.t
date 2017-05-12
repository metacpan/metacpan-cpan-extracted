use strict;
use warnings;

use Test::More tests => 5;

require_ok('HTML::Laundry');
TODO: {
    local $TODO = q{Create ruleset to activate trim_tag_whitespace};
    my $l1 = HTML::Laundry->new({ notidy => 1 });
    my $whitespace = "< p >Emma Woodhouse, handsome, clever, and rich, with a comfortable home and happy disposition, seemed to unite some of the best blessings of existence; and had lived nearly twenty-one years in the world with very little to distress or vex her.< / p >";
    is ( $l1->clean($whitespace), "<p>Emma Woodhouse, handsome, clever, and rich, with a comfortable home and happy disposition, seemed to unite some of the best blessings of existence; and had lived nearly twenty-one years in the world with very little to distress or vex her.</p>",
        'Laundry w/trim option handles whitespace in non-empty tags');
    $whitespace = "<             br      id=\"xyzzy\"      /                          >";
    is ( $l1->clean($whitespace), '<br id="xyzzy" />', 'Laundry w/trim option handles leading and trailing whitespace in empty tags');
    $whitespace = "<
    p
    >Emma Woodhouse, handsome, clever, and rich, with a comfortable home and happy disposition, seemed to unite some of the best blessings of existence; and had lived nearly twenty-one years in the world with very little to distress or vex her.<
    /
    p
    >";
    is ( $l1->clean($whitespace),
        "<p>Emma Woodhouse, handsome, clever, and rich, with a comfortable home and happy disposition, seemed to unite some of the best blessings of existence; and had lived nearly twenty-one years in the world with very little to distress or vex her.</p>",
        'Laundry w/trim option handles vertical whitespace in non-empty tags');
    $whitespace = "<



        br

        id=\"xyzzy\"
        /
        >";
    is ( $l1->clean($whitespace), "<br id=\"xyzzy\" />", 'Laundry w/trim option handles leading and trailing vertical whitespace in empty tags');
}
