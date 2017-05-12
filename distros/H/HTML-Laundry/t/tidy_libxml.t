use strict;
use warnings;

use Test::More tests => 14;

require_ok('HTML::Laundry');
my $tidy_libxml_available;

{
    local $@;
    eval {
        require HTML::Tidy::libXML;
        $tidy_libxml_available = 1;
    };
}

SKIP: {
    skip 'HTML::Tidy::libXML unavailable; skipping tests', 13 unless ( $tidy_libxml_available );
    {
        local $@;
        eval {
            no warnings 'redefine';
            no warnings 'once';
            require HTML::Tidy;
            *HTML::Tidy::new = sub { return 0; };
        };
    }
    my $l = HTML::Laundry->new();
    is( $l->{tidy_engine}, q{HTML::Tidy::libXML},
        'Laundry uses HTML::Tidy::libXML as tidying engine if HTML::Tidy is unavailable'
        );
    my $plaintext = 'She was the youngest of the two daughters of a most affectionate, indulgent father...';
    is( $l->clean($plaintext), $plaintext, 'Short plain text passes through cleanly');
    $plaintext = q{She had been a friend and companion such as few possessed: intelligent, well-informed, useful, gentle, knowing all the ways of the family, interested in all its concerns, and peculiarly interested in herself, in every pleasure, every scheme of hers--one to whom she could speak every thought as it arose, and who had such an affection for her as could never find fault.};
    is( $l->clean($plaintext), $plaintext, 'Longer plain text passes through cleanly');
    my $kurosawa = q[Akira Kurosawa (Kyūjitai: 黒澤 明, Shinjitai: 黒沢 明 Kurosawa Akira, 23 March 1910 – 6 September 1998) was a legendary Japanese filmmaker, producer, screenwriter and editor];
    is( $l->clean($kurosawa), $kurosawa, 'UTF-8 text passes through cleanly');
    my $valid = q{<p>} . $plaintext . q{</p>};
    is( $l->clean($valid), $valid, 'Validating HTML passes through cleanly');
    is( $l->clean('<p></p>'), '<p/>', 'libXML collapses no-content paragraph tags to empty element');
    is( $l->clean('<br />'), '<br/>', 'Empty tag passes through cleanly');
    is( $l->clean('<br /   >'), '<br/>', 'Empty tag with whitespace passes through cleanly');
    is( $l->clean('<br></br>'), '<br/>', 'Empty tag passed in as non-empty is normalized to empty format');
    is( $l->clean('<br class="foo" />'), '<br class="foo"/>', 'Empty tag attribute is preserved');
    is( $l->clean('<p class="foo"></p>'), '<p class="foo"/>', 'Non-empty tag attribute is preserved');
    # Actual tidying begins
    is( $l->clean('<em><strong>Important!'), '<em><strong>Important!</strong></em>', 'Unclosed tags are closed');
    is( $l->clean('<p><strong>Important!</p></strong>'), '<p><strong>Important!</strong></p>', 'Transposed close tags are fixed');
}


