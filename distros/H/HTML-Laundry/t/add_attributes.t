use strict;
use warnings;

use Test::More tests => 8;

use FindBin;
use lib "$FindBin::RealBin/lib";
use TestHelpers;

require_ok('HTML::Laundry');
use HTML::Laundry::Rules;
my $rules = new HTML::Laundry::Rules;

my $l1 = HTML::Laundry->new({ notidy => 1 });
my $para = '<p class="austen" novel="emma">Sixteen years had Miss Taylor been in Mr. Woodhouse\'s family, less as a governess than a friend, very fond of both daughters, but particularly of Emma.</p>';
is( $l1->clean($para), '<p class="austen">Sixteen years had Miss Taylor been in Mr. Woodhouse\'s family, less as a governess than a friend, very fond of both daughters, but particularly of Emma.</p>', 'Initial parsing strips unknown attribute.');
my @acceptable = sort $l1->acceptable_attributes;
my @original_acceptable = sort keys %{$rules->acceptable_a};
is_deeply( \@acceptable, \@original_acceptable, 'acceptable_attributes() returns default Rules in list (not hash) form' );
$l1->add_acceptable_attribute('novel');
TestHelpers::eq_or_diff_html( $l1->clean($para), $para, 'add_acceptable_attribute accepts single attribute');
$l1->add_acceptable_attribute(['magic_word','game']);
my $adventure = '<div game="adventure"><p plugh="plover" magic_word="xyzzy">Nothing happens.</p></div>';
is( $l1->clean($adventure), '<div game="adventure"><p magic_word="xyzzy">Nothing happens.</p></div>', 'add_acceptable_attribute accepts listref');
$l1->remove_acceptable_attribute('href');
is( $l1->clean('<a href="http://example.com" name="bar">foo</a>'), '<a name="bar">foo</a>', 'remove_acceptable_attribute accepts single attribute');
$l1->remove_acceptable_attribute(['id','class']);
is( $l1->clean('<br id="foo" class="bar" />'), '<br />', 'remove_acceptable_attribute accepts listref');
$l1->acceptable_attributes(['filfre', 'blorb', 'bozbar']);
my @new_attributes = $l1->acceptable_attributes;
ok( (scalar @new_attributes == 3 && grep {/^bozbar$/} @new_attributes),
    'acceptable_elements replaces all acceptable elements when given listref');
