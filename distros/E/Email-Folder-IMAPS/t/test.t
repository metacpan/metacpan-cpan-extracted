use Test::More qw[no_plan];
use strict;
$^W = 1;

use_ok 'Email::Folder::IMAPS';

can_ok 'Email::Folder::IMAPS', qw[new next_message messages];
