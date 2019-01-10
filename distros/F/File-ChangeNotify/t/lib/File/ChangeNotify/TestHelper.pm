package File::ChangeNotify::TestHelper;

use strict;
use warnings;

use File::ChangeNotify;
use File::Path qw( mkpath rmtree );
use File::Spec;
use File::Temp qw( tempdir );
use Module::Runtime qw( use_module );

BEGIN {
    ## no critic (ErrorHandling::RequireCheckingReturnValueOfEval)
    eval {
        require Time::HiRes;
        Time::HiRes->import('stat');
    };
}

use Test2::V0;

use base 'Exporter';

## no critic (Modules::ProhibitAutomaticExportation)
our @EXPORT = qw( run_tests );
## use critic

## no critic (ValuesAndExpressions::ProhibitLeadingZeros)

sub run_tests {
    my @classes;
    if ( $ENV{FCN_CLASS} ) {
        @classes = $ENV{FCN_CLASS};
    }
    else {
        @classes = 'File::ChangeNotify::Watcher::Default';
        push @classes, File::ChangeNotify->usable_classes;
    }

    for my $class (@classes) {
        ( my $short = $class ) =~ s/^File::ChangeNotify::Watcher:://;

        # $class may just be something like "Default" if it came from an env var.
        my $long = 'File::ChangeNotify::Watcher::' . $short;
        use_module($long);

        subtest(
            "$short class",
            sub {
                subtest(
                    'blocking',
                    sub {
                        _shared_tests( $long, \&_blocking );
                    },
                );

                subtest(
                    'nonblocking',
                    sub {
                        _shared_tests( $long, \&_nonblocking );
                        subtest(
                            'exclude feature',
                            sub { _exclude_tests( $long, \&_nonblocking ) }
                        );
                        subtest( 'symlinks', sub { _symlink_tests($long) } );
                    },
                );
            },
        );
    }

    done_testing();
}

sub _blocking {
    my $watcher = shift;

    return $watcher->wait_for_events;
}

sub _nonblocking {
    my $watcher = shift;

    return $watcher->new_events;
}

sub _shared_tests {
    my @args = @_;
    subtest( 'single event basic tests', sub { _basic_tests(@args) } );
    subtest( 'multiple events',          sub { _multi_event_tests(@args) } );
    subtest( 'filter',                   sub { _filter_tests(@args) } );
    subtest( 'add/remove directory', sub { _dir_add_remove_tests(@args) } );
    subtest( 'create and rename', sub { _create_and_rename_tests(@args) } );
    subtest(
        'modify includes stat info',
        sub { _modify_file_attributes_tests(@args) }
    );
    subtest(
        'modify includes content',
        sub { _modify_content_tests(@args) }
    );
}

sub _basic_tests {
    my $class      = shift;
    my $events_sub = shift;

    my $dir = tempdir( CLEANUP => 1 );

    my $watcher = $class->new(
        directories     => $dir,
        follow_symlinks => 0,
        sleep_interval  => 0,
    );

    my $path = File::Spec->catfile( $dir, 'whatever' );
    create_file($path);

    _is_events(
        [ $events_sub->($watcher) ],
        [
            {
                path => $path,
                type => 'create',
            },
        ],
        "added one file ($path)",
    );

    modify_file($path);

    _is_events(
        [ $events_sub->($watcher) ],
        [
            {
                path => $path,
                type => 'modify',
            },
        ],
        "modified one file ($path)",
    );

    delete_file($path);

    _is_events(
        [ $events_sub->($watcher) ],
        [
            {
                path => $path,
                type => 'delete',
            },
        ],
        "deleted one file ($path)",
    );
}

