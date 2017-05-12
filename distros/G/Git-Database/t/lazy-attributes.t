use strict;
use warnings;
use Test::More;
use Git::Database;

use lib 't/lib';
use TestUtil;

# this set of tests mostly targets the builders:
#
# it creates the object with each supported attribute,
# lets the builders build the other attributes,
# and tests the results

test_kind(
    blob => sub {
        my ( $backend, $is_empty, @items ) = @_;
        my $is_reader = $backend->does('Git::Database::Role::ObjectReader');

        for my $test (@items) {
            subtest(
                $test->{desc},
                sub {

                    # digest
                    if ( $is_reader && !$is_empty ) {
                        is(
                            Git::Database::Object::Blob->new(
                                backend => $backend,
                                digest  => $test->{digest},
                              )->content,
                            $test->{content},
                            'digest -> content'
                        );
                        is(
                            Git::Database::Object::Blob->new(
                                backend => $backend,
                                digest  => $test->{digest},
                              )->size,
                            $test->{size},
                            'digest -> size'
                        );
                    }

                    # content
                    is(
                        Git::Database::Object::Blob->new(
                            backend => $backend,
                            content => $test->{content},
                          )->digest,
                        $test->{digest},
                        'content -> digest'
                    );
                    is(
                        Git::Database::Object::Blob->new(
                            backend => $backend,
                            content => $test->{content},
                          )->size,
                        $test->{size},
                        'content -> size'
                    );

                    done_testing;
                }
            );
        }
    },
    tree => sub {
        my ( $backend, $is_empty, @items ) = @_;
        my $is_reader = $backend->does('Git::Database::Role::ObjectReader');

        for my $test (@items) {
            subtest(
                $test->{desc},
                sub {

                    # digest
                    if ( $is_reader && !$is_empty ) {
                        is(
                            Git::Database::Object::Tree->new(
                                backend => $backend,
                                digest  => $test->{digest},
                              )->content,
                            $test->{content},
                            'digest -> content'
                        );
                        is(
                            Git::Database::Object::Tree->new(
                                backend => $backend,
                                digest  => $test->{digest},
                              )->size,
                            $test->{size},
                            'digest -> size'
                        );
                        is_deeply(
                            Git::Database::Object::Tree->new(
                                backend => $backend,
                                digest  => $test->{digest},
                              )->directory_entries,
                            [
                                sort { $a->filename cmp $b->filename }
                                  @{ $test->{directory_entries} }
                            ],
                            'digest -> directory_entries'
                        );
                    }

                    # content
                    is(
                        Git::Database::Object::Tree->new(
                            backend => $backend,
                            content => $test->{content}
                          )->digest,
                        $test->{digest},
                        'content -> digest'
                    );
                    is(
                        Git::Database::Object::Tree->new(
                            backend => $backend,
                            content => $test->{content}
                          )->size,
                        $test->{size},
                        'content -> size'
                    );
                    is_deeply(
                        Git::Database::Object::Tree->new(
                            backend => $backend,
                            content => $test->{content}
                          )->directory_entries,
                        [
                            sort { $a->filename cmp $b->filename }
                              @{ $test->{directory_entries} }
                        ],
                        'content -> directory_entries'
                    );

                    # directory_entries
                    is(
                        Git::Database::Object::Tree->new(
                            backend           => $backend,
                            directory_entries => $test->{directory_entries}
                          )->digest,
                        $test->{digest},
                        'directory_entries -> digest'
                    );
                    is(
                        Git::Database::Object::Tree->new(
                            backend           => $backend,
                            directory_entries => $test->{directory_entries}
                          )->content,
                        $test->{content},
                        'directory_entries -> content'
                    );
                    is(
                        Git::Database::Object::Tree->new(
                            backend           => $backend,
                            directory_entries => $test->{directory_entries}
                          )->size,
                        $test->{size},
                        'directory_entries -> size'
                    );

                    done_testing;
                }
            );
        }
    },
    commit => sub {
        my ( $backend, $is_empty, @items ) = @_;
        my $is_reader = $backend->does('Git::Database::Role::ObjectReader');

        for my $test (@items) {
            subtest(
                $test->{desc},
                sub {
                    # digest
                    if ( $is_reader && !$is_empty ) {
                        is(
                            Git::Database::Object::Commit->new(
                                backend => $backend,
                                digest  => $test->{digest}
                              )->content,
                            $test->{content},
                            'digest -> content'
                        );
                        is(
                            Git::Database::Object::Commit->new(
                                backend => $backend,
                                digest  => $test->{digest}
                              )->size,
                            $test->{size},
                            'digest -> size'
                        );
                        is_deeply(
                            Git::Database::Object::Commit->new(
                                backend => $backend,
                                digest  => $test->{digest}
                              )->commit_info,
                            $test->{commit_info},
                            'digest -> commit_info'
                        );
                    }

                    # content
                    is(
                        Git::Database::Object::Commit->new(
                            backend => $backend,
                            content => $test->{content}
                          )->digest,
                        $test->{digest},
                        'content -> digest'
                    );
                    is(
                        Git::Database::Object::Commit->new(
                            backend => $backend,
                            content => $test->{content}
                          )->size,
                        $test->{size},
                        'content -> size'
                    );
                    is_deeply(
                        Git::Database::Object::Commit->new(
                            backend => $backend,
                            content => $test->{content}
                          )->commit_info,
                        $test->{commit_info},
                        'content -> commit_info'
                    );

                    # commit_info
                    is(
                        Git::Database::Object::Commit->new(
                            backend     => $backend,
                            commit_info => $test->{commit_info}
                          )->digest,
                        $test->{digest},
                        'commit_info -> digest'
                    );
                    is(
                        Git::Database::Object::Commit->new(
                            backend     => $backend,
                            commit_info => $test->{commit_info}
                          )->content,
                        $test->{content},
                        'commit_info -> content'
                    );
                    is(
                        Git::Database::Object::Commit->new(
                            backend     => $backend,
                            commit_info => $test->{commit_info}
                          )->size,
                        $test->{size},
                        'commit_info -> size'
                    );

                    done_testing;
                }
            );
        }
    },
    tag => sub {
        my ( $backend, $is_empty, @items ) = @_;
        my $is_reader = $backend->does('Git::Database::Role::ObjectReader');

        for my $test (@items) {
            subtest(
                $test->{desc},
                sub {
                    # digest
                    if ( $is_reader && !$is_empty ) {
                        is(
                            Git::Database::Object::Tag->new(
                                backend => $backend,
                                digest  => $test->{digest}
                              )->content,
                            $test->{content},
                            'digest -> content'
                        );
                        is(
                            Git::Database::Object::Tag->new(
                                backend => $backend,
                                digest  => $test->{digest}
                              )->size,
                            $test->{size},
                            'digest -> size'
                        );
                        is_deeply(
                            Git::Database::Object::Tag->new(
                                backend => $backend,
                                digest  => $test->{digest}
                              )->tag_info,
                            $test->{tag_info},
                            'digest -> tag_info'
                        );
                    }

                    # content
                    is(
                        Git::Database::Object::Tag->new(
                            backend => $backend,
                            content => $test->{content}
                          )->digest,
                        $test->{digest},
                        'content -> digest'
                    );
                    is(
                        Git::Database::Object::Tag->new(
                            backend => $backend,
                            content => $test->{content}
                          )->size,
                        $test->{size},
                        'content -> size'
                    );
                    is_deeply(
                        Git::Database::Object::Tag->new(
                            backend => $backend,
                            content => $test->{content}
                          )->tag_info,
                        $test->{tag_info},
                        'content -> tag_info'
                    );

                    # tag_info
                    done_testing;
                }
            );
        }
    },
);

