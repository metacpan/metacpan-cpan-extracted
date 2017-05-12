use strict;
use warnings;
use Test::More tests => 1;
use FFI::Util qw( :types );

pass 'good';

diag '';
diag '';
diag "size_t = " . (eval { _size_t } || 'undef');
diag "time_t = " . (eval { _time_t } || 'undef');
diag "dev_t  = " . (eval { _dev_t  } || 'undef');
diag "gid_t  = " . (eval { _gid_t  } || 'undef');
diag "uid_t  = " . (eval { _uid_t  } || 'undef');
diag '';
diag '';