sub _multi_event_tests {
    my $class      = shift;
    my $events_sub = shift;

    my $dir = tempdir( CLEANUP => 1 );

    my $watcher = $class->new(
        directories     => $dir,
        follow_symlinks => 0,
        sleep_interval  => 0,
    );

    my $path1 = File::Spec->catfile( $dir, 'whatever' );
    create_file($path1);
    modify_file($path1);
    delete_file($path1);

    my $path2 = File::Spec->catfile( $dir, 'another' );
    create_file($path2);
    modify_file($path2);

    if ( $watcher->sees_all_events ) {
        _is_events(
            [ $events_sub->($watcher) ],
            [
                {
                    path => $path1,
                    type => 'create',
                }, {
                    path => $path1,
                    type => 'modify',
                }, {
                    path => $path1,
                    type => 'delete',
                }, {
                    path => $path2,
                    type => 'create',
                }, {
                    path => $path2,
                    type => 'modify',
                },
            ],
            "added/modified/deleted $path1 and added/modified $path2",
        );
    }
    else {
        _is_events(
            [ $events_sub->($watcher) ],
            [
                {
                    path => $path2,
                    type => 'create',
                },
            ],
            "added/modified/deleted $path1 and added/modified $path2",
        );
    }
}

sub _create_and_rename_tests {
    my $class      = shift;
    my $events_sub = shift;

    my $dir = tempdir( CLEANUP => 1 );

    my $watcher = $class->new(
        directories     => $dir,
        follow_symlinks => 0,
        filter          => qr/\.txt/,
        sleep_interval  => 0,
    );

    my $path      = File::Spec->catfile( $dir, 'file.txt' );
    my $temp_path = File::Spec->catfile( $dir, 'file.txt-tmp' );

    create_file($temp_path);
    rename $temp_path, $path
        or die "Cannot rename $temp_path to $path: $!";

    my @events = $events_sub->($watcher);

    # The filter matches the temporary file as well as the final file, but
    # whether we get any events on the temporary file depends on the backend in
    # use. (KQueue on Mac OS doesn't report events for the temporary, but
    # Inotify on Linux does.) Changing the filter to match only the final file
    # would work, but the test would then hang under a version of Inotify that
    # isn't patched to treat IN_MOVED_TO as a 'create' event (because no events
    # would ever match). So ignore events that aren't for the final file.
    _is_events(
        [ grep { $_->path eq $path } @events ],
        [
            {
                path => $path,
                type => 'create',
            },
        ],
        'single creation event on final file for create/rename',
    );
}

sub _filter_tests {
    my $class      = shift;
    my $events_sub = shift;

    my $dir = tempdir( CLEANUP => 1 );

    my $watcher = $class->new(
        directories     => $dir,
        follow_symlinks => 0,
        filter          => qr/^foo/,
        sleep_interval  => 0,
    );

    my $path1 = File::Spec->catfile( $dir, 'not-included' );
    create_file($path1);
    modify_file($path1);
    delete_file($path1);

    my $path2 = File::Spec->catfile( $dir, 'foo.txt' );
    create_file($path2);

    _is_events(
        [ $events_sub->($watcher) ],
        [
            {
                path => $path2,
                type => 'create',
            },
        ],
        'file not matching filter is ignored but foo.txt is noted',
    );
}

sub _dir_add_remove_tests {
    my $class      = shift;
    my $events_sub = shift;

    my $dir = tempdir( CLEANUP => 1 );

    my $watcher = $class->new(
        directories     => $dir,
        follow_symlinks => 0,
        sleep_interval  => 0,
    );

    my $subdir1 = File::Spec->catdir( $dir, 'subdir1' );
    my $subdir2 = File::Spec->catdir( $dir, 'subdir2' );

    mkpath( $subdir1, 0, 0755 );
    rmtree($subdir1);

    mkpath( $subdir2, 0, 0755 );

    my $path = File::Spec->catfile( $subdir2, 'whatever' );
    create_file($path);

    if ( $watcher->sees_all_events ) {
        _is_events(
            [ $events_sub->($watcher) ],
            [
                {
                    path => $subdir1,
                    type => 'create',
                }, {
                    path => $subdir1,
                    type => 'delete',
                }, {
                    path => $subdir2,
                    type => 'create',
                }, {
                    path => $path,
                    type => 'create',
                },
            ],
            "created/delete $subdir1 and created one file ($path) in a new subdir ($subdir2)",
        );
    }
    else {
        _is_events(
            [ $events_sub->($watcher) ],
            [
                {
                    path => $subdir2,
                    type => 'create',
                }, {
                    path => $path,
                    type => 'create',
                },
            ],
            "created/delete $subdir1 and created one file ($path) in a new subdir ($subdir2)",
        );
    }

    rmtree($subdir2);

    _is_events(

        # The Default & Inotify watchers have different orders for these events
        [ sort { $a->path cmp $b->path } $events_sub->($watcher) ],
        [
            {
                path => $subdir2,
                type => 'delete',
            }, {
                path => $path,
                type => 'delete',
            },
        ],
        "deleted $subdir2",
    );
}