# additional attributes for the various kinds
my %extra = (
    tree   => 'directory_entries',
    commit => 'commit_info',
    tag    => 'tag_info',
);

# building attributes for an unknown object fails
test_backends(
    sub {
        my ( $backend, $is_empty, $source ) = @_;
        plan
          skip_all => sprintf '%s does not Git::Database::Role::ObjectReader',
          ref $backend
          if !$backend->does('Git::Database::Role::ObjectReader');

        for my $kind (qw( blob tree commit tag )) {

            ok( !eval { "Git::Database::Object::\u$kind"->new(); } );
            my $err =
                "One of 'digest' or 'content' "
              . ( $extra{$kind} ? "or '$extra{$kind}' " : '' )
              . "is required ";
            like( $@, qr/^$err/, '... expected error message' );

            # pick some random sha1
            my $sha1 = join '', map sprintf( '%02x', rand 256 ), 1 .. 20;
            $err  = qr/^$kind $sha1 not found in \Q$backend\E /;
            my $obj  = "Git::Database::Object::\u$kind"->new(
                digest  => $sha1,
                backend => $backend
            );

            ok( !eval { $obj->content }, "$kind content not found" );
            like( $@, $err, '... expected error message' );

            ok( !eval { $obj->size }, "$kind size not found" );
            like( $@, $err, '... expected error message' );

            if ( my $attr = $extra{$kind} ) {
                ok( !eval { $obj->$attr }, "$kind $attr not found" );
                like( $@, $err, '... expected error message' );
            }
        }
    },
    ''    # empty repository
);

done_testing;
