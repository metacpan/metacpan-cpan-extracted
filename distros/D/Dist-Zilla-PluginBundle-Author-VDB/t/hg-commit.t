#!perl
#   ---------------------------------------------------------------------- copyright and license ---
#
#   file: t/hg-commit.t
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
use IPC::System::Simple qw{ capture $EXITVAL };
use Path::Tiny qw{ path tempdir };
use Test::Deep qw{ isa re cmp_deeply };
use Test::More;
use Test::Routine;
use Test::Routine::Util;

with 'Test::Dist::Zilla::Release';

my $Plugin = 'Author::VDB::Hg::Commit';     # Name of the plugin to test.

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

sub _build_files {
    my ( $self ) = @_;
    return {
        'README'    => "read me\n",
        'COPYING'   => "licemnse\n",
    };
};

# Default plugins to use in tests.
sub _build_plugins {
    my ( $self ) = @_;
    return [
        '=BeforeBuild',
        'FakeRelease',                  # REQUIRE: Dist::Zilla::Plugin::FakeRelease
        '=AfterRelease',
        [ $Plugin => $self->options ],
    ];
};

sub _build_message_filter {
    my ( $self ) = @_;
    return sub {
        map(
            { ( my $r = $_ ) =~ s{^\[[^\[\]]*\] }{}; $r }
            grep( $_ =~ m{^\Q[$Plugin]\E }, @_ )
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
    if ( not $expected->{ status } ) {
        plan skip_all => 'no expected status specified';
    };
    my $root = path( $self->tzil->root );
    my @status = capture( 'hg', '--cwd', "$root", '-R', '.', 'status' );
    chomp( @status );
    $self->_anno_text( "hg status", @status );
    cmp_deeply( \@status, $expected->{ status }, 'status' );
};

my $aborting = isa( 'Dist::Zilla::Role::ErrorLogger::Exception::Abort' );
    # REQUIRE: Dist::Zilla::Role::ErrorLogger v0.9.0

# --------------------------------------------------------------------------------------------------

if ( not defined( which( 'hg' ) ) and not $ENV{ AUTHOR_TESTING } ) {
    plan skip_all => "no 'hg' found in PATH";
};

plan tests => 5;

#   If no `file` option is specified, plugin does nothing.
run_me 'No file option' => {
    expected => {
        messages => [
        ],
    },
};

#   `message` option must not be empty.
run_me 'Empty message' => {
    options => {
        message => '',
    },
    expected => {
        exception => $aborting,
        messages => [
            'message option must not be empty',
        ],
    },
};

#   If `file` option is specified, the plugin will try to commit the file and fail because
#   there is no repository.
run_me 'No repository' => {
    options => {
        files => [ 'dist.ini' ],
    },
    expected => {
        exception => $aborting,
        messages => [
            re( qr{^\Q$ hg \E} ),
            re( qr{^\Qstdout is empty\E$} ),
            re( qr{^\Qstderr:\E$} ),
            re( qr{^\Q    abort: repository . not found!\E$} ),
            re( qr{^\QProgram hg exited with status 255\E$} ),
        ],
    },
};

sub init_repo {
    my ( $self ) = @_;
    $self->run_hg( 'init' );
    $self->run_hg( 'add', 'dist.ini', 'COPYING', 'README' );
    $self->run_hg( 'commit', '-m', '1st commit' );
};

sub change_files {
    my ( $self ) = @_;
    my $root = path( $self->zilla->root );
    $root->child( 'README' )->append( "new line\n" );
    $root->child( 'COPYING' )->append( "new line\n" );
};

run_me 'Commit multiple files' => {
    options => {
        files => [ 'COPYING', 'README' ],   # BTW: `files` option.
    },
    before_build => \&init_repo,
    after_release => \&change_files,
    expected => {
        messages => [
        ],
        status => [
            # No changed files expected.
        ],
    },
};

run_me 'Commit only specified file' => {
    options => {
        file => 'README',               # BTW: `file` option.
    },
    before_build => \&init_repo,
    after_release => \&change_files,
    expected => {
        messages => [
        ],
        status => [
            'M COPYING',
            #^^^^^^^^^ The file is not listed in `file` option and so should not be committed.
        ],
    },
};

done_testing;

exit( 0 );

# end of file #
