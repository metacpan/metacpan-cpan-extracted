# ABSTRACT: FFI binding for C libyaml
package LibYAML::FFI;

use strict;
use warnings;
use experimental 'signatures';
use FFI::Platypus 2.00;
use FFI::C;
use YAML::PP::Common;

our $VERSION = 'v0.0.1'; # VERSION

my $ffi = FFI::Platypus->new( api => 1 );
FFI::C->ffi($ffi);

$ffi->bundle;

package LibYAML::FFI::YamlEncoding {
    FFI::C->enum( yaml_encoding_t => [qw/
        ANY_ENCODING
        UTF8_ENCODING
        UTF16LE_ENCODING
        UTF16BE_ENCODING
    /],
    { rev => 'int', prefix => 'YAML_', package => 'LibYAML::FFI::YamlEncoding' }
    );
}

package LibYAML::FFI::event_type {
    FFI::C->enum( yaml_event_type_t => [qw/
        NO_EVENT
        STREAM_START_EVENT STREAM_END_EVENT
        DOCUMENT_START_EVENT DOCUMENT_END_EVENT
        ALIAS_EVENT SCALAR_EVENT
        SEQUENCE_START_EVENT SEQUENCE_END_EVENT
        MAPPING_START_EVENT MAPPING_END_EVENT
    /],
    { rev => 'int', prefix => 'YAML_', package => 'LibYAML::FFI::event_type' }
    );
}

package LibYAML::FFI::YamlScalarStyle {
    FFI::C->enum( yaml_scalar_style_t => [qw/
        ANY_SCALAR_STYLE
        PLAIN_SCALAR_STYLE
        SINGLE_QUOTED_SCALAR_STYLE
        DOUBLE_QUOTED_SCALAR_STYLE
        LITERAL_SCALAR_STYLE
        FOLDED_SCALAR_STYLE
    /],
    { rev => 'int', prefix => 'YAML_', package => 'LibYAML::FFI::YamlScalarStyle' }
    );
}

package LibYAML::FFI::YamlSequenceStyle {
    FFI::C->enum( yaml_sequence_style_t => [qw/
        ANY_SEQUENCE_STYLE
        BLOCK_SEQUENCE_STYLE
        FLOW_SEQUENCE_STYLE
    /],
    { rev => 'int', prefix => 'YAML_', package => 'LibYAML::FFI::YamlSequenceStyle' }
    );
}
package LibYAML::FFI::YamlMappingStyle {
    FFI::C->enum( yaml_mapping_style_t => [qw/
        ANY_MAPPING_STYLE
        BLOCK_MAPPING_STYLE
        FLOW_MAPPING_STYLE
    /],
    { rev => 'int', prefix => 'YAML_', package => 'LibYAML::FFI::YamlMappingStyle' }
    );
}

package LibYAML::FFI::YamlErrorType {
    FFI::C->enum( yaml_error_type_t => [qw/
    NO_ERROR
    MEMORY_ERROR
    READER_ERROR
    SCANNER_ERROR
    PARSER_ERROR
    COMPOSER_ERROR
    WRITER_ERROR
    EMITTER_ERROR
    /],
    { rev => 'int', prefix => 'YAML_', package => 'LibYAML::FFI::YamlErrorType' }
    );
}

package LibYAML::FFI::YamlParserState {
    FFI::C->enum( yaml_parser_state_t => [qw/
    PARSE_STREAM_START_STATE
    PARSE_IMPLICIT_DOCUMENT_START_STATE
    PARSE_DOCUMENT_START_STATE
    PARSE_DOCUMENT_CONTENT_STATE
    PARSE_DOCUMENT_END_STATE
    PARSE_BLOCK_NODE_STATE
    PARSE_BLOCK_NODE_OR_INDENTLESS_SEQUENCE_STATE
    PARSE_FLOW_NODE_STATE
    PARSE_BLOCK_SEQUENCE_FIRST_ENTRY_STATE
    PARSE_BLOCK_SEQUENCE_ENTRY_STATE
    PARSE_INDENTLESS_SEQUENCE_ENTRY_STATE
    PARSE_BLOCK_MAPPING_FIRST_KEY_STATE
    PARSE_BLOCK_MAPPING_KEY_STATE
    PARSE_BLOCK_MAPPING_VALUE_STATE
    PARSE_FLOW_SEQUENCE_FIRST_ENTRY_STATE
    PARSE_FLOW_SEQUENCE_ENTRY_STATE
    PARSE_FLOW_SEQUENCE_ENTRY_MAPPING_KEY_STATE
    PARSE_FLOW_SEQUENCE_ENTRY_MAPPING_VALUE_STATE
    PARSE_FLOW_SEQUENCE_ENTRY_MAPPING_END_STATE
    PARSE_FLOW_MAPPING_FIRST_KEY_STATE
    PARSE_FLOW_MAPPING_KEY_STATE
    PARSE_FLOW_MAPPING_VALUE_STATE
    PARSE_FLOW_MAPPING_EMPTY_VALUE_STATE
    PARSE_END_STATE
    /],
    { rev => 'int', prefix => 'YAML_', package => 'LibYAML::FFI::YamlParserState' }
    );
}

