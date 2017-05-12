use strict;
use warnings;

# don't load extra subs, or run any import
use Module::Runtime     ();
use File::Spec          ();
use File::Temp          ();
use File::Basename      ();
use Test::Requires::Git ();

# Git::Database objects
use Git::Database::Object::Blob;
use Git::Database::Object::Tree;
use Git::Database::Object::Commit;
use Git::Database::Object::Tag;

use Git::Database::Backend::None;

our @kinds = qw( blob tree commit tag );

# all the following functions will end up in the caller's namespace

# test data
sub objects_from {
    my ($name) = @_;
    my $perl = File::Spec->catfile( 't', 'bundles', "$name.perl" );

    # slurp and eval the content of the file
    my $objects = do { local @ARGV = ($perl); local $/; eval <> }
      or die "Failed processing $perl";

    # add extra information
    for my $kind ( @kinds ) {
        for my $object ( @{ $objects->{$kind} } ) {
            $object->{kind} = $kind;
            $object->{desc} ||= join ' ', $object->{kind}, $object->{digest};
            $object->{sha1} = $object->{digest};
            $object->{size} ||= length $object->{content};
            $object->{string} ||= $object->{content};
            $object->{commit_info}{parents_digest} ||= []
              if $kind eq 'commit';
        }
    }

    return $objects;
}

sub repository_from {
    my ($name) = @_;
    my $bundle = File::Spec->catfile( qw( t bundles ), "$name.bundle" );
    my $dir = File::Temp::tempdir( CLEANUP => 1 );

    Test::Requires::Git::test_requires_git '1.6.5';
    `git clone -q $bundle $dir`;
    die "`git clone -q $bundle $dir` failed" if $?;

    return $dir;
}

sub empty_repository {
    my $dir = File::Temp::tempdir( CLEANUP => 1 );

    Test::Requires::Git::test_requires_git '1.6.5';
    `git init $dir`;
    die "`git init $dir` failed" if $?;

    return $dir;
}

# build a store from a repository directory
my %builder_for = (
    'None' => sub { '' },    # ignored by Git::Database::Backend::None
    'Cogit' => sub { Cogit->new( directory => shift ); },
    'Git'             => sub { Git->repository( Directory      => shift ); },
    'Git::PurePerl'   => sub { Git::PurePerl->new( directory   => shift ); },
    'Git::Repository' => sub { Git::Repository->new( work_tree => shift ); },
    'Git::Sub'        => sub { shift },
    'Git::Wrapper'    => sub { Git::Wrapper->new( shift ); },
    'Git::Raw::Repository' => sub { Git::Raw::Repository->open( shift ); },
);
my %min_version = (
    map ( { ( $_ => 0 ) } keys %builder_for ),
    'Git::Raw::Repository' => 0.74,
    'Git::Repository'      => 1.300,
    'Git::Sub'             => 0.163320,
);

sub store_for { return $builder_for{ $_[0] }->( $_[1] ); }

sub backend_for {
    Module::Runtime::use_module("Git::Database::Backend::$_[0]")
      ->new( store => store_for( $_[0], $_[1] ) );
}

# helpers
my %test_data;
for my $file ( glob File::Spec->catfile(qw( t bundles * )) ) {
    my ( $name, undef, $ext ) =
      File::Basename::fileparse( $file, qw( .perl .bundle ) );
    $test_data{$name}{$ext} = $file;
}

sub available_objects {
    return grep exists $test_data{$_}{'.perl'}, sort keys %test_data;
}

sub available_bundles {
    return grep exists $test_data{$_}{'.bundle'}, sort keys %test_data;
}

sub available_backends {
    return 'None',    # always available
      grep $_->VERSION >= $min_version{$_},
      map eval { Module::Runtime::use_module($_) },
      grep !/^None$/,
      sort keys %builder_for;
}

sub bundle_for { return $test_data{ $_[0] }{'.bundle'} }