sub _exclude_tests {
    my $class      = shift;
    my $events_sub = shift;

    my $dir = tempdir( CLEANUP => 1 );

    my $watcher = $class->new(
        directories     => $dir,
        follow_symlinks => 0,
        sleep_interval  => 0,
        exclude         => [
            qr/\bignored-dir\b/,
            qr/\.ignore$/,
        ],
    );

    my $included = File::Spec->catfile( $dir, 'include' );
    create_file($included);

    _is_events(
        [ $events_sub->($watcher) ],
        [
            {
                path => $included,
                type => 'create',
            },
        ],
        "added/modified/deleted $included",
    );

    my $ignored_dir = File::Spec->catdir( $dir, 'ignored-dir' );
    mkpath( $ignored_dir, 0, 0755 );
    my $excluded = File::Spec->catfile( $ignored_dir, 'foo' );
    create_file($excluded);

    _is_events(
        [ $events_sub->($watcher) ],
        [],
        "created $excluded - should be ignored",
    );

    my $excluded_file = File::Spec->catfile( $dir, 'foo.ignore' );
    create_file($excluded_file);

    _is_events(
        [ $events_sub->($watcher) ],
        [],
        "created $excluded_file - should be ignored",
    );
}

sub _symlink_tests {
    my $class = shift;

    my $dir1 = tempdir( CLEANUP => 1 );
    my $dir2 = tempdir( CLEANUP => 1 );

    my $symlink = File::Spec->catfile( $dir1, 'other' );

    skip_all 'This platform does not support symlinks.'
        unless eval {
        ## no critic (InputOutput::RequireCheckedSyscalls)
        symlink $dir2 => $symlink;
        1;
        };

    my $watcher = $class->new(
        directories     => $dir1,
        follow_symlinks => 0,
        sleep_interval  => 0,
    );

    my $path = File::Spec->catfile( $dir2, 'file' );
    create_file($path);
    delete_file($path);

    _is_events(
        [ $watcher->new_events ],
        [],
        'no events for symlinked dir when not following symlinks',
    );

    $watcher = $class->new(
        directories     => $dir1,
        follow_symlinks => 1,
        sleep_interval  => 0,
    );

    create_file($path);

    my $expected_path = File::Spec->catfile( $symlink, 'file' );

    _is_events(
        [ $watcher->new_events ],
        [
            {
                path => $expected_path,
                type => 'create',
            },
        ],
        'one event for symlinked dir when following symlinks',
    );

    my $dir3 = tempdir( CLEANUP => 1 );

    symlink File::Spec->catdir( $dir3, '.' ),
        File::Spec->catdir( $dir3, 'self' )
        or die $!;
    symlink File::Spec->catfile( $dir3, 'input-circular1' ),
        File::Spec->catfile( $dir3, 'input-circular2' )
        or die $!;
    symlink File::Spec->catfile( $dir3, 'input-circular2' ),
        File::Spec->catfile( $dir3, 'input-circular1' )
        or die $!;

    ok(
        lives {
            File::ChangeNotify->instantiate_watcher(
                directories     => $dir3,
                follow_symlinks => 1,
            );
        },
        'made watcher for directory with circular symlinks'
    );
}

