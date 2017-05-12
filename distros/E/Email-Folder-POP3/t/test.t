use Test::More qw[no_plan];
use strict;
$^W = 1;

use_ok 'Email::Folder::POP3';

can_ok 'Email::Folder::POP3', qw[new next_message messages];
