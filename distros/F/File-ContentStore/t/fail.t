use strict;
use warnings;
use Test::More;

use Path::Tiny ();
use File::ContentStore;

# non-existent directory
ok( !eval { File::ContentStore->new( path => 'does-not-exists' ); 1; },
    'Fails with non-existent directory' );
like(
    $@,
    qr{^Directory 'does-not-exists' does not exist},
    '... with the expected error message'
);

# non-existent digest
ok(
    !eval {
        File::ContentStore->new(
            path   => Path::Tiny->tempdir,
            digest => 'NoSuchHASH',
        );
        1;
    },
    'Fails with non-existent hash digest'
);
like(
    $@,
    qr{^Can't locate Digest/NoSuchHASH\.pm in \@INC },
    '... with the expected error message'
);

done_testing;
