#!/usr/bin/env perl
use Test2::V0;
use LibYAML::FFI;

subtest scalar => sub {
    my $event = LibYAML::FFI::Event->new;
    my $style = LibYAML::FFI::YamlScalarStyle::YAML_FOLDED_SCALAR_STYLE;
    my $ret = $event->yaml_scalar_event_initialize("Anc", "Tag", "lala", -1, 1, 1, $style);
    is $event->data->scalar->anchor_str, 'Anc', 'anchor';
    is $event->data->scalar->tag_str, 'Tag', 'tag';
    is $event->data->scalar->value_str, "lala", "value";
    is $event->data->scalar->length, 4, "length";
    is $event->data->scalar->plain_implicit, 1, "plain_implicit";
    is $event->data->scalar->quoted_implicit, 1, "quoted_implicit";
    is $event->data->scalar->style, $style, "style";
};

subtest sequence => sub {
    my $event = LibYAML::FFI::Event->new;
    my $style = LibYAML::FFI::YamlSequenceStyle::YAML_FLOW_SEQUENCE_STYLE;
    my $ret = $event->yaml_sequence_start_event_initialize("Anc", "Tag", 1, $style);
    is $event->data->sequence_start->anchor_str, 'Anc', 'anchor';
    is $event->data->sequence_start->tag_str, 'Tag', 'tag';
    is $event->data->sequence_start->implicit, 1, "quoted_implicit";
    is $event->data->sequence_start->style, $style, "style";
};

subtest streamstart => sub {
    my $event = LibYAML::FFI::Event->new;
    my $encoding = LibYAML::FFI::YamlEncoding::YAML_UTF8_ENCODING;
    my $ret = $event->yaml_stream_start_event_initialize($encoding);
    is $event->data->stream_start->encoding, $encoding, "encoding";
    my $type = LibYAML::FFI::event_type::YAML_STREAM_START_EVENT;
    is $event->type, $type, "type";
};

done_testing;
