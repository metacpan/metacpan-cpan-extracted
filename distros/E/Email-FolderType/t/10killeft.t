use Test::More tests => 2;

use Email::FolderType qw[folder_type];

ok ! eval "folder_type", $@;
ok ! eval "folder_type('foo','bar')", $@;
