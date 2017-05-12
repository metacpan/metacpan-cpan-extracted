use strict;
use warnings;
use utf8;
use Test::More;
use HTML::CallJS;

is call_js('foo', {'x' => [1, '<>&3']}), '<script class="call_js" type="text/javascript">foo({"x":[1,"\u003c\u003e\u00263"]})</script>';
is call_js('bar', 5963), '<script class="call_js" type="text/javascript">bar(5963)</script>';


done_testing;

