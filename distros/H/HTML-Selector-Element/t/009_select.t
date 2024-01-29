use Test::More;

use_ok('HTML::Selector::Element', qw(select));
require_ok('HTML::Tree');
ok(my $html = HTML::TreeBuilder->new_from_content(<<'__SNIPPET_1__'), 'parse using new_from_content');
<html><body><div class="container">
<div class="section"><p>Cold...</p></div>
<div class="section"><h1>Getting there...</h1><p id="goal">This is the goal</p></div>
</div></body></html>
__SNIPPET_1__
is($html->can('select'), HTML::Selector::Element::Trait->can('select'), 'select is our own method');
is(scalar $html->select('div.section > h1 + p')->{id}, 'goal', 'found using normal select');

done_testing();