package LibYAML::FFI::StreamStart {
    FFI::C->struct( YAML_StreamStart => [
        encoding => 'yaml_encoding_t',
   ]);
}

package LibYAML::FFI::Scalar {
    FFI::C->struct( YAML_Scalar => [
        anchor => 'opaque',
        tag => 'opaque',
        value => 'opaque',
        length => 'size_t',
        plain_implicit => 'int',
        quoted_implicit => 'int',
        style => 'yaml_scalar_style_t',
    ]);
    sub anchor_str ($self) { $ffi->cast('opaque', 'string', $self->anchor) }
    sub tag_str ($self) { $ffi->cast('opaque', 'string', $self->tag) }
    sub value_str ($self) { $ffi->cast('opaque', 'string', $self->value) }
}

package LibYAML::FFI::Alias {
    FFI::C->struct( YAML_Alias => [
        anchor => 'opaque',
    ]);
    sub anchor_str ($self) { $ffi->cast('opaque', 'string', $self->anchor) }
}

package LibYAML::FFI::SequenceStart {
    FFI::C->struct( YAML_SequenceStart => [
        anchor => 'opaque',
        tag => 'opaque',
        implicit => 'int',
        style => 'yaml_sequence_style_t',
    ]);
    sub anchor_str ($self) { $ffi->cast('opaque', 'string', $self->anchor) }
    sub tag_str ($self) { $ffi->cast('opaque', 'string', $self->tag) }
}

package LibYAML::FFI::MappingStart {
    FFI::C->struct( YAML_MappingStart => [
        anchor => 'opaque',
        tag => 'opaque',
        implicit => 'int',
        style => 'yaml_mapping_style_t',
    ]);
    sub anchor_str ($self) { $ffi->cast('opaque', 'string', $self->anchor) }
    sub tag_str ($self) { $ffi->cast('opaque', 'string', $self->tag) }
}

package LibYAML::FFI::EventData {
    FFI::C->union( yaml_event_data_t => [
        stream_start => 'YAML_StreamStart',
        alias => 'YAML_Alias',
        scalar => 'YAML_Scalar',
        sequence_start => 'YAML_SequenceStart',
        mapping_start => 'YAML_MappingStart',
    ]);
}

package LibYAML::FFI::YamlMark {
    use overload
        '""' => sub { shift->as_string };
    FFI::C->struct( yaml_mark_t => [
        index => 'size_t',
        line =>'size_t',
        column => 'size_t',
    ]);
    sub as_string {
        my ($self) = @_;
        sprintf "(%2d):[L:%2d C:%2d]", $self->index, $self->line, $self->column;
    }
}

