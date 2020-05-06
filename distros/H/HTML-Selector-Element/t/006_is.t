use Test::More;

use_ok('HTML::Selector::Element', qw(is));
require_ok('HTML::Tree');
ok(my $html = HTML::TreeBuilder->new_from_content(<<'__SNIPPET_1__'), 'parse using new_from_content');
<html><body><div class="container">
<div class="section"><p>Cold...</p></div>
<div class="section"><h1>Getting there...</h1><p id="goal">This is the goal</p></div>
</div></body></html>
__SNIPPET_1__
ok($html->can('is'), 'is is a method');
ok($el = $html->look_down(id => 'goal'), 'find by id');
ok(scalar $el->is('div.section > h1 + p'), 'is matched');

done_testing();