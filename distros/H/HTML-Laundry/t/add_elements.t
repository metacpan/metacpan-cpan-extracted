use strict;
use warnings;

use Test::More tests => 27;

require_ok('HTML::Laundry');
use HTML::Laundry::Rules;
my $rules = new HTML::Laundry::Rules;

my $l1 = HTML::Laundry->new({ notidy => 1 });
my $para = '<p>Sixteen years had <austen:footnote id="1">Miss Taylor</austen:footnote> been in Mr. Woodhouse\'s family, less as a governess than a friend, very fond of both daughters, but particularly of Emma.</p>';
is( $l1->clean($para), '<p>Sixteen years had Miss Taylor been in Mr. Woodhouse\'s family, less as a governess than a friend, very fond of both daughters, but particularly of Emma.</p>', 'Initial parsing strips unknown tag.');
my @acceptable = sort $l1->acceptable_elements;
my @original_acceptable = sort keys %{$rules->acceptable_e};
is_deeply( \@acceptable, \@original_acceptable, 'acceptable_elements() returns default Rules in list (not hash) form' );
$l1->add_acceptable_element('austen:footnote');
is( $l1->clean($para), $para, 'add_acceptable_element prevents parser (notidy) from stripping element');
$para = '<p>Between <em>them</em> it was more the intimacy of sisters.</p>';
is( $l1->clean($para), $para, 'Default parser recognizes <em> tag');
$l1->remove_acceptable_element( 'em' );
is( $l1->clean($para), '<p>Between them it was more the intimacy of sisters.</p>', 'remove_acceptable_element causes parser to strip known element');
$para = '<div><p>Even before Miss Taylor had ceased to hold the nominal office of governess, the mildness of her temper had hardly allowed her to impose any restraint...</p></div>';
$l1->remove_acceptable_element( ['p', 'div'] );
is( $l1->clean($para), 'Even before Miss Taylor had ceased to hold the nominal office of governess, the mildness of her temper had hardly allowed her to impose any restraint...',
    'remove_acceptable_element accepts listref' );
my $empty = '<plugh/>';
$l1->add_acceptable_element('plugh');
is( $l1->clean($empty), '<plugh></plugh>', 'Newly added element defaults to non-empty');
$l1->add_acceptable_element('plugh', { empty => 1 });
is( $l1->clean($empty), '<plugh />', 'Existing non-empty element may be switched to empty by add_acceptable_element argument');
$empty = '<plover/>';
$l1->add_acceptable_element('plover', { empty => 1 });
is( $l1->clean($empty), '<plover />', 'Newly added element can be marked empty with add_acceptable_element argument');
my $enchanter = '<filfre /><span /><blorb>small object</blorb><exex></exex><xyzzy />';
$l1->add_acceptable_element([ 'blorb', 'exex' ]);
is( $l1->clean($enchanter), '<span></span><blorb>small object</blorb><exex></exex>', 'add_acceptable_element accepts take listref');
$l1->add_acceptable_element([ 'filfre', 'xyzzy' ], { empty => 1 });
is( $l1->clean($enchanter), '<filfre /><span></span><blorb>small object</blorb><exex></exex><xyzzy />', 'add_acceptable_element accepts listref with empty argument');
$l1->acceptable_elements( [ 'filfre', 'blorb', 'xyzzy', 'bozbar', 'plugh' ] );
is( $l1->clean($enchanter), '<filfre /><blorb>small object</blorb><xyzzy />', 'acceptable_elements accepts listref argument');
my @new_acceptable = $l1->acceptable_elements;
ok( (scalar @new_acceptable == 5) && (grep {/^bozbar$/} @new_acceptable) && (! grep {/^p$/} @new_acceptable),
    'acceptable_elements replaces all acceptable elements when given listref');
$l1->remove_empty_element('plugh');
is ( $l1->clean('<plugh/>'), '<plugh></plugh>', 'remove_empty_element makes element non-empty but still acceptable');
$l1->remove_empty_element(['xyzzy', 'filfre']);
is( $l1->clean($enchanter), '<filfre></filfre><blorb>small object</blorb><xyzzy></xyzzy>', 'remove_empty_element accepts listref argument');

my $l2 = HTML::Laundry->new({ notidy => 1 });
$para = '<p>Between <em>them</em> it was more the intimacy of sisters.</p>';
is( $l2->clean($para), $para, 'Default parser recognizes <p> and <em> tags');
$l2->remove_acceptable_element('em');
is( $l2->clean($para), '<p>Between them it was more the intimacy of sisters.</p>', 'remove_acceptable_element accepts single tag');
$l2->remove_acceptable_element(['span', 'div']);
$para = "<span><div><blockquote>$para</blockquote></div></span>";
is( $l2->clean($para), '<blockquote><p>Between them it was more the intimacy of sisters.</p></blockquote>', 'remove_acceptable_element accepts listref');

my $tidy_available;
eval {
	require HTML::Tidy;
	$tidy_available = 1;
};
SKIP: {
	skip 'HTML::Tidy unavailable; skipping tidy tests', 8 unless ( $tidy_available );
    my $l3 = HTML::Laundry->new();
    my $para = q{<p>She had been a friend and <austen:footnote id="governess">companion</austen:footnote> such as few possessed: intelligent, well-informed, useful, gentle, knowing all the ways of the family, interested in all its concerns, and peculiarly interested in herself, in every pleasure, every scheme of hers--one to whom she could speak every thought as it arose, and who had such an affection for her as could never find fault.</p>};
    is( $l3->clean($para), q{<p>She had been a friend and companion such as few possessed: intelligent, well-informed, useful, gentle, knowing all the ways of the family, interested in all its concerns, and peculiarly interested in herself, in every pleasure, every scheme of hers--one to whom she could speak every thought as it arose, and who had such an affection for her as could never find fault.</p>}, q{Initial parsing with Tidy strips unknown tag.});
    $l3->add_acceptable_element('austen:footnote');
    is( $l3->clean($para), $para, q{Adding acceptable element inserts it into Tidy's acceptable list});
    $l3->add_acceptable_element('swanzo', { empty => 1 });
    is( $l3->clean(q[Magic word? <swanzo></swanzo>]),q[Magic word? <swanzo />], q[Adding empty element inserts it into Tidy's empty list]);
    is( $l3->clean(q[<austen:footnote><swanzo /></austen:footnote>]), q[<austen:footnote><swanzo /></austen:footnote>], 'New elements can nest');
    $l3->add_acceptable_element([ 'blorb', 'exex' ]);
    is( $l3->clean(q[<blorb><exex>1</exex></blorb>]), q[<blorb><exex>1</exex></blorb>], 'Adding new elements via listref inserts them into Tidy\'s acceptable list');
    is( $l3->clean(q[<austen:footnote><swanzo /></austen:footnote>]), q[<austen:footnote><swanzo /></austen:footnote>], 'Previously added new element is still available');
    $l3->add_acceptable_element([ 'plugh', 'plover' ], { empty => 1});
    is( $l3->clean(q[<p><plugh /><plover /></p>]), '<p><plugh /><plover /></p>', 'Adding new empty elements via listref inserts them into Tidy\'s empty list');
    is( $l3->clean(q[Magic word? <swanzo></swanzo>]), q[Magic word? <swanzo />], 'Previous empty element still available');
}
