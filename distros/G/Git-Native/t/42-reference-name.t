use Test2::V0;
use Git::Native;

# Valid names libgit2 should accept.
ok(  Git::Native->reference_name_is_valid('refs/heads/main'),        'valid branch ref' );
ok(  Git::Native->reference_name_is_valid('refs/karr/tasks/1/data'), 'valid nested ref' );
ok(  Git::Native->reference_name_is_valid('HEAD'),                   'HEAD is valid' );

# Invalid names.
ok( !Git::Native->reference_name_is_valid('refs/heads/bad..name'),   'double-dot rejected' );
ok( !Git::Native->reference_name_is_valid('refs/with space/x'),      'space rejected' );
ok( !Git::Native->reference_name_is_valid('refs/tilde~ref'),         'tilde rejected' );
ok( !Git::Native->reference_name_is_valid(''),                       'empty rejected' );
ok( !Git::Native->reference_name_is_valid(undef),                    'undef rejected' );

done_testing;
