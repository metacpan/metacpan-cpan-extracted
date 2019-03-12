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
        $hr->process(
            '<<input>div onmouseover="alert(1);">hover over me<<input>/div>'),
        '&lt;div onmouseover="alert(1);"&gt;hover over me&lt;/div&gt;',
        'malformed HTML is correctly cleaned'
    );
}

{
    my $hr = HTML::Restrict->new;
    is(
        $hr->process(
            '&<input></input>lt; &theta; &aMp; &#50; &#x50; &#xabg;'),
        '&amp;lt; &theta; &aMp; &#50; &#x50; &#xab;g;',
        'badly encoded entities corrected'
    );
}

done_testing();
