#! perl -w
use Test::More;

use_ok('HTML::Selector::Element', qw(!DEFAULT));
ok(HTML::Element->can('is'), 'HTML::Element is monkeypatched');
is(HTML::Element->can('find'), HTML::Selector::Element::Trait->can('find'), 'overwritten version of find');

done_testing();
