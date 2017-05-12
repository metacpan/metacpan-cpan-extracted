#!perl
#   ---------------------------------------------------------------------- copyright and license ---
#
#   file: t/hg-push.t
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

our $Test;

with 'Test::Dist::Zilla::Release';

# Code to execute before build.
has before_build => (
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

has repos => (
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
        [ 'Author::VDB::Hg::Push' => $self->options ],
    ];
};

sub _build_message_filter {
    my ( $self ) = @_;
    return sub {
        #   I am not interested in output from other plugins, so let me grep output of Hg::Push
        #   plugin first:
        my @lines = map(
            { ( my $r = $_ ) =~ s{^\[[^\[\]]*\] }{}; $r }
            grep( $_ =~ m{^\Q[Author::VDB::Hg::Push]\E }, @_ )
        );
        #   Older versions of hg print messages to stdout (for example, "pushing to ...") but newer
        #   versions do not. Let us drop stdout completely so the test does not depend on hg
        #   version:
        my $text = join( "\n", @lines, '' );    # '' adds nl to the last line.
        $text =~ s{^stdout.*\n(    .*\n)*}{}m;
        return split( "\n", $text );
    };
};

around release => sub {
    my ( $orig, $self, @args ) = @_;
    no warnings 'once';
    local $Test               = $self;
    local $BeforeBuild::Hook  = $self->before_build;
    return $self->$orig( @args );
};

test 'Post-Release' => sub {
    my ( $self ) = @_;
    my $expected = $self->expected;
    if ( $self->exception ) {
        plan skip_all => 'exception occurred';
    };
    my $root = path( $self->tzil->root );
    my $repos = $self->repos;
    while ( my ( $repo, $dir ) = each( %$repos ) ) {
        my @outgoing = capture( [ 0 .. 1 ], 'hg', '--cwd', "$root", '-R', '.', 'outgoing', "$dir" );
        chomp( @outgoing );
        is( $EXITVAL, 1, 'hg outgoing status' );
        cmp_deeply(
                \@outgoing,
            [ "comparing with $dir", "searching for changes", "no changes found" ],
            "outgoing $repo",
        ) or $self->_anno_text( "hg outgoing $repo", @outgoing );
    };
};

my $aborting = isa( 'Dist::Zilla::Role::ErrorLogger::Exception::Abort' );
    # REQUIRE: Dist::Zilla::Role::ErrorLogger v0.9.0

# --------------------------------------------------------------------------------------------------

if ( not defined( which( 'hg' ) ) and not $ENV{ AUTHOR_TESTING } ) {
    plan skip_all => "no 'hg' found in PATH";
};

plan tests => 4;

run_me 'No repository' => {
    expected => {
        exception => $aborting,
        messages => [
            re( qr{^\$ hg } ),
            re( qr{^stderr:$} ),
            re( qr{^    abort: repository \. not found!$} ),
            re( qr{^Program hg exited with status 255$} ),
        ],
    },
};

# Initialize remote and local repositories.
sub init_repos {
    my ( $plugin ) = @_;
    my $repos = $Test->{ repos } ;
    # Initialize remote repos.
    for my $repo ( keys( %$repos ) ) {
        if ( not $repos->{ $repo } ) {
            $repos->{ $repo } = tempdir();
        };
        $plugin->run_hg( 'init', $repos->{ $repo } );
    };
    # Initialize local repo.
    $plugin->run_hg( 'init' );
    $plugin->run_hg( 'add', 'dist.ini', 'README' );
    $plugin->run_hg( 'commit', '-m', '1st commit' );
    path( $plugin->zilla->root )->child( '.hg/hgrc' )->spew(
        "[paths]\n",
        map( { "$_ = $repos->{ $_ }\n" } keys( %$repos ) ),
    );
};

run_me 'No default remote repository' => {
    files => {
        'README' => 'read me',
    },
    before_build => \&init_repos,
    expected => {
        exception => $aborting,
        messages => [
            re( qr{^\$ hg } ),
            re( qr{^stderr:$} ),
            re( qr{^    abort: repository default (?:not found|does not exist)!$} ),
            re( qr{^Program hg exited with status 255$} ),
        ],
    },
};

run_me 'Push to default repository' => {
    files => {
        'README' => 'read me',
    },
    repos => {
        default => undef,
    },
    before_build => \&init_repos,
    expected => {
    },
};

run_me 'Push to two repositories' => {
    files => {
        'README' => 'read me',
    },
    repos => {
        default => undef,
        another => undef,
    },
    options => {
        repository => [ 'default', 'another' ],
    },
    before_build => \&init_repos,
    expected => {
    },
};

done_testing;

exit( 0 );

# end of file #
