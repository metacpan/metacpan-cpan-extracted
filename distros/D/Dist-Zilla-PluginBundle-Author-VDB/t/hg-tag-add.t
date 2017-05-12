#!perl
#   ---------------------------------------------------------------------- copyright and license ---
#
#   file: t/hg-tag-add.t
#
#   Copyright © 2015 Van de Bugger
#
#   This file is part of perl-Dist-Zilla-PluginBundle-Author-VDB.
#
#   perl-Dist-Zilla-PluginBundle-Author-VDB is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by the Free Software
#   Foundation, either version 3 of the License, or (at your option) any later version.
#
#   perl-Dist-Zilla-PluginBundle-Author-VDB is distributed in the hope that it will be useful, but
#   WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
#   PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with
#   perl-Dist-Zilla-PluginBundle-Author-VDB. If not, see <http://www.gnu.org/licenses/>.
#
#   ---------------------------------------------------------------------- copyright and license ---

use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC';
use autodie ':all';                     # REQUIRE: IPC::System::Simple
use lib 't/lib';
use strict;
use utf8;
use version 0.77;
use warnings;

use File::Which;
use IPC::System::Simple qw{ capture };
use Path::Tiny;
use Test::Deep qw{ isa re cmp_deeply };
use Test::More;
use Test::Routine;
use Test::Routine::Util;

with 'Test::Dist::Zilla::Release';

# Code to execute before build.
has before_build => (
    isa         => 'CodeRef',
    is          => 'ro',
    default     => sub { sub {} },
);

# Code to execute after release.
has after_release => (
    isa         => 'CodeRef',
    is          => 'ro',
    default     => sub { sub {} },
);

# Options to pass to the plugin.
has options => (
    isa         => 'HashRef',
    is          => 'ro',
    default     => sub { {} },
);

# Default plugins to use in tests.
sub _build_plugins {
    my ( $self ) = @_;
    return [
        '=BeforeBuild',
        'FakeRelease',                  # REQUIRE: Dist::Zilla::Plugin::FakeRelease
        [ 'Author::VDB::Hg::Tag::Add' => $self->options ],
        '=AfterRelease',
    ];
};

sub _build_message_filter {
    my ( $self ) = @_;
    return sub {
        map(
            { ( my $r = $_ ) =~ s{^\[[^\[\]]*\] }{}; $r }
            grep( $_ =~ m{^\Q[Author::VDB::Hg::Tag::Add]\E }, @_ )
        );
    };
};

around release => sub {
    my ( $orig, $self, @args ) = @_;
    no warnings 'once';
    local $BeforeBuild::Hook  = $self->before_build;
    local $AfterRelease::Hook = $self->after_release;
    return $self->$orig( @args );
};

test 'Post-Release' => sub {
    my ( $self ) = @_;
    my $expected = $self->expected;
    if ( $self->exception ) {
        plan skip_all => 'exception occurred';
    };
    my $root    = path( $self->tzil->root );
    my $version = $self->tzil->version;
    my @tags = capture( 'hg', '--cwd', "$root", '-R', '.', 'tags' );
    $self->_anno_text( 'hg tags', @tags );
    @tags = grep( { $_ =~ m{ ^ \Q$version\E \s }x } @tags );
    is( @tags + 0, 1, 'tags' );
};

my $aborting = isa( 'Dist::Zilla::Role::ErrorLogger::Exception::Abort' );
    # REQUIRE: Dist::Zilla::Role::ErrorLogger v0.9.0

# --------------------------------------------------------------------------------------------------

if ( not defined( which( 'hg' ) ) and not $ENV{ AUTHOR_TESTING } ) {
    plan skip_all => "no 'hg' found in PATH";
};

plan tests => 6;

run_me 'No repository' => {
    expected => {
        exception => $aborting,
        messages => [
            re( qr{^\$ hg } ),
            re( qr{^stdout is empty$} ),
            re( qr{^stderr:$} ),
            re( qr{^    abort: (?:repository \. not found!|there is no Mercurial repository here \(\.hg not found\))$} ),
            re( qr{^Program hg exited with status 255$} ),
        ],
    },
};

# Repository created but there are no commits yet.
run_me 'No commits' => {
    before_build => sub {
        my ( $self ) = @_;
        $self->run_hg( 'init' );
    },
    expected => {
        exception => $aborting,
        messages => [
            'Oops, current changeset has null id',
        ],
    },
};

# Repository created, there are some commits, but there is no `.hgtags`.
run_me 'No .hgtags' => {
    files => {
        'README' => 'read me',
    },
    before_build => sub {
        my ( $self ) = @_;
        $self->run_hg( 'init' );
        $self->run_hg( 'add', 'dist.ini', 'README' );
        $self->run_hg( 'commit', '-m', 'First commit' );
    },
    after_release => sub {
        my ( $self ) = @_;
        #   Make sure the plugin added `.hgtags`.
        cmp_deeply( $self->run_hg( 'status', '.hgtags' ), [ "A .hgtags" ], '.hgtags status' );
        #   `Post-Release` test checks the tag by `hg tags` command. `hg` does not see new tag
        #   until it committed, so we have to commit `.hgtags` file to let the test pass.
        $self->run_hg( 'commit', '-m', 'Post-release commit', '.hgtags' );
    },
    expected => {
        messages => [],
    },
};

# Repository created, there are commits, `.hgtags` is in repository.
run_me 'All in place' => {
    files => {
        'README' => 'read me',
    },
    before_build => sub {
        my ( $self ) = @_;
        $self->run_hg( 'init' );
        $self->run_hg( 'add', 'dist.ini', 'README' );
        $self->run_hg( 'commit', '-m', 'First commit' );
        $self->run_hg( 'tag', 'initial' );      # Creates `.hgtags`.
    },
    after_release => sub {
        my ( $self ) = @_;
        #   Make sure the plugin changed `.hgtags`.
        cmp_deeply( $self->run_hg( 'status', '.hgtags' ), [ "M .hgtags" ], '.hgtags status' );
        #   `Post-Release` test checks the tag by `hg tags` command. `hg` does not see new tag
        #   until it committed, so we have to commit `.hgtags` file to let the test pass.
        $self->run_hg( 'commit', '-m', 'post-release', '.hgtags' );
    },
    expected => {
        messages => [],
    },
};

run_me 'Changed files' => {
    files => {
        'README' => '',
    },
    before_build => sub {
        my ( $self ) = @_;
        $self->run_hg( 'init' );
        $self->run_hg( 'add', 'dist.ini', 'README' );
        $self->run_hg( 'commit', '-m', 'First commit' );
        path( $self->zilla->root )->child( 'README' )->append( "read me\n" );
    },
    expected => {
        exception => $aborting,
        messages => [
            'The working directory has uncommitted changes',
        ],
    },
};

run_me 'Local tag' => {
    files => {
        'README' => 'read me',
    },
    options => {
        local => 1,
    },
    before_build => sub {
        my ( $self ) = @_;
        $self->run_hg( 'init' );
        $self->run_hg( 'add', 'dist.ini', 'README' );
        $self->run_hg( 'commit', '-m', 'First commit' );
    },
    expected => {
        messages => [],
    },
};

done_testing;

exit( 0 );

# end of file #
