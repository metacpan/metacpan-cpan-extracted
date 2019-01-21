use Test::More;
use warnings;
use strict;

# <test-body>

require_ok('HTML5::DOM');

######################################################################################
# utf8 support
######################################################################################

ok(length(HTML5::DOM->new->parse('<b>пыщь пыщь</b>')->at('b')->text) == 17, 'test utf8 flag auto "no utf8" [0]');
ok(length(HTML5::DOM->new->parse('<b>пыщь пыщь</b>', {utf8 => "auto"})->at('b')->text) == 17, 'test utf8 flag auto "no utf8" [1]');

ok(length(HTML5::DOM->new->parse('<b>пыщь пыщь</b>', {utf8 => 1})->at('b')->text) == 9, 'test utf8 flag on');

{
	use utf8;
	ok(length(HTML5::DOM->new->parse('<b>пыщь пыщь</b>')->at('b')->text) == 9, 'test utf8 flag auto with "use utf8" [0]');
	ok(length(HTML5::DOM->new->parse('<b>пыщь пыщь</b>', {utf8 => "auto"})->at('b')->text) == 9, 'test utf8 flag auto "use utf8" [1]');
	ok(length(HTML5::DOM->new->parse('<b>пыщь пыщь</b>')->utf8(0)->at('b')->text) == 17, 'test utf8 flag off after parse');
	
	ok(length(HTML5::DOM->new({utf8 => 0})->parse('<b>пыщь пыщь</b>')->at('b')->text) == 17, 'test utf8 flag off');
}

ok(length(HTML5::DOM::CSS->new->parseSelector("[name=\"тест\"]")->text) == 17, 'test utf8 flag auto "no utf8" [0]');
ok(length(HTML5::DOM::CSS->new->parseSelector("[name=\"тест\"]", {utf8 => "auto"})->text) == 17, 'test utf8 flag auto "no utf8" [1]');

ok(length(HTML5::DOM::CSS->new->parseSelector("[name=\"тест\"]", {utf8 => 1})->text) == 13, 'test utf8 flag on');

{
	use utf8;
	ok(length(HTML5::DOM::CSS->new->parseSelector("[name=\"тест\"]")->text) == 13, 'test utf8 flag auto with "use utf8" [0]');
	ok(length(HTML5::DOM::CSS->new->parseSelector("[name=\"тест\"]", {utf8 => "auto"})->text) == 13, 'test utf8 flag auto "use utf8" [1]');
	ok(length(HTML5::DOM::CSS->new->parseSelector("[name=\"тест\"]")->utf8(0)->text) == 17, 'test utf8 flag off after parse');
}

ok(length(HTML5::DOM::CSS->new({utf8 => 0})->parseSelector("[name=\"тест\"]")->text) == 17, 'test utf8 flag off');

done_testing;

# </test-body>
