use strict;
use warnings;
use Test::More;
use Git::Database;

use lib 't/lib';
use TestUtil;

# a database with no store
my $db = Git::Database->new();
ok(
    $db->does('Git::Database::Role::Backend'),
    'db does Git::Database::Role::Backend'
);

# test with
my $dir = empty_repository;
for my $backend ( available_backends() ) {

    # provide backend directly
    $db = backend_for( $backend, $dir );
    isa_ok( $db, "Git::Database::Backend::$backend" );
    isa_ok( $db->store, $backend )
      if $backend ne 'None' && $backend ne 'Git::Sub';

    # build backend from store
    $db = Git::Database->new( store => store_for( $backend, $dir ) );
    isa_ok( $db, "Git::Database::Backend::$backend" );
    isa_ok( $db->store, $backend )
      if $backend ne 'None' && $backend ne 'Git::Sub';
}

# some error cases
ok(
    !eval { $db = Git::Database->new( store => bless( {}, 'Nope' ) ) },
    'Git::Database::Backend::Nope does not exist'
);
like(
    $@,
    qr{^Can't locate Git/Database/Backend/Nope.pm in \@INC },
    '... expected error message'
);


done_testing;
