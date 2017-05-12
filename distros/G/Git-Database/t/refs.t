use strict;
use warnings;
use Test::More;
use Git::Database;

use lib 't/lib';
use TestUtil;

test_backends(
    sub {
        my ( $backend, $is_empty, $source ) = @_;
        plan
          skip_all => sprintf '%s does not Git::Database::Role::RefReader',
          ref $backend
          if !$backend->does('Git::Database::Role::RefReader');

        my $refs = objects_from($source)->{refs};

        is_deeply( $backend->refs, $refs, 'refs' );

        is_deeply( [ $backend->ref_names ], [ sort keys %$refs ], 'ref_names' );

        is_deeply(
            [ $backend->ref_names('heads') ],
            [ sort grep m{^refs/heads/}, keys %$refs ],
            "ref_names('heads')"
        );

        is_deeply(
            [ $backend->ref_names('remotes/origin') ],
            [ sort grep m{^refs/remotes/origin/}, keys %$refs ],
            "ref_names('remotes/origin')"
        );

        is( $backend->ref_digest($_), $refs->{$_}, "ref_digest('$_')" )
          for (qw( HEAD refs/heads/master refs/remotes/origin/master nil ));

        if ( $backend->does('Git::Database::Role::RefWriter') ) {

            $backend->put_ref( 'refs/heads/master-tmp',
                $refs->{'refs/heads/master'} );
            is( $backend->ref_digest('refs/heads/master-tmp'),
                $refs->{'refs/heads/master'}, 'put_ref' );

            $backend->delete_ref('refs/heads/master-tmp');
            is( $backend->ref_digest('refs/heads/master-tmp'),
                undef, 'delete_ref' );
        }
    }
);

done_testing;
