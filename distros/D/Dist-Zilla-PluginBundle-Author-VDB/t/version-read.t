#!perl
#   ---------------------------------------------------------------------- copyright and license ---
#
#   file: t/version-read.t
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
use POSIX qw{ locale_h };
use Test::Deep qw{ isa re };
use Test::More;
use Test::Routine;
use Test::Routine::Util;

with 'Test::Dist::Zilla::Build';

# Options to pass to the plugin.
has options => (
    isa         => 'HashRef',
    is          => 'ro',
    default     => sub { {} },
);

# I do not need `version` option — it is provided by the plugin.
around _build_dist => sub {
    my ( $orig, $self, @args ) = @_;
    my $dist = $self->$orig( @args );
    delete( $dist->{ version } );
    return $dist;
};

sub _build_plugins {
    my ( $self ) = @_;
    return [
        [ 'Author::VDB::Version::Read' => $self->options ],
    ];
};

sub _build_message_filter {
    my ( $self ) = @_;
    return sub {
        map(
            { ( my $r = $_ ) =~ s{^\[[^\[\]]*\] }{}; $r }
            grep( $_ =~ m{^\Q[Author::VDB::Version::Read]\E }, @_ )
        );
    };
};

test 'Version' => sub {
    my ( $self ) = @_;
    my $expected = $self->expected;
    if ( not exists( $expected->{ version } ) ) {
        plan skip_all => 'no expected version';
    };
    if ( $self->exception ) {
        plan skip_all => 'exception occurred';
    };
    is( $self->tzil->version, $expected->{ version }, 'version' );
};

# --------------------------------------------------------------------------------------------------

#   Some tests check error messages, which expected to be in English.
setlocale( LC_ALL, 'C' )
    or diag "*** Can't set \"C\" locale, some tests may fail! ***";

my $aborting = isa( 'Dist::Zilla::Role::ErrorLogger::Exception::Abort' );
    # REQUIRE: Dist::Zilla::Role::ErrorLogger v0.9.0

# --------------------------------------------------------------------------------------------------

plan tests => 8;

run_me 'Default' => {
    files => {
        'VERSION'       => '0.001',
        'version.txt'   => '0.002',
    },
    expected => {
        version => '0.001',     # By default version is read from `VERSION`.
    },
};

run_me 'File option does work' => {
    files => {
        'VERSION'       => '0.001',
        'version.txt'   => '0.070',
    },
    options => {
        file => 'version.txt',
    },
    expected => {
        version => '0.070',     # Version read from `version.txt`, not from default.
    },
};

run_me 'Trailing whitespace is ignored' => {
    files => {
        'VERSION'       => "0.011  \n  \n",
    },
    expected => {
        version => '0.011',
    },
};

run_me 'Dotted version is accepted' => {
    files => {
        'VERSION'       => "v0.7.1",
    },
    expected => {
        version => 'v0.7.1',
    },
};

run_me 'Version file does not exist' => {
    expected => {
        exception => $aborting,
        messages => [
            "Can't read version file 'VERSION': No such file or directory",
        ],
    },
};

run_me 'Invalid version is not accepted' => {
    files => {
        'VERSION'       => "v.0.7",
    },
    expected => {
        exception => $aborting,
        messages => [
            "Invalid version string 'v.0.7' at VERSION line 1",
        ],
    },
};

run_me 'Empty file name is not an error' => {
    files => {
        'VERSION'       => "v.0.7",
    },
    options => {
        file => '',
    },
    expected => {
        exception => re( qr{^\[DZ\] no version was ever set} ),
    },
};

run_me 'Absolute path is not allowed' => {
    options => {
        file => '/Version',
    },
    expected => {
        exception => $aborting,
        messages => [
            "Bad version file '/Version': absolute path is not allowed",
        ],
    },
};

done_testing;

exit( 0 );

# end of file #
