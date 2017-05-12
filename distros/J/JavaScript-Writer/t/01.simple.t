#!/usr/bin/env perl

use strict;
use warnings;
use lib 't/lib';

use JavaScript::Writer;
use Test::More tests => 4;
use Test::JE;

my $page = JavaScript::Writer->new;
$page->call("alert", 'Nihao');

is($page->as_string(), 'alert("Nihao");' );

$page->call(confirm => "Nihao");

my $str = $page->as_string();

is($str, 'alert("Nihao");confirm("Nihao");' );

is($page->as_html(), qq{<script type="text/javascript">$str</script>});

my $je = Test::JE->new;
$je->eval_ok($str);

