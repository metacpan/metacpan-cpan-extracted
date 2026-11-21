#!/usr/bin/env perl
use 5.020;
use strict;
use warnings FATAL => 'all';
use re '/aasx';

use Test2::V1 -i;    ## no critic (ProhibitUnusedImports) the T2 handle, which the policy does not see used
use Test2::Plugin::NoWarnings;
use Test::DZil   qw{Builder simple_ini};
use File::Temp   ();
use Git::Wrapper ();
use File::pushd  ();
use FindBin::libs;

T2->skip_all('set RELEASE_TESTING=1 to run the tests against real git repositories') unless $ENV{RELEASE_TESTING};

# Each repository here is a scratch one.  git must not read the configuration
# of the person who runs the tests, and must not write to the repository that
# runs them, which it would do if a hook left GIT_DIR or GIT_INDEX_FILE set.
delete @ENV{ grep { /^GIT_/ } keys %ENV };
my $empty_config = File::Temp->new;
local $ENV{GIT_CONFIG_GLOBAL}   = $empty_config->filename;
local $ENV{GIT_CONFIG_NOSYSTEM} = 1;
local $ENV{GIT_AUTHOR_NAME}     = 'A. Tester';
local $ENV{GIT_AUTHOR_EMAIL}    = 'tester@test.test';
local $ENV{GIT_COMMITTER_NAME}  = 'A. Tester';
local $ENV{GIT_COMMITTER_EMAIL} = 'tester@test.test';

my $PREAMBLE = "Revision history for DZT\n\n";
my $FORMAT   = '%v %{yyyy-MM-dd}d';
my @BASIC    = ( 'GatherDir', [ 'Git::ChangelogFromTrailers' => { format => $FORMAT } ] );

# A distribution in a new git repository, with the plugins given.  With no
# changes given, the repository has no Changes.
sub dist {
    my (%args) = @_;
    my %files = (
        'source/dist.ini'   => simple_ini( @{ $args{plugins} } ),
        'source/lib/DZT.pm' => "package DZT;\n1;\n",
        'source/.gitignore' => ".build/\n",
    );
    $files{'source/Changes'} = $args{changes} if defined $args{changes};
    my $tzil = Builder->from_config( { dist_root => File::Temp->newdir()->dirname }, { add_files => \%files } );
    my $git  = Git::Wrapper->new( $tzil->root->stringify );
    $git->init( { initial_branch => 'master' } );
    return ( $tzil, $git );
}

# Commit everything, with the message given, at a time that only goes forward,
# so that the order of the commits does not depend on how fast the test runs.
my $clock = 1_700_000_000;

sub commit {
    my ( $git, $message ) = @_;
    $clock += 60;
    local $ENV{GIT_AUTHOR_DATE}    = "\@$clock +0000";
    local $ENV{GIT_COMMITTER_DATE} = "\@$clock +0000";
    $git->add('.');
    $git->commit( { message => $message, allow_empty => 1 } );
    return;
}

# The header that the plugin writes for this version today.
sub header {
    my ($tzil) = @_;
    return $tzil->plugin_named(q{Git::ChangelogFromTrailers})->section_header;
}

T2->subtest(
    'with no release tag, the trailers of every commit go in, oldest first' => sub {
        my ( $tzil, $git ) = dist( plugins => \@BASIC, changes => $PREAMBLE );
        commit( $git, "Start\n\nChangelog: First change" );
        commit( $git, "No trailer here\n\nJust a body that mentions Changelog: in passing." );
        commit( $git, "Two at once\n\nchangelog: Second change\nSigned-off-by: A. Tester <tester\@test.test>\nChangelog: Third change\n  that wraps" );
        commit( $git, "Merge the branch\n\nChangelog: Second change" );

        $tzil->build;
        T2->is(
            $tzil->slurp_file(q{build/Changes}),
            $PREAMBLE . header($tzil) . "\n    - First change\n    - Second change\n    - Third change that wraps\n",
            'one item per trailer, in commit order, with the key in any case, joined lines, and no repeats'
        );
        T2->is( $tzil->slurp_file('source/Changes'), $PREAMBLE, 'a build does not change Changes in the repository' );
    }
);

T2->subtest(
    'only the commits after the last release tag count' => sub {
        my $old = "0.001 2026-01-01\n    - Old change\n";
        my ( $tzil, $git ) = dist( plugins => \@BASIC, changes => $PREAMBLE . $old );
        commit( $git, "Old\n\nChangelog: Old change" );
        $git->tag('0.001');

        # A higher tag that HEAD cannot reach belongs to another branch.
        $git->checkout( { b => 'other' } );
        commit( $git, "Elsewhere\n\nChangelog: On another branch" );
        $git->tag('9.000');
        $git->checkout('master');

        commit( $git, "New\n\nChangelog: New change" );

        $tzil->build;
        T2->is( $tzil->slurp_file(q{build/Changes}), $PREAMBLE . header($tzil) . "\n    - New change\n\n$old", 'the entry has only the new trailer, above the entries that were there' );
    }
);

T2->subtest(
    'with no new trailers, the build leaves Changes alone and the release stops' => sub {
        my ( $tzil, $git ) = dist( plugins => [ @BASIC, 'FakeRelease' ], changes => $PREAMBLE );
        commit( $git, "Old\n\nChangelog: Old change" );
        $git->tag('0.001');
        commit( $git, 'Tidy, which nobody needs to read about' );

        $tzil->build;
        T2->is( $tzil->slurp_file(q{build/Changes}), $PREAMBLE, 'Changes in the build is the one in the repository' );

        my $error = T2->dies( sub { $tzil->release } );
        T2->like( $error, qr/no\ Changelog\ trailers/, 'the release says why it stopped' );
    }
);

T2->subtest(
    'a release with no Changes makes one, and Git::Commit commits it' => sub {
        my $plugins = [ @BASIC, [ 'Git::Commit' => { allow_dirty => 'Changes' } ], 'FakeRelease' ];
        my ( $tzil, $git ) = dist( plugins => $plugins );
        commit( $git, "Start\n\nChangelog: A change" );

        {
            # Git::Commit writes its message to a file in the current directory.
            my $in_root = File::pushd::pushd( $tzil->root );    ## no critic (ProhibitUnusedVarsStricter) a guard, which goes back when it goes out of scope
            $tzil->release;
        }

        T2->is( $tzil->slurp_file(q{source/Changes}),                                "Revision history for DZT-Sample\n\n" . header($tzil) . "\n    - A change\n", 'Changes in the repository has the preamble and the entry' );
        T2->is( [ $git->status->get(qw{changed indexed unknown}) ],                  [],                                                                           'nothing is left uncommitted' );
        T2->is( [ $git->show( { pretty => 'format:', name_status => 1 }, 'HEAD' ) ], ["A\tChanges"],                                                               'the release commit adds Changes' );
    }
);

T2->subtest(
    'below Git::Commit, the release stops before it starts' => sub {
        my $plugins = [ 'GatherDir', 'Git::Commit', [ 'Git::ChangelogFromTrailers' => { format => $FORMAT } ], 'FakeRelease' ];
        my ( $tzil, $git ) = dist( plugins => $plugins, changes => $PREAMBLE );
        commit( $git, "Start\n\nChangelog: A change" );

        my $error = T2->dies( sub { $tzil->release } );
        T2->like( $error, qr/must\ be\ above\ \[Git::Commit\]/, 'the release says what to move' );
        T2->is( $tzil->slurp_file('source/Changes'), $PREAMBLE, 'and Changes in the repository is unchanged' );
    }
);

T2->done_testing;