sub _modify_file_attributes_tests {
    my @args = @_;

    # These tests hang on Windows because Windows doesn't support chmod, so we
    # block waiting for an event in the blocking tests.
    skip_all('chmod does not work on Windows') if $^O eq 'MSWin32';

    subtest(
        'everything includes file_attributes',
        sub { _modify_file_attributes_on_everything_tests(@args) }
    );
    subtest(
        'some things includes file_attributes',
        sub { _modify_file_attributes_on_some_things_tests(@args) }
    );
}

sub _modify_file_attributes_on_everything_tests {
    my $class      = shift;
    my $events_sub = shift;

    my $dir = tempdir( CLEANUP => 1 );

    my $chmod_path = File::Spec->catfile( $dir, 'will-chmod' );
    create_file($chmod_path);
    chmod 0666, $chmod_path or die "Cannot chmod $chmod_path: $!";

    # We will also modify a file to make sure that we _don't_ include file
    # attributes in that modify event.
    my $content_path = File::Spec->catfile( $dir, 'will-modify-content' );
    create_file($content_path);

    my $watcher = $class->new(
        directories                     => $dir,
        follow_symlinks                 => 0,
        sleep_interval                  => 0,
        modify_includes_file_attributes => 1,
    );

    chmod 0600, $chmod_path or die "Cannot chmod $chmod_path: $!";
    modify_file($content_path);

    my @stat = stat $chmod_path;

    _is_events(
        [ sort { $a->path cmp $b->path } $events_sub->($watcher) ],
        [
            {
                path       => $chmod_path,
                type       => 'modify',
                attributes => [
                    {
                        permissions => 0666,
                        uid         => $stat[4],
                        gid         => $stat[5],
                    },
                    {
                        permissions => 0600,
                        uid         => $stat[4],
                        gid         => $stat[5],
                    },
                ],
            },
            {
                path => $content_path,
                type => 'modify',
            },
        ],
        'got stat info in modify event for file that had permissions change',
    );
}

sub _modify_file_attributes_on_some_things_tests {
    my $class      = shift;
    my $events_sub = shift;

    my $parent  = tempdir( CLEANUP => 1 );
    my $subdir1 = File::Spec->catdir( $parent, 'subdir1' );
    my $subdir2 = File::Spec->catdir( $parent, 'subdir2' );

    for my $d ( $subdir1, $subdir2 ) {
        mkpath( $d, 0, 0755 ) or die "Cannot mkpath $d: $!";
    }

    my $path1 = File::Spec->catfile( $subdir1, 'will-chmod' );
    my $path2 = File::Spec->catfile( $subdir2, 'will-chmod' );

    for my $p ( $path1, $path2 ) {
        create_file($p);
        chmod 0666, $p or die "Cannot chmod $p: $!";
    }

    my $watcher = $class->new(
        directories                     => $parent,
        follow_symlinks                 => 0,
        sleep_interval                  => 0,
        modify_includes_file_attributes => [qr/^\Q$subdir1/],
    );

    for my $p ( $path1, $path2 ) {
        chmod 0600, $p or die "Cannot chmod $p: $!";
    }

    my @stat = stat $path1;

    _is_events(
        [ $events_sub->($watcher) ],
        [
            {
                path       => $path1,
                type       => 'modify',
                attributes => [
                    {
                        permissions => 0666,
                        uid         => $stat[4],
                        gid         => $stat[5],
                    },
                    {
                        permissions => 0600,
                        uid         => $stat[4],
                        gid         => $stat[5],
                    },
                ],
            },
        ],
        'got stat info in modify event for path where modify includes file_attributes',
    );
}

sub _modify_content_tests {
    my @args = @_;

    subtest(
        'everything includes content',
        sub { _modify_content_on_everything_tests(@args) }
    );
    subtest(
        'some things includes content',
        sub { _modify_content_on_some_things_tests(@args) }
    );
}

