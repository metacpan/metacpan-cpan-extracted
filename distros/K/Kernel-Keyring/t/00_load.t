use strict;
use warnings;

use Test::More tests => 1;

use_ok 'Kernel::Keyring', qw/
    key_add
    key_get_by_id
    key_timeout
    key_unlink
    key_session
    key_perm
    key_revoke
/;

