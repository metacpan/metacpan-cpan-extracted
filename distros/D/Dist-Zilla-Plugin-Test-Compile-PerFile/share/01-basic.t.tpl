use strict;
use warnings;

# This test was generated for <{{$file}}>
# using by {{ $plugin_module }} ( {{ $plugin_name }} ) version {{ $plugin_version }}
# with template 01-basic.t.tpl

use Test::More {{ $test_more_version }} tests => 1;
require_ok({{ quoted($relpath) }});
