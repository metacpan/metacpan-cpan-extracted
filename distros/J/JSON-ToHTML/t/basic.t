use strict; use warnings;
use Test::More tests => 2;

use JSON::ToHTML;

my @out = JSON::ToHTML::json_values_to_html([{foo=>[],'bar'=>{},baz=>1970}]);
is 0+@out, 1;
is $out[0], '<table class="table"><tr><th class="num"><i>#</i></th><th>bar</th><th>baz</th><th>foo</th></tr><tr><td class="num"><i>0</i></td><td><i>empty&#160;object</i></td><td><div class="num">1970</div></td><td><table class="table"><tr><td><i>empty&#160;array</i></td></tr></table></td></tr></table>';
