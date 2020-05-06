use Test::More;

use_ok('HTML::Selector::Element', qw(find));
require_ok('HTML::Tree');
ok(my $html = HTML::TreeBuilder->new_from_content(<<'__SNIPPET_1__'), 'parse using new_from_content');
<html><body><div class="container">
<div class="section"><p>Cold...</p></div>
<div class="section"><h1>Getting there...</h1><p id="goal">This is the goal</p></div>
</div></body></html>
__SNIPPET_1__
is($html->can('find'), HTML::Selector::Element::Trait->can('find'), 'find is our own method');
ok(my $s = HTML::Selector::Element->new('div.section > h1 + p'), 'selector object');
ok(my $el = $s->find($html), 'flipped find');
is($el, scalar $html->look_down(id => 'goal'), 'found using flipped find');
is(scalar $html->find('div.section > h1 + p')->{id}, 'goal', 'found using normal find');
ok($s->{find}, 'cached criteria');
ok(my $s2 = HTML::Selector::Element->new('> h1'), 'selector child');
ok(my $el2 = $s2->find($el->{_parent}), 'find child found something');
is(scalar $el2->right,  $el, 'find child worked');
ok(my $s3 = HTML::Selector::Element->new('+ p'), 'selector next sibling');
ok(my $el3 = $s3->find($el2), 'find next sibling found something');
is($el3,  $el, 'find next sibling worked');
ok(my $s4 = HTML::Selector::Element->new('~ p'), 'selector a sibling');
ok(my $el4 = $s3->find($el2), 'find a sibling found something');
is($el4,  $el, 'find a sibling worked');

done_testing();