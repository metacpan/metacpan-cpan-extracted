#
# This file is part of Language-Befunge
#
# This software is copyright (c) 2003 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.010;
use strict;
use warnings;

package Language::Befunge::Ops::Befunge98;
# ABSTRACT: operations supported by a Befunge-98 interpreter
$Language::Befunge::Ops::Befunge98::VERSION = '5.000';
use Language::Befunge::Ops;

sub get_ops_map {
    return {
        '0'  => \&Language::Befunge::Ops::num_push_number,
        '1'  => \&Language::Befunge::Ops::num_push_number,
        '2'  => \&Language::Befunge::Ops::num_push_number,
        '3'  => \&Language::Befunge::Ops::num_push_number,
        '4'  => \&Language::Befunge::Ops::num_push_number,
        '5'  => \&Language::Befunge::Ops::num_push_number,
        '6'  => \&Language::Befunge::Ops::num_push_number,
        '7'  => \&Language::Befunge::Ops::num_push_number,
        '8'  => \&Language::Befunge::Ops::num_push_number,
        '9'  => \&Language::Befunge::Ops::num_push_number,
        'a'  => \&Language::Befunge::Ops::num_push_number,
        'b'  => \&Language::Befunge::Ops::num_push_number,
        'c'  => \&Language::Befunge::Ops::num_push_number,
        'd'  => \&Language::Befunge::Ops::num_push_number,
        'e'  => \&Language::Befunge::Ops::num_push_number,
        'f'  => \&Language::Befunge::Ops::num_push_number,
        '"'  => \&Language::Befunge::Ops::str_enter_string_mode,
        "'"  => \&Language::Befunge::Ops::str_fetch_char,
        's'  => \&Language::Befunge::Ops::str_store_char,
        '+'  => \&Language::Befunge::Ops::math_addition,
        '-'  => \&Language::Befunge::Ops::math_substraction,
        '*'  => \&Language::Befunge::Ops::math_multiplication,
        '/'  => \&Language::Befunge::Ops::math_division,
        '%'  => \&Language::Befunge::Ops::math_remainder,
        '>'  => \&Language::Befunge::Ops::dir_go_east,
        '<'  => \&Language::Befunge::Ops::dir_go_west,
        '^'  => \&Language::Befunge::Ops::dir_go_north,
        'v'  => \&Language::Befunge::Ops::dir_go_south,
        '?'  => \&Language::Befunge::Ops::dir_go_away,
        '['  => \&Language::Befunge::Ops::dir_turn_left,
        ']'  => \&Language::Befunge::Ops::dir_turn_right,
        'r'  => \&Language::Befunge::Ops::dir_reverse,
        'x'  => \&Language::Befunge::Ops::dir_set_delta,
        '!'  => \&Language::Befunge::Ops::decis_neg,
        '`'  => \&Language::Befunge::Ops::decis_gt,
        '_'  => \&Language::Befunge::Ops::decis_horiz_if,
        '|'  => \&Language::Befunge::Ops::decis_vert_if,
        'w'  => \&Language::Befunge::Ops::decis_cmp,
        ' '  => \&Language::Befunge::Ops::flow_space,
        'z'  => \&Language::Befunge::Ops::flow_no_op,
        ';'  => \&Language::Befunge::Ops::flow_comments,
        '#'  => \&Language::Befunge::Ops::flow_trampoline,
        'j'  => \&Language::Befunge::Ops::flow_jump_to,
        'k'  => \&Language::Befunge::Ops::flow_repeat,
        '@'  => \&Language::Befunge::Ops::flow_kill_thread,
        'q'  => \&Language::Befunge::Ops::flow_quit,
        '$'  => \&Language::Befunge::Ops::stack_pop,
        ':'  => \&Language::Befunge::Ops::stack_duplicate,
        '\\' => \&Language::Befunge::Ops::stack_swap,
        'n'  => \&Language::Befunge::Ops::stack_clear,
        '{'  => \&Language::Befunge::Ops::block_open,
        '}'  => \&Language::Befunge::Ops::block_close,
        'u'  => \&Language::Befunge::Ops::bloc_transfer,
        'g'  => \&Language::Befunge::Ops::store_get,
        'p'  => \&Language::Befunge::Ops::store_put,
        '.'  => \&Language::Befunge::Ops::stdio_out_num,
        ','  => \&Language::Befunge::Ops::stdio_out_ascii,
        '&'  => \&Language::Befunge::Ops::stdio_in_num,
        '~'  => \&Language::Befunge::Ops::stdio_in_ascii,
        'i'  => \&Language::Befunge::Ops::stdio_in_file,
        'o'  => \&Language::Befunge::Ops::stdio_out_file,
        '='  => \&Language::Befunge::Ops::stdio_sys_exec,
        'y'  => \&Language::Befunge::Ops::sys_info,
        't'  => \&Language::Befunge::Ops::spawn_ip,
        '('  => \&Language::Befunge::Ops::lib_load,
        ')'  => \&Language::Befunge::Ops::lib_unload,
        'A'  => \&Language::Befunge::Ops::lib_run_instruction,
        'B'  => \&Language::Befunge::Ops::lib_run_instruction,
        'C'  => \&Language::Befunge::Ops::lib_run_instruction,
        'D'  => \&Language::Befunge::Ops::lib_run_instruction,
        'E'  => \&Language::Befunge::Ops::lib_run_instruction,
        'F'  => \&Language::Befunge::Ops::lib_run_instruction,
        'G'  => \&Language::Befunge::Ops::lib_run_instruction,
        'H'  => \&Language::Befunge::Ops::lib_run_instruction,
        'I'  => \&Language::Befunge::Ops::lib_run_instruction,
        'J'  => \&Language::Befunge::Ops::lib_run_instruction,
        'K'  => \&Language::Befunge::Ops::lib_run_instruction,
        'L'  => \&Language::Befunge::Ops::lib_run_instruction,
        'M'  => \&Language::Befunge::Ops::lib_run_instruction,
        'N'  => \&Language::Befunge::Ops::lib_run_instruction,
        'O'  => \&Language::Befunge::Ops::lib_run_instruction,
        'P'  => \&Language::Befunge::Ops::lib_run_instruction,
        'Q'  => \&Language::Befunge::Ops::lib_run_instruction,
        'R'  => \&Language::Befunge::Ops::lib_run_instruction,
        'S'  => \&Language::Befunge::Ops::lib_run_instruction,
        'T'  => \&Language::Befunge::Ops::lib_run_instruction,
        'U'  => \&Language::Befunge::Ops::lib_run_instruction,
        'V'  => \&Language::Befunge::Ops::lib_run_instruction,
        'W'  => \&Language::Befunge::Ops::lib_run_instruction,
        'X'  => \&Language::Befunge::Ops::lib_run_instruction,
        'Y'  => \&Language::Befunge::Ops::lib_run_instruction,
        'Z'  => \&Language::Befunge::Ops::lib_run_instruction,
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Language::Befunge::Ops::Befunge98 - operations supported by a Befunge-98 interpreter

=head1 VERSION

version 5.000

=head1 DESCRIPTION

This module defines the operations supported by a Befunge-98 interpreter.
It's used internally when setting up a L::B::Interpreter.

The only subroutine defined is:

=over 4

=item get_ops_map()

return a mapping of the supported letter instructions with the associated
operations.

=back

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