# extra kind-specific tests
my %cmp_for = (
    tree => sub {
        my ( $tree, $test ) = @_;
        is_deeply(
            $tree->directory_entries,
            [
                sort { $a->filename cmp $b->filename }
                  @{ $test->{directory_entries} }
            ],
            '= directory_entries'
        );
    },
    commit => sub {
        my ( $commit, $test ) = @_;

        # can't use is_deeply here
        my $commit_info = $commit->commit_info;
        for my $attr (qw( tree_digest author_date committer_date comment encoding )) {
            is(
                $commit_info->{$attr},
                $test->{commit_info}{$attr},
                "= commit_info.$attr"
            );
        }
        for my $attr (qw( author committer )) {
            is(
                $commit_info->{$attr}->ident,
                $test->{commit_info}{$attr}->ident,
                "= commit_info.$attr"
            );
        }
        is(
            join( ' ', @{ $commit_info->{parents_digest} } ),
            join( ' ', @{ $test->{commit_info}{parents_digest} } ),
            '= commit_info.parents_digest'
        );
    },
    tag => sub {
        my ( $tag, $test ) = @_;

        # can't use is_deeply here
        my $tag_info = $tag->tag_info;
        for my $attr (qw( object type tag tagged_date comment )) {
            is( $tag_info->{$attr}, $test->{tag_info}{$attr},
                "= tag_info.$attr" );
        }
        is(
            $tag_info->{tagger}->ident,
            $test->{tag_info}{tagger}->ident,
            '= tag_info.tagger'
        );
    },
);

# test routines
sub cmp_git_objects {
    my ( $object, $test ) = @_;

    my $kind = $object->kind;
    isa_ok( $object, "Git::Database::Object::\u$kind" );

    # read content in memory early
    is( $object->kind,      $test->{kind},    "= kind: $test->{kind}" );
    is( $object->content,   $test->{content}, '= content' );
    is( $object->size,      $test->{size},    '= size' );
    is( $object->digest,    $test->{digest},  "= digest: $test->{digest}" );
    is( $object->as_string, $test->{string},  '= as_string' );

    # run the kind-specific tests
    $cmp_for{$kind}->( $object, $test ) if exists $cmp_for{$kind};
}

sub test_backends {
    my ( $code, @sources ) = @_;
    @sources = ( '', available_bundles() )
      if @sources == 1 && $sources[0] eq '*';

    # loop over all bundles if none given
    @sources = available_bundles() if !@sources;

    # loop over all available backends
    for my $backend ( available_backends() ) {

        for my $source (@sources) {

            # if we have a .bundle for the repository, connect the backend to it
            my ( $is_empty, $Backend ) =
              bundle_for($source)
              ? ( 0, backend_for( $backend, repository_from($source) ) )
              : ( 1, backend_for( $backend, empty_repository() ) );

            subtest(
                "$backend & " . ( $source || '<empty repository>' ),
                sub {
                    $code->( $Backend, $is_empty, $source );
                    done_testing;
                }
            );
        }
    }
}

sub test_kind {
    my %code_for = @_ == 1
      ? map +( $_ => $_[0] ), @kinds    # the same coderef for every kind
      : @_;                             # one coderef per kind

    # loop over all available object sources
    for my $source ( sort( available_objects() ) ) {
        my $objects = objects_from($source);

        # and all available backends
        for my $backend ( available_backends() ) {

            # if we have a .bundle for the repository, connect the backend to it
            my ( $is_empty, $Backend ) =
              bundle_for($source)
              ? ( 0, backend_for( $backend, repository_from($source) ) )
              : ( 1, backend_for( $backend, empty_repository() ) );

            # test all objects
            for my $kind (@kinds) {
                next
                  if !exists $code_for{$kind}
                  || !exists $objects->{$kind}
                  || !@{ $objects->{$kind} };
                subtest(
                    "$backend & $source ${kind}s",
                    sub {
                        $code_for{$kind}
                          ->( $Backend, $is_empty, @{ $objects->{$kind} } );
                        done_testing;
                    }
                );
            }
        }
    }
}
1;
