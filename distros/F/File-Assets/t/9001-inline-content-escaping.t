#!perl -w

use strict;

use Test::More qw/no_plan/;
use t::Test;

my $assets = t::Test->assets;
$assets->include_content(<<_END_, 'js');
alert("Hello, World.");
_END_

$assets->include(<<_END_);
<style media="screen">
div {
    background: "#fff"
}
</style>

_END_

is($assets->export."\n", <<_END_);
<style media="screen" type="text/css">

div {
    background: "#fff"
}
</style>
<script type="text/javascript">
alert("Hello, World.");
</script>
_END_
