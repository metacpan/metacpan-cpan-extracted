use strict;
use warnings;

use Test::More tests => 9;

require_ok('HTML::Laundry');
use HTML::Laundry::Rules;

my $l1 = HTML::Laundry->new({ notidy => 1 });
my $script = '<p>Hello.</p><script>alert("Ha ha ha")</script>';
is( $l1->clean($script), '<p>Hello.</p>', 'Initial parsing treats script as unacceptable' );
my @unacceptable = sort $l1->unacceptable_elements;
my $rules = new HTML::Laundry::Rules;
my @original_unacceptable = sort keys %{$rules->unacceptable_e};
is_deeply( \@unacceptable, \@original_unacceptable, 'unacceptable_elements() returns default Rules in list (not hash) form' );
$l1->add_unacceptable_element('p');
is( $l1->clean($script), '', 'add_unacceptable_element accepts single attribute');
$l1->add_unacceptable_element(['div', 'span']);
is( $l1->clean('<div>foo</div><span>bar</span>'), '', 'add_unacceptable_element accepts listref');
$l1->remove_unacceptable_element('script');
is( $l1->clean('<script>alert("Ha ha ha");</script><div>foo</div><span>bar</span><p>baz</p>'), 'alert(&quot;Ha ha ha&quot;);',
    'remove_unacceptable_element accepts single element but does not make it acceptable');
$l1->remove_unacceptable_element(['div','span']);
is( $l1->clean('<script>alert("Ha ha ha");</script><div>foo</div><span>bar</span><p>baz</p>'), 'alert(&quot;Ha ha ha&quot;);foobar',
    'remove_unacceptable_element accepts listref but does not make any elements acceptable');
$l1->unacceptable_elements(['ol','plugh','plover','gaspar','cleesh']);
my @new_unacceptable = $l1->unacceptable_elements;
ok( (scalar @new_unacceptable == 5 && grep {/^gaspar$/} @new_unacceptable),
    'unacceptable_elements replaces all unacceptable elements when given listref');
my @acceptable = $l1->acceptable_elements;
ok( ! ( grep {/^ol$/} @acceptable ), 'giving unacceptable_elements new listref removes new items from acceptable elements');
