use Test::More qw[no_plan];
use strict;
$^W = 1;

use_ok 'Email::Folder::IMAP';

can_ok 'Email::Folder::IMAP', qw[new next_message messages];
