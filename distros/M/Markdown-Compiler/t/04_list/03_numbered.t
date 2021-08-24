#!/usr/bin/env perl
use Markdown::Compiler::Test;

my $source = <<EOF;
1. One
2. Two
3. Three
4. Four
EOF

my $result = <<EOF;
<ol>
<li>One</li>
<li>Two</li>
<li>Three</li>
<li>Four</li>

</ol>
EOF

my $c = build_and_test( "Numbered List",
    $source, [
    [ result_is => $result ],
]);

done_testing;



