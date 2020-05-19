#! /usr/bin/env perl

use JSON::Karabiner::Manipulator;

set_filename 'TEST_4_finger_swipes_file_name';
set_title '4 finger swipes';
set_rule_name 'Double tap left-shift to swipe right';
new_manipulator;

add_action    'from';
add_key_code  'left_shift';

add_action    'to';
add_key_code  'left_arrow';
add_modifiers 'shift', 'control';

add_condition 'variable_if';
add_variable  'left_shift pressed', 1;


new_manipulator;

add_action        'from';
add_key_code      'left_shift';

add_action        'to';
add_set_variable  'left_shift pressed', '1';
add_key_code      'left_shift';

add_action        'to_delayed_if_invoked';
add_set_variable  'left_shift pressed', '0';

add_action        'to_delayed_if_canceled';
add_set_variable  'left_shift pressed', '0';


set_rule_name 'Double tap right-shift to swipe left';
new_manipulator;

add_action    'from';
add_key_code  'right_shift';

add_action    'to';
add_key_code  'right_arrow';
add_modifiers 'shift', 'control';

add_condition 'variable_if';
add_variable  'right_shift pressed', 1;


new_manipulator;

add_action        'from';
add_key_code      'right_shift';

add_action        'to';
add_set_variable  'right_shift pressed', '1';
add_key_code      'right_shift';

add_action        'to_delayed_if_invoked';
add_set_variable  'right_shift pressed', '0';

add_action        'to_delayed_if_canceled';
add_set_variable  'right_shift pressed', '0';

write_file;
