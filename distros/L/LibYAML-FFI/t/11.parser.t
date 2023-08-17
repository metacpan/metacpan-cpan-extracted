#!/usr/bin/env perl
use Test2::V0;
use LibYAML::FFI;

subtest parser_objects => sub {
    for my $i (1..100) {
        my $parser = LibYAML::FFI::Parser->new;
        my $ok = $parser->yaml_parser_initialize;
        is $ok, 1, "($i) initialize";
        is $parser->error, 0, "($i) error" or bail_out("Parser not correctly initialized");
    }
};

done_testing;
