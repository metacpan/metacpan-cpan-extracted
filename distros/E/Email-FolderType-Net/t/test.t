use Test::More tests => 5;
use strict;
$^W = 1;

BEGIN {
    use_ok 'Email::FolderType', qw[folder_type];
}

is folder_type('imap://example.com'), 'IMAP', 'IMAP folder';
is folder_type('imaps://user@example.com'), 'IMAPS', 'IMAPS folder';
is folder_type('pop://user@example.com'), 'POP3', 'POP3 folder';
is folder_type('pops://user@example.com'), 'POP3S', 'POP3S folder';




