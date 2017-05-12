use Test::More tests => 3;
$^W = 1;

use_ok 'Email::FolderType', 'folder_type';

can_ok __PACKAGE__, 'folder_type';

ok(Email::FolderType->matchers);



