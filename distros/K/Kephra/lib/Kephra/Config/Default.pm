use v5.12;
use warnings;

package Kephra::Config::Default;

sub get {{
    file => {
        open => '',
        closed => [],
    },
    session => {loaded => '', last => [] },
    document_default => {},
    editor => {
        change_pos => -1,
        change_prev => -1,
        caret_pos => -1,
        marker => [],
    },
    view => {
        whitespace    => 1,
        caret_line    => 1,
        line_ending   => 0,
        line_wrap => 0,
        line_nr_margin => 1,
        marker_margin => 1,
        right_margin  => 1,
        indent_guide  => 1,
        zoom_level => 0,
        full_screen => 0,
    },
    document => {
        soft_tabs => 1,
        tab_size => 4,
        line_ending   => 'lf',
        encoding   => 'utf-8',
    },
    search => {
        find_term => '',
        replace_term => '',
        case_sensitive => 0,
        whole_word => 0,
        word_start => 0,
        regular_expression => 0,
        wrap_abound_document => 1,
    },

}}

1;
