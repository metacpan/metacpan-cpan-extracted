use strict;
use warnings;
use Test::More;
use Git::Database;

use lib 't/lib';
use TestUtil;

my %methods_for = (
    'Git::Database::Role::Backend'      => ['hash_object'],
    'Git::Database::Role::ObjectReader' => [
        'get_object_meta', 'get_object_attributes',
        'get_object',      'has_object',
        'all_digests',
    ],
    'Git::Database::Role::ObjectWriter' => ['put_object'],
    'Git::Database::Role::RefReader'    => ['refs'],
    'Git::Database::Role::RefWriter'    => [ 'put_ref', 'delete_ref' ],
);

test_backends(
    sub {
        my ( $backend, $is_empty, $source ) = @_;
        my $class = ref $backend;

        # stuff we're sure of
        ok(
            $backend->does('Git::Database::Role::Backend'),
            "does Git::Database::Role::Backend"
        );
        ok( !$backend->can('zlonk'), "cant'( zlonk )" );

        for my $role ( sort keys %methods_for ) {
            if ( $backend->does($role) ) {
                ok( $backend->can($_), "can( $_ )" ) for @{ $methods_for{$role} };
            }
            else {
                ok( !$backend->can($_), "can't( $_ )" ) for @{ $methods_for{$role} };
            }
        }
    },
    '',    # test each backend once, with an empty repository
);

done_testing;
