#!perl
#   ---------------------------------------------------------------------- copyright and license ---
#
#   file: t/version-bump.t
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

use strict;
use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC';
use utf8;
use version 0.77;
use warnings;

use Path::Tiny;
use Test::Deep qw{ isa re };
use Test::More;
use Test::Routine;
use Test::Routine::Util;

with 'Test::Dist::Zilla::Release';

# Project version.
has version => (
    isa         => 'Str',
    is          => 'ro',
);

# Options to pass to the plugin.
has options => (
    isa         => 'HashRef',
    is          => 'ro',
    default     => sub { {} },
);

#   Fix `version` option.
around _build_dist => sub {
    my ( $orig, $self, @args ) = @_;
    my $dist = $self->$orig( @args );
    $dist->{ version } = $self->version;
    return $dist;
};

sub _build_plugins {
    my ( $self ) = @_;
    return [
        'FakeRelease',                  # REQUIRE: Dist::Zilla::Plugin::FakeRelease
        [ 'Author::VDB::Version::Bump' => $self->options ],
    ];
};

sub _build_message_filter {
    my ( $self ) = @_;
    return sub {
        map(
            { ( my $r = $_ ) =~ s{^\[[^\[\]]*\] }{}; $r }
            grep( $_ =~ m{^\Q[Author::VDB::Version::Bump]\E }, @_ )
        );
    };
};

test 'Files' => sub {
    my ( $self ) = @_;
    my $expected = $self->expected;
    if ( not exists( $expected->{ files } ) ) {
        plan skip_all => 'no expected files';
    };
    if ( $self->exception ) {
        plan skip_all => 'exception occurred';
    };
    plan tests => keys( %{ $expected->{ files } } ) + 0;
    for my $name ( keys( %{ $expected->{ files } } ) ) {
        my $file = path( $self->tzil->root )->child( $name );
        my $bulk = $file->slurp();
        is( $bulk, $expected->{ files }->{ $name }, $name );
    };
};

my $aborting = isa( 'Dist::Zilla::Role::ErrorLogger::Exception::Abort' );
    # REQUIRE: Dist::Zilla::Role::ErrorLogger v0.9.0

# --------------------------------------------------------------------------------------------------

plan tests => 5;

run_me 'Default' => {
    version => '0.003',
    files => {
        'VERSION'       => '0.001',
    },
    expected => {
        files => {
            'VERSION'       => "0.003_01\n",    # Version bumped, original file content overwritten.
        },
    },
};

run_me 'File option does work' => {
    version => '0.004',
    files => {
        'VERSION'       => '0.001',
        'version.txt'   => '0.002',
    },
    options => {
        file => 'version.txt',
    },
    expected => {
        files => {
            'VERSION'       => '0.001',         # Not changed.
            'version.txt'   => "0.004_01\n",    # Bumped.
        },
    },
};

run_me 'Dotted version' => {
    version => 'v0.5.1',
    files => {
        'VERSION'       => '0.001',
    },
    expected => {
        files => {
            'VERSION'       => "v0.5.1_01\n",   # Bumped.
        },
    },
};

run_me 'No file' => {
    version => 'v0.5.1_01',
    expected => {
        files => {
            'VERSION'       => "v0.5.1_02\n",   # File is written anyway.
        },
    },
};

run_me 'Absolute file path' => {
    version => 'v0.5.1_02',
    options => {
        file => '/VERSION',
    },
    expected => {
        exception => $aborting,
        messages => [
            "Bad version file '/VERSION': absolute path is not allowed",
        ],
    },
};

done_testing;

exit( 0 );

# end of file #
