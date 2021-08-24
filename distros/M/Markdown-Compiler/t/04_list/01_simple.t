#!/usr/bin/env perl
use Markdown::Compiler::Test;

my $source = <<EOF;
- One
- Two
- Three
- Four
EOF

my $result = <<EOF;
<ul>
<li>One</li>
<li>Two</li>
<li>Three</li>
<li>Four</li>

</ul>
EOF

my $c = build_and_test( "Basic List",
    $source, [
    [ result_is => $result ],
]);

done_testing;



