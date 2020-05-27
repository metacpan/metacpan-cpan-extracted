#! /usr/bin/env perl

use JSON::Karabiner::Manipulator;

set_title 'some title';
set_rule_name 'some rule name';

new_manipulator;

add_action 'from';
add_key_code 'a';
add_action 'to';
add_key_code '9';

write_file();
