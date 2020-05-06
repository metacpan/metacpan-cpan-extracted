use Test::More;

use_ok('HTML::Selector::Element', qw(query));
require_ok('HTML::Tree');
ok(my $html = HTML::TreeBuilder->new_from_content(<<'__SNIPPET_1__'), 'parse using new_from_content');
<html><body><div class="container">
<div class="section"><p>Cold...</p></div>
<div class="section"><h1>Getting there...</h1><p id="goal">This is the goal</p></div>
</div></body></html>
__SNIPPET_1__
is($html->can('query'), HTML::Selector::Element::Trait->can('query'), 'query is our own method');
is(scalar $html->query('div.section > h1 + p')->{id}, 'goal', 'found using normal query');

done_testing();