package LibYAML::FFI::Event {
    FFI::C->struct( yaml_event_t => [
        type => 'yaml_event_type_t',
        data => 'yaml_event_data_t',
        start_mark => 'yaml_mark_t',
        end_mark => 'yaml_mark_t',
    ]);

    sub to_hash {
        my ($self) = @_;
        my %hash = ();
        my $type = $self->yaml_event_type;
        if ($type == LibYAML::FFI::event_type::YAML_STREAM_START_EVENT()) {
            $hash{name} = 'stream_start_event';
        }
        elsif ($type == LibYAML::FFI::event_type::YAML_STREAM_END_EVENT()) {
            $hash{name} = 'stream_end_event';
        }
        elsif ($type == LibYAML::FFI::event_type::YAML_DOCUMENT_START_EVENT()) {
            $hash{name} = 'document_start_event';
        }
        elsif ($type == LibYAML::FFI::event_type::YAML_DOCUMENT_END_EVENT()) {
            $hash{name} = 'document_end_event';
        }
        elsif ($type == LibYAML::FFI::event_type::YAML_ALIAS_EVENT()) {
            $hash{name} = 'alias_event';
            if (my $anchor = $self->data->alias->anchor_str) {
                $hash{value} = $anchor;
            }
        }
        elsif ($type == LibYAML::FFI::event_type::YAML_SCALAR_EVENT()) {
            $hash{name} = 'scalar_event';
            my $val = $self->yaml_event_scalar_value;
            $hash{value} = $val;
            if (my $anchor = $self->yaml_event_scalar_anchor) {
                $hash{anchor} = $anchor;
            }
            if (my $tag = $self->yaml_event_scalar_tag) {
                $hash{tag} = $tag;
            }
            $hash{style} = $self->yaml_event_scalar_style;
        }
        elsif ($type == LibYAML::FFI::event_type::YAML_SEQUENCE_START_EVENT()) {
            $hash{name} = 'sequence_start_event';
            if (my $anchor = $self->yaml_event_sequence_anchor) {
                $hash{anchor} = $anchor;
            }
            if (my $tag = $self->yaml_event_sequence_tag) {
                $hash{tag} = $tag;
            }
            $hash{style} = $self->yaml_event_sequence_style;
        }
        elsif ($type == LibYAML::FFI::event_type::YAML_SEQUENCE_END_EVENT()) {
            $hash{name} = 'sequence_end_event';
        }
        elsif ($type == LibYAML::FFI::event_type::YAML_MAPPING_START_EVENT()) {
            $hash{name} = 'mapping_start_event';
            $hash{style} = $self->yaml_event_mapping_style;
            if (my $anchor = $self->yaml_event_mapping_anchor) {
                $hash{anchor} = $anchor;
            }
            if (my $tag = $self->yaml_event_mapping_anchor) {
                $hash{tag} = $tag;
            }
        }
        elsif ($type == LibYAML::FFI::event_type::YAML_MAPPING_END_EVENT()) {
            $hash{name} = 'mapping_end_event';
        }
        return \%hash;
    }
    sub as_string {
        my ($self) = @_;
        my $str = sprintf "(%2d) ",
            $self->type;
        if ($self->type == LibYAML::FFI::event_type::YAML_STREAM_START_EVENT()) {
            $str .= "+STR";
        }
        elsif ($self->type == LibYAML::FFI::event_type::YAML_STREAM_END_EVENT()) {
            $str .= "-STR";
        }
        elsif ($self->type == LibYAML::FFI::event_type::YAML_DOCUMENT_START_EVENT()) {
            $str .= "+DOC";
        }
        elsif ($self->type == LibYAML::FFI::event_type::YAML_DOCUMENT_END_EVENT()) {
            $str .= "-DOC";
        }
        elsif ($self->type == LibYAML::FFI::event_type::YAML_ALIAS_EVENT()) {
            $str .= "=ALI";
            $str .= " " . $self->data->alias->anchor_str;
        }
        elsif ($self->type == LibYAML::FFI::event_type::YAML_SCALAR_EVENT()) {
            my $scalar = $self->data->scalar;
            my $val = $scalar->value_str;
            my $anchor = $scalar->anchor;
            my $length = $scalar->length;
            my $plain_implicit = $scalar->plain_implicit;
            $str .= sprintf "=VAL >%s< (%d) plain_implicit: %d", $val, $length, $plain_implicit;
            $scalar = $self->data->scalar;
        }
        elsif ($self->type == LibYAML::FFI::event_type::YAML_SEQUENCE_START_EVENT()) {
            my $style = $self->data->sequence_start->style;
            $str .= "+SEQ";
            if ($style == LibYAML::FFI::YamlSequenceStyle::YAML_FLOW_SEQUENCE_STYLE()) {
                $str .= " []";
            }
        }
        elsif ($self->type == LibYAML::FFI::event_type::YAML_SEQUENCE_END_EVENT()) {
            $str .= "-SEQ";
        }
        elsif ($self->type == LibYAML::FFI::event_type::YAML_MAPPING_START_EVENT()) {
            my $style = $self->data->sequence_start->style;
            $str .= "+MAP";
            if ($style == LibYAML::FFI::YamlMappingStyle::YAML_FLOW_MAPPING_STYLE()) {
                $str .= " {}";
            }
        }
        elsif ($self->type == LibYAML::FFI::event_type::YAML_MAPPING_END_EVENT()) {
            $str .= "-MAP";
        }
        $str = $self->start_mark . ' ' . $self->end_mark . ' ' . $str;
        return $str;
    }
    $ffi->attach( [ yaml_event_delete => 'DESTROY' ] => [ 'yaml_event_t' ] => 'void'   );
    $ffi->attach( yaml_scalar_event_initialize => [qw/
        yaml_event_t string string string int int int yaml_scalar_style_t
    /] => 'int' );
    $ffi->attach( yaml_sequence_start_event_initialize => [qw/
        yaml_event_t string string int yaml_scalar_style_t
    /] => 'int' );
    $ffi->attach( yaml_stream_start_event_initialize => [qw/
        yaml_event_t yaml_encoding_t
    /] => 'int' );
    $ffi->attach( yaml_event_type => [qw/ yaml_event_t /] => 'yaml_event_type_t' );

    $ffi->attach( yaml_event_scalar_style => [qw/ yaml_event_t /] => 'yaml_scalar_style_t' );
    $ffi->attach( yaml_event_scalar_value => [qw/ yaml_event_t /] => 'string' );
    $ffi->attach( yaml_event_scalar_anchor => [qw/ yaml_event_t /] => 'string' );
    $ffi->attach( yaml_event_scalar_tag => [qw/ yaml_event_t /] => 'string' );

    $ffi->attach( yaml_event_mapping_style => [qw/ yaml_event_t /] => 'yaml_mapping_style_t' );
    $ffi->attach( yaml_event_mapping_anchor => [qw/ yaml_event_t /] => 'string' );
    $ffi->attach( yaml_event_mapping_tag => [qw/ yaml_event_t /] => 'string' );

    $ffi->attach( yaml_event_sequence_style => [qw/ yaml_event_t /] => 'yaml_sequence_style_t' );
    $ffi->attach( yaml_event_sequence_anchor => [qw/ yaml_event_t /] => 'string' );
    $ffi->attach( yaml_event_sequence_tag => [qw/ yaml_event_t /] => 'string' );
}

package LibYAML::FFI::ParserInputString {
    FFI::C->struct( Parser_input_string => [
        start => 'opaque',
        end => 'opaque',
        current => 'opaque',
    ]);
}

package LibYAML::FFI::ParserBuffer {
    FFI::C->struct( Parser_buffer => [
        start => 'opaque',
        end => 'opaque',
        pointer => 'opaque',
        last => 'opaque',
    ]);
}

package LibYAML::FFI::ParserTokens {
    FFI::C->struct( Parser_tokens => [
        start => 'opaque',
        end => 'opaque',
        head => 'opaque',
        tail => 'opaque',
    ]);
}
package LibYAML::FFI::ParserIndents {
    FFI::C->struct( Parser_indents => [
        start => 'opaque',
        end => 'opaque',
        top => 'opaque',
    ]);
}

package LibYAML::FFI::ParserSimpleKeys {
    FFI::C->struct( Parser_simple_keys => [
        start => 'opaque',
        end => 'opaque',
        top => 'opaque',
    ]);
}

package LibYAML::FFI::ParserInput {
    FFI::C->union( Parser_input => [
        string => 'Parser_input_string',
        file => 'opaque',
    ]);
}

package LibYAML::FFI::ParserStates {
    FFI::C->struct( Parser_states => [
        start => 'opaque',
        end => 'opaque',
        top => 'opaque',
    ]);
}

package LibYAML::FFI::ParserMarks {
    FFI::C->struct( Parser_marks => [
        start => 'opaque',
        end => 'opaque',
        top => 'opaque',
    ]);
}

package LibYAML::FFI::ParserTagDirectives {
    FFI::C->struct( Parser_tag_directives => [
        start => 'opaque',
        end => 'opaque',
        top => 'opaque',
    ]);
}

package LibYAML::FFI::ParserAliases {
    FFI::C->struct( Parser_aliases => [
        start => 'opaque',
        end => 'opaque',
        top => 'opaque',
    ]);
}

