use Test::More tests => 2;

use_ok('Email::FolderType',qw(folder_type));

is(folder_type('t/testmh/.'), 'MH');
