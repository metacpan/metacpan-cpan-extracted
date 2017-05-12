use Test::More tests => 5;

use_ok('Email::FolderType',qw(folder_type));

is(folder_type('t/testmaildir/'),    'Maildir');
is(folder_type('t/testmaildir'),     'Maildir');
is(folder_type('t/'),                'Maildir');
isnt(folder_type('t//'),             'Maildir');
