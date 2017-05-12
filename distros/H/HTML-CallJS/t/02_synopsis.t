use strict;
use warnings;
use utf8;
use Test::More;

    use HTML::CallJS;

    is call_js('foo', {x => 1}), '<script class="call_js" type="text/javascript">foo({"x":1})</script>';

done_testing;

