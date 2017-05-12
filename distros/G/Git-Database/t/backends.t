use strict;
use warnings;
use Test::More;
use Git::Database;

use lib 't/lib';
use TestUtil;

our @kinds;    # set by TestUtil

# different object kinds work with different possible arguments
my %args_for = (
    blob => sub {
        return
          [ content => $_[0]->{content} ],
          ;
    },
    tree => sub {
        return
          [ content           => $_[0]->{content} ],
          [ directory_entries => $_[0]->{directory_entries} ],
          ;
    },
    commit => sub {
        return
          [ content     => $_[0]->{content} ],
          [ commit_info => $_[0]->{commit_info} ],
          ;
    },
    tag => sub {
        return
          [ content  => $_[0]->{content} ],
          [ tag_info => $_[0]->{tag_info} ],
          ;
    },
);

diag "Available backends:";
diag "- $_" for available_backends();

test_kind(
    sub {
        my ( $backend, $is_empty, @objects ) = @_;
        my $is_reader = $backend->does('Git::Database::Role::ObjectReader');
        my $is_writer = $backend->does('Git::Database::Role::ObjectWriter');

        # figure out the store class
        my $class = substr( ref $backend, 24 );  # drop Git::Database::Backend::

        # a database pointing to an empty repository
        my $nil =
          Git::Database->new( store => store_for( $class, empty_repository ) );

        # pick some random sha1 and check it's not in the empty repository
        if ($is_reader) {
            my $sha1 = join '', map sprintf( '%02x', rand 256 ), 1 .. 20;
            is( $nil->has_object($sha1), '', "has_object fails with $sha1" );
            is( $nil->get_object($sha1),
                undef, "get_object fails with $sha1 (scalar context)" );
            is_deeply( [ $nil->get_object($sha1) ],
                [undef], "get_object fails with $sha1 (list context)" );
            is( $nil->get_object_attributes($sha1),
                undef,
                "get_object_attributes fails with $sha1 (scalar context)" );
            is_deeply( [ $nil->get_object_attributes($sha1) ],
                [undef],
                "get_object_attributes fails with $sha1 (list context)" );
        }

        my %nil_contains;
        for my $test (@objects) {
            my ( $kind, $digest, $size ) = @{$test}{qw( kind digest size )};

            subtest(
                $test->{desc},
                sub {

                    for my $args ( $args_for{$kind}->($test) ) {

                        # various ways to create an object
                        for my $object (
                            "Git::Database::Object::\u$kind"->new(@$args),
                            $nil->create_object( kind => $kind, @$args )
                          )
                        {
                            is( $nil->hash_object($object),
                                $test->{digest},
                                "hash_object: $test->{digest}" );
                            cmp_git_objects( $object, $test );
                        }
                    }

                    done_testing;
                }
            );

            # check the object can't be found in an empty repository
            subtest(
                "$test->{desc} [not found in empty repository]",
                sub {

                    # object is not in the empty database
                    plan
                      skip_all => 'The empty tree is a special case in Git',
                      if $kind eq 'tree'
                      && $digest eq '4b825dc642cb6eb9a060e54bf8d69288fbee4904';

                  SKIP: {
                        skip "$digest has already been added to $backend", 3
                          if $nil_contains{$digest};

                        # has_object
                        ok(
                            !$nil->has_object($digest),
                            "has_object( $digest ): missing"
                        );

                        # get_object_meta
                        is_deeply(
                            [ $nil->get_object_meta($digest) ],
                            [ $digest, 'missing', undef ],
                            "get_object_meta( $digest ): missing"
                        );

                        # get_object
                        is( $nil->get_object($digest),
                            undef, "get_object( $digest ): missing" );
                    }

                    # add the object to the database
                    if ($is_writer) {
                        is(
                            $nil->put_object(
                                "Git::Database::Object::\u$kind"->new(
                                    content => $test->{content}
                                )
                            ),
                            $digest,
                            "put_object: $digest"
                        );
                        cmp_git_objects( $nil->get_object($digest), $test );
                        $nil_contains{$digest}++;
                    }

                    done_testing;
                }
            ) if $is_reader;

            # check the object can be found in its own repository
            subtest(
                "$test->{desc} [found in its own repository]",
                sub {
                    # has_object
                    ok( $backend->has_object($digest), "has_object( $digest )" );

                    # get_object_meta
                    is_deeply(
                        [ $backend->get_object_meta($digest) ],
                        [ $digest, $kind, $test->{size} ],
                        "get_object_meta( $digest )"
                    );

                    # fetching the object
                    cmp_git_objects( $backend->get_object($digest), $test );

                    # create the object with only the digest
                    cmp_git_objects(
                        "Git::Database::Object::\u$kind"->new(
                            backend => $backend,
                            digest  => $test->{digest},
                        ),
                        $test
                    );

                    done_testing;
                }
            ) if $is_reader && !$is_empty;

        }
    }
);

# all_digests
test_backends(
    sub {
        my ( $backend, $is_empty, $source ) = @_;
        plan
          skip_all => sprintf '%s does not Git::Database::Role::ObjectReader',
          ref $backend
          if !$backend->does('Git::Database::Role::ObjectReader');

        if ($is_empty) {
            is_deeply( [ $backend->all_digests ],
                [], "Empty repository contains no digests" );
            return;
        }

        my $objects = objects_from($source);
        my %digests = map +(
            $_ => do {
                my %s;
                [ grep !$s{$_}++, sort map $_->{digest}, @{ $objects->{$_} } ];
              }
          ),
          @kinds;

        is_deeply( [ $backend->all_digests($_) ],
            $digests{$_}, "all_digests( $_ )" )
          for sort keys %digests;

        is_deeply(
            [ $backend->all_digests ],
            [ sort map @$_, values %digests ],
            'all_digests( )'
        );

        # abbreviated digests
        if ( $source eq 'ambiguous' ) {

            # one known case of ambiguous abbreviated digest
            is( $backend->get_object('577ecc'),
                undef, "get_object( ambiguous ) fails" );
        }
        else {
            my $digest = $objects->{commit}[0]{digest};
            my $abbrev = substr( $digest, 0, 4 );

            # get the object from the abbreviated id
            my $object = $backend->get_object($abbrev);
            ok( defined $object, "get_object( $abbrev )" );
            is( $backend->get_object($abbrev)->digest,
                $digest, "$abbrev -> $digest" )
              if $object;
        }
    },
    '*'    # all bundles, and an empty repository
);

done_testing;
