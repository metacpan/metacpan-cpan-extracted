use Test::More;

require_ok('HTML::Selector::Element');
require_ok('HTML::Element');
@HTML::Element::Subclass::ISA = qw(HTML::Selector::Element::Trait HTML::Element);
ok(HTML::Element::Subclass->can('new_from_lol'), 'subclass of HTML::Element');
ok(HTML::Element::Subclass->can('look_self'), 'subclass of HTML::Selector::Element::Trait');
is(HTML::Element::Subclass->can('find'), HTML::Selector::Element::Trait->can('find'), 'overridden version of find');
isnt(HTML::Element::Subclass->can('find'), HTML::Element->can('find'), 'old version of find');
done_testing();
