#!/usr/bin/env pugs

use JavaScript::Writer;
use Test;

plan 1;

my $page = JavaScript::Writer.new;
$page.call("alert", "Nihao");

is($page.as_string, 'alert("Nihao");' );
