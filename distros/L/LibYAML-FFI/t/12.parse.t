#!/usr/bin/env perl
use Test2::V0;
use LibYAML::FFI;

subtest parse => sub {
    my $parser = LibYAML::FFI::Parser->new;
    my $ok = $parser->yaml_parser_initialize;
    my $input = <<'EOM';
foo: [
    &ALIAS bar, *ALIAS
  ]
EOM
    is $parser->read_handler, undef, "read_handler";
    $parser->yaml_parser_set_input_string($input, length($input));
    is $parser->state, 0, "state";
    my $events;
    while (1) {
        my $event = LibYAML::FFI::Event->new;
        my $ok = $parser->yaml_parser_parse($event);
        my $error = $parser->error;
        my $type = $event->type;
        my $str = $event->as_string;
        diag "Event: $str";
        push @$events, "$event";
        last unless $ok;
        last if $type == LibYAML::FFI::event_type::YAML_STREAM_END_EVENT;
    }
    is scalar @$events, 11, "event number";
    undef $parser;
    diag "end";
};

done_testing;