package LibYAML::FFI::TagDirective {
    FFI::C->struct( yaml_tag_directive_t => [
        handle => 'opaque',
        prefix => 'opaque',
    ]);
}

package LibYAML::FFI::VersionDirective {
    FFI::C->struct( yaml_version_directive_t => [
        major => 'int',
        minor => 'int',
    ]);
}

package LibYAML::FFI::DocumentTagDirectives {
    FFI::C->struct( document_tag_directives => [
        start => 'yaml_tag_directive_t',
        end => 'yaml_tag_directive_t',
    ]);
}

package LibYAML::FFI::YamlDocument {
    $ffi->type( 'opaque' => 'document_nodes' );
    FFI::C->struct( yaml_document_t => [
        nodes => 'document_nodes',
        version_directive => 'yaml_version_directive_t',
        tag_directives => 'document_tag_directives',
        start_implicit => 'int',
        end_implicit => 'int',
        start_mark => 'yaml_mark_t',
        end_mark => 'yaml_mark_t',
    ]);
}

package LibYAML::FFI::Parser {
    $ffi->type( 'opaque' => 'yaml_read_handler_t' );
    FFI::C->struct( yaml_parser_t => [
        error => 'yaml_error_type_t',
        problem => 'opaque',
        problem_offset => 'size_t',
        problem_value => 'int',
        problem_mark => 'yaml_mark_t',
        context => 'opaque',
        context_mark => 'yaml_mark_t',

        read_handler => 'yaml_read_handler_t',
        read_handler_data => 'opaque',

        input => 'Parser_input',
        eof => 'int',

        buffer => 'Parser_buffer',
        unread => 'size_t',
        raw_buffer => 'Parser_buffer',

        encoding => 'yaml_encoding_t',

        offset => 'size_t',
        mark => 'yaml_mark_t',

        stream_start_produced => 'int',
        stream_end_produced => 'int',
        flow_level => 'int',

        tokens => 'Parser_tokens',

        tokens_parsed => 'size_t',
        token_available => 'int',

        indents => 'Parser_indents',
        indent => 'int',
        simple_key_allowed => 'int',
        simple_keys => 'Parser_simple_keys',

        states => 'Parser_states',
        state => 'yaml_parser_state_t',
        marks => 'Parser_marks',

        tag_directives => 'Parser_tag_directives',

        aliases => 'Parser_aliases',

        document => 'yaml_document_t',
    ]);

    $ffi->attach( [ yaml_parser_delete => 'DESTROY' ] => [ 'yaml_parser_t' ] => 'void'   );

    $ffi->attach( yaml_parser_initialize => [qw/
        yaml_parser_t
    /] => 'int' );
    $ffi->attach( yaml_parser_set_input_string => [qw/
        yaml_parser_t string size_t
    /] => 'void' );
    $ffi->attach( yaml_parser_parse => [qw/
        yaml_parser_t yaml_event_t
    /] => 'int' );
#    $ffi->attach( yaml_parser_delete => [qw/ yaml_parser_t /] => 'void' );

}


1;

__END__

=pod

=encoding utf-8

=head1 NAME

LibYAML::FFI - FFI binding for C libyaml

=head1 SYNOPSIS

    use LibYAML::FFI;
    my $ok = $parser->yaml_parser_initialize;
    my $input = <<'EOM';
    foo: [
        &ALIAS bar, *ALIAS
      ]
    EOM
    $parser->yaml_parser_set_input_string($input, length($input));
    my $events;
    while (1) {
        my $event = LibYAML::FFI::Event->new;
        my $ok = $parser->yaml_parser_parse($event);
        my $str = $event->as_string;
        print "Event: $str";
        last unless $ok;
        last if $event->type == LibYAML::FFI::event_type::YAML_STREAM_END_EVENT;
    }

=head1 DESCRIPTION

This is a Proof of Concept for now. It uses L<FFI::Platypus> to provide
a wrapper around the C library libyaml. For now it can only parse, not emit.
Libyaml sources are included for now, I would like to use L<Alien::LibYAML>
in the future.

For loading a data structure, see L<LibYAML::FFI::YPP> in this distribution.

=head1 SEE ALSO

=over

=item L<YAML::LibYAML::API>

=item L<YAML::XS>

=item L<YAML::PP::LibYAML>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2023 by Tina Müller

This library is free software and may be distributed under the same terms
as perl itself.

=cut
