#!/usr/bin/env perl
#==
# Ensure that JSON structures work in the default case.
# ('JSON is a subset of YAML', et cetra)
#==
use Markdown::Compiler::Test;

my $source = <<EOF;
---
{
    "key": "value"
}
---  

Hello, World!

EOF

my $c = build_and_test( "Basic Key Value",
    $source, [
    [ metadata_is => { key => 'value' } ],
]);


done_testing;


