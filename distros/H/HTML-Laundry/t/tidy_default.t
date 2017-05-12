use strict;
use warnings;

use Test::More tests => 20;
use Test::Exception;
use Encode;

require_ok('HTML::Laundry');

my $tidy_available = eval {
   require HTML::Tidy;
   1;
};

SKIP: {
    skip 'HTML::Tidy unavailable; skipping tidy tests', 19 unless $tidy_available;
    my $l = HTML::Laundry->new();
    is( $l->{tidy_engine}, q{HTML::Tidy}, 'HTML::Tidy is default tidying engine; sets tidy_engine key');
    my $plaintext = 'She was the youngest of the two daughters of a most affectionate, indulgent father...';
    is( $l->clean($plaintext), $plaintext, 'Short plain text passes through cleanly');
    $plaintext = q{She had been a friend and companion such as few possessed: intelligent, well-informed, useful, gentle, knowing all the ways of the family, interested in all its concerns, and peculiarly interested in herself, in every pleasure, every scheme of hers--one to whom she could speak every thought as it arose, and who had such an affection for her as could never find fault.};
    is( $l->clean($plaintext), $plaintext, 'Longer plain text passes through cleanly');

    TODO: {
        # HTML::Tidy 1.56 fixes unicode support
        local $TODO = "HTML::Tidy version dependent. Install HTML::Tidy 1.56 or greater"
            unless eval { HTML::Tidy->VERSION(1.56) };

        my $kurosawa_chars = Encode::encode('UTF-8', q[Akira Kurosawa (Kyūjitai: 黒澤 明, Shinjitai: 黒沢 明 Kurosawa Akira, 23 March 1910 – 6 September 1998) was a legendary Japanese filmmaker, producer, screenwriter and editor]);
        my $kurosawa_bytes = Encode::decode('UTF-8', $kurosawa_chars);
        is( $l->clean($kurosawa_chars), $kurosawa_bytes, 'UTF-8 text passes through cleanly');
    };

    my $valid = q{<p>} . $plaintext . q{</p>};
    is( $l->clean($valid), $valid, 'Validating HTML passes through cleanly');
    TODO: {
        local $TODO = "libtidy version dependent - figure out how to check";
        is( $l->clean('<div></div>'), q{}, 'No-content elements are stripped...');
        is( $l->clean('<div foo="bar"></div>'), q{<div id="foo"></div>}, '...unless they have attributes');
        my $para = q{<p>Sixteen years had Miss Taylor been in Mr. Woodhouse's family, less as a governess than a friend, very fond of both daughters, but particularly of Emma.</p>};
        is( $l->clean($para), $para, q{Single-quotes are preserved} );
    }
    is( $l->clean('<p></p>'), '<p></p>', 'Non-empty tag passes through cleanly');
    is( $l->clean('<br />'), '<br />', 'Empty tag passes through cleanly');
    is( $l->clean('<br /   >'), '<br />', 'Empty tag with whitespace passes through cleanly');
    is( $l->clean('<p />'), '<p></p>', 'Non-empty tag passed in as empty is normalized to non-empty format');
    is( $l->clean('<br></br>'), '<br />', 'Empty tag passed in as non-empty is normalized to empty format');
    is( $l->clean('<br class="foo" />'), '<br class="foo" />', 'Empty tag attribute is preserved');
    is( $l->clean('<p class="foo"></p>'), '<p class="foo"></p>', 'Non-empty tag attribute is preserved');
    # Actual tidying begins
    is( $l->clean('<em><strong>Important!'), '<em><strong>Important!</strong></em>', 'Unclosed tags are closed');
    is( $l->clean('<p><strong>Important!</p></strong>'), '<p><strong>Important!</strong></p>', 'Transposed close tags are fixed');
    is( $l->clean('<p>P1</p><p>P2</p>'), "<p>P1</p>\n<p>P2</p>", 'Line breaks are inserted between block tags');
    is( $l->clean('<li>Buy milk</li><li>Pick up dry cleaning</li>'), "<ul>\n<li>Buy milk</li>\n<li>Pick up dry cleaning</li>\n</ul>", 'Naked <li> tags are given <ul> wrapper');
}


