#!perl
#   ---------------------------------------------------------------------- copyright and license ---
#
#   file: t/hg-tag-check.t
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
use Path::Tiny;
use Test::Deep qw{ isa re };
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

# Default plugins to use in tests.
sub _build_plugins {
    return [
        '=BeforeBuild',
        'Author::VDB::Hg::Tag::Check',
        'FakeRelease',                  # REQUIRE: Dist::Zilla::Plugin::FakeRelease
    ];
};

sub _build_message_filter {
    my ( $self ) = @_;
    return sub {
        map(
            { ( my $r = $_ ) =~ s{^\[[^\[\]]*\] }{}; $r }
            grep( $_ =~ m{^\Q[Author::VDB::Hg::Tag::Check]\E }, @_ )
        );
    };
};

# `before_build` mechanics.
around release => sub {
    my ( $orig, $self, @args ) = @_;
    no warnings 'once';
    local $BeforeBuild::Hook = $self->before_build;
    return $self->$orig( @args );
};

my $aborting = isa( 'Dist::Zilla::Role::ErrorLogger::Exception::Abort' );
    # REQUIRE: Dist::Zilla::Role::ErrorLogger v0.9.0

# --------------------------------------------------------------------------------------------------

if ( not defined( which( 'hg' ) ) and not $ENV{ AUTHOR_TESTING } ) {
    plan skip_all => "no 'hg' found in PATH";
};

plan tests => 5;

run_me 'No repository' => {
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

#   Hook creates mercurial repository, the check should pass successfully.
run_me 'Check passes' => {
    before_build => sub {
        my ( $self ) = @_;
        $self->run_hg( 'init' );
    },
    expected => {
        exception => undef,
        messages => [
        ],
    },
};

run_me 'Tag already exists' => {
    before_build => sub {
        my ( $self ) = @_;
        $self->run_hg( 'init' );
        $self->run_hg( 'add', 'lib/Dummy.pm' );
        $self->run_hg( 'commit', '-m', 'Initial commit' );
        $self->run_hg( 'tag', '0.003' );
    },
    files => {
        'lib/Dummy.pm' => "package Dummy; 1;\n",
    },
    expected => {
        exception => $aborting,
        messages => [
            re( qr{^\QTag '0.003' already exists\E} ),
        ],
    },
};

run_me 'Local tag already exists' => {
    before_build => sub {
        my ( $self ) = @_;
        $self->run_hg( 'init' );
        $self->run_hg( 'add', 'lib/Dummy.pm' );
        $self->run_hg( 'commit', '-m', 'Initial commit' );
        $self->run_hg( 'tag', '-l', '0.003' );
    },
    files => {
        'lib/Dummy.pm' => "package Dummy; 1;\n",
    },
    expected => {
        exception => $aborting,
        messages => [
            re( qr{^\QTag '0.003' already exists\E} ),
        ],
    },
};

run_me 'Tag exists in future' => {
    before_build => sub {
        my ( $self ) = @_;
        my $root = path( $self->zilla->root );
        $self->run_hg( 'init' );
        $self->run_hg( 'add', 'lib/Dummy.pm' );
        $self->run_hg( 'commit', '-m', 'Initial commit' );
        $self->run_hg( 'tag', '0.001' );
        $root->child( 'lib/Dummy.pm' )->append( "# end of file #\n" );
        $self->run_hg( 'commit', '-m', 'The first change' );
        $self->run_hg( 'tag', '0.003' );
        $self->run_hg( 'update', '-r', '0.001' );
    },
    files => {
        'lib/Dummy.pm' => "package Dummy; 1;\n",
    },
    expected => {
        exception => $aborting,
        messages => [
            re( qr{^\QTag '0.003' already exists\E} ),
        ],
    },
};

done_testing;

exit( 0 );

# end of file #
