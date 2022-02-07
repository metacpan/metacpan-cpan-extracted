#!/usr/bin/env perl
use Markdown::Compiler::Test;

my $source = <<EOF;
---
key: value
---

Hello, World!

EOF

my $c = build_and_test( "Basic Key Value",
    $source, [
    [ metadata_is => { key => 'value' } ],
]);

done_testing;