sub _modify_content_on_everything_tests {
    my $class      = shift;
    my $events_sub = shift;

    my $dir = tempdir( CLEANUP => 1 );

    my $path = File::Spec->catfile( $dir, 'will-modify-content' );
    create_file( $path, "first\n" );

    my $watcher = $class->new(
        directories             => $dir,
        follow_symlinks         => 0,
        sleep_interval          => 0,
        modify_includes_content => 1,
    );

    modify_file( $path, "second\n" );

    _is_events(
        [ $events_sub->($watcher) ],
        [
            {
                path    => $path,
                type    => 'modify',
                content => [ "first\n", "first\nsecond\n" ],
            },
        ],
        'got content in modify event',
    );
}

sub _modify_content_on_some_things_tests {
    my $class      = shift;
    my $events_sub = shift;

    my $parent  = tempdir( CLEANUP => 1 );
    my $subdir1 = File::Spec->catdir( $parent, 'subdir1' );
    my $subdir2 = File::Spec->catdir( $parent, 'subdir2' );

    for my $d ( $subdir1, $subdir2 ) {
        mkpath( $d, 0, 0755 ) or die "Cannot mkpath $d: $!";
    }

    my $path1 = File::Spec->catfile( $subdir1, 'will-modify-content' );
    my $path2 = File::Spec->catfile( $subdir2, 'will-modify-content' );

    for my $p ( $path1, $path2 ) {
        create_file( $p, "first\n" );
    }

    my $watcher = $class->new(
        directories             => $parent,
        follow_symlinks         => 0,
        sleep_interval          => 0,
        modify_includes_content => [qr/^\Q$subdir1/],
    );

    for my $p ( $path1, $path2 ) {
        modify_file( $p, "second\n" );
    }

    _is_events(
        [ $events_sub->($watcher) ],
        [
            {
                path    => $path1,
                type    => 'modify',
                content => [ "first\n", "first\nsecond\n" ],
            },
            {
                path => $path2,
                type => 'modify',
            },
        ],
        'got content in modify event for path where modify includes content',
    );
}

sub _is_events {
    my $got      = shift;
    my $expected = shift;
    my $desc     = shift;

    is(
        $got,
        array {
            for my $e ( @{$expected} ) {
                item object {
                    call path => $e->{path};
                    call type => $e->{type};

                    if ( $e->{attributes} ) {

                        # The event's attributes method will return a two
                        # element array where each element is a hashref
                        # containing some keys like permissions, uid, etc. We
                        # don't want to check all the keys, just the ones we
                        # care about
                        call attributes => array {
                            for my $i ( 0, 1 ) {
                                item $i => hash {
                                    for my $k (
                                        sort
                                        keys %{ $e->{attributes}[$i] }
                                    ) {
                                        field $k => $e->{attributes}[$i]{$k};
                                    }
                                    end();
                                };
                            }
                            end();
                        };
                    }
                    else {
                        call has_attributes => F();
                    }

                    if ( $e->{content} ) {
                        call content => $e->{content};
                    }
                    else {
                        call has_content => F();
                    }
                };
            }
            end();
        },
        "$desc"
    );
}

sub create_file {
    my $path    = shift;
    my $content = shift;

    diag("Creating $path");

    open my $fh, '>', $path
        or die "Cannot write to $path: $!";
    if ( defined $content ) {
        print {$fh} $content
            or die "Cannot write to $path: $!";
    }
    close $fh
        or die "Cannot write to $path: $!";
}

sub modify_file {
    my $path    = shift;
    my $content = shift || "1\n";

    diag("Modifying $path");

    die "No such file $path!\n" unless -f $path;

    open my $fh, '>>', $path
        or die "Cannot write to $path: $!";
    print {$fh} $content
        or die "Cannot write to $path: $!";
    close $fh
        or die "Cannot write to $path: $!";
}

sub delete_file {
    my $path = shift;

    diag("Deleting $path");

    die "No such file $path!\n" unless -f $path;

    unlink $path
        or die "Cannot unlink $path: $!";
}

1;
