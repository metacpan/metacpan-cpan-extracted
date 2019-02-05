use strict;
use warnings;

use Test::Fatal qw( exception );
use Test::More;

use HTML::Restrict;

# Behaviour as of 2.3.0 is for
# <<input>div onmouseover="alert(1);">hover over me<<input>/div>
# to get pared down to
# <div onmouseover="alert(1);">hover over me</div>
# with a subsequent call to process() returning
# hover over me

# So, malformed HTML is actually being turned into valid HTML on the first pass
# and the tags are not being stripped. This is a regression test for fixing the
# issue noted above.

my $html = '<<input>div onmouseover="alert(1);">hover over me<<input>/div>';

{
    my $hr = HTML::Restrict->new;
    is(
        $hr->process($html), 'hover over me',
        'malformed HTML is correctly cleaned'
    );
}

{
    my $attempts = 2;
    my $hr       = HTML::Restrict->new( max_parser_loops => $attempts );
    like(
        exception { $hr->process($html) },
        qr/after $attempts attempts/,
        'dies after max loops exceeded',
    );
    $hr->max_parser_loops(3);
    is( $hr->process('<foo>bar'), 'bar', 'can parse after caught exception' );
}

{
    for my $i ( -1 .. 1 ) {
        like(
            exception { HTML::Restrict->new( max_parser_loops => $i ) },
            qr/did not pass type constraint/i,
            'max_parser_loops cannot be ' . $i,
        );
    }
}

done_testing();
