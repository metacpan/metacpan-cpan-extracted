#   ---------------------------------------------------------------------- copyright and license ---
#
#   file: t/lib/ManifestWriteTester.pm
#
#   Copyright © 2015, 2016 Van de Bugger.
#
#   This file is part of perl-Dist-Zilla-Plugin-Manifest-Write.
#
#   perl-Dist-Zilla-Plugin-Manifest-Write is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by the Free Software
#   Foundation, either version 3 of the License, or (at your option) any later version.
#
#   perl-Dist-Zilla-Plugin-Manifest-Write is distributed in the hope that it will be useful, but
#   WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
#   PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with
#   perl-Dist-Zilla-Plugin-Manifest-Write. If not, see <http://www.gnu.org/licenses/>.
#
#   ---------------------------------------------------------------------- copyright and license ---

package ManifestWriteTester;

#   The test is written using `Moose`-based `Test::Routine`. It is not big deal, because we are
#   testing plugin for `Dist::Zilla`, and `Dist-Zilla` is also `Moose`-based.

use autodie ':all';
use namespace::autoclean;
use version 0.77;

use Archive::Tar qw{};
use ExtUtils::Manifest qw{};
use Path::Tiny;
use Set::Object;
use Test::Deep qw{ re cmp_deeply };
use Test::More;
use Test::Routine;
use Try::Tiny;

with 'Test::Dist::Zilla::Build' => { -version => 'v0.4.3' };    # need skip_if_exception

#   Name of the plugin to test. By default 'Manifest::Write', but some tests use non-default name.
has name => (
    isa         => 'Str',
    is          => 'ro',
    default     => 'Manifest::Write',
);

has extra_files => (
    isa         => 'HashRef',
    is          => 'ro',
    default     => sub { {} },
);

sub _build_files {
    my ( $self ) = @_;
    return {
        'lib/Dummy.pm' => [
            'package Dummy.pm;',
            '',     # Empty line for `PkgVersion`.
            '1;',
        ],
        %{ $self->extra_files },
    };
};

sub _build_message_filter {
    my ( $self ) = @_;
    return sub {
        map(
            { ( my $r = $_ ) =~ s{^\[[^\]]*\] }{}; $r }
            grep( $_ =~ m{\Q[@{[ $self->name ]}]\E }, @_ )
        );
    };
};

has options => (
    isa         => 'HashRef',
    is          => 'ro',
    default     => sub { {} },
);

has extra_plugins => (
    isa         => 'ArrayRef',
    is          => 'ro',
    default     => sub { [] },
);

sub _build_plugins {
    my ( $self ) = @_;
    return [
        'GatherDir',                # REQUIRE: Dist::Zilla::Plugin::GatherDir
        'MetaYAML',                 # REQUIRE: Dist::Zilla::Plugin::MetaYAML
        [ 'Manifest::Write' => $self->options ],
        @{ $self->extra_plugins },
    ];
};

#   Regular expression to match against the first line of manifest written by `Manifest::Write`.
has first_line => (
    isa     => 'Object',
    is      => 'ro',
    lazy    => 1,
    builder => '_build_first_line',
);

sub _build_first_line {
    my ( $self ) = @_;
    return re( qr{
        \A
        \# \Q This file was generated with Dist::Zilla::Plugin::Manifest::Write \E
            $version::LAX \.
        \z
    }x );
};

#   I expect this (pseudo)test will be executed after `Build` but before `BuiltFiles`.
#   It converts `$self->expected->manifest` to `$self->expected->{ files }->{ MANIFEST }` to let
#   `BuiltFiles` do the work.
test 'before BuiltFiles' => sub {
    my ( $self ) = @_;
    my $expected = $self->expected;
    if ( $expected->{ manifest } ) {
        $expected->{ files }->{ MANIFEST } = [
            $self->first_line,
            @{ $expected->{ manifest } },
        ];
    };
    pass;
};

with 'Test::Dist::Zilla::BuiltFiles';

#   Make sure our manifest can be read by `ExtUtils::Manifest::readmani` and result of reading
#   matches list of files in the distribution (if `exclude_files` was not used).
test 'Read manifest' => sub {
    my ( $self ) = @_;
    $self->skip_if_exception;
    my $path      = path( $self->tzil->built_in )->child( 'MANIFEST' ) . '';
    my $manifest  = ExtUtils::Manifest::maniread( $path );
    my @maninames = sort( keys( %$manifest ) );
    my $distfiles =
        Set::Object->new( @{ $self->tzil->files } ) -
        Set::Object->new( @{ $self->tzil->plugin_named( $self->name )->found_files } );
    my @distnames = sort( map( { $_->name } $distfiles->members ) );
    cmp_deeply( \@maninames, \@distnames, 'maninames == distnames' );
};

# Build and check distribution tarball.
test 'Check Archive' => sub {
    my ( $self ) = @_;
    $self->skip_if_exception;
    my $expected = $self->expected;
    if ( not $expected->{ archive } ) {
        plan skip_all => 'no expected archive';
    };
    my $tzil = $self->tzil;
    try {
        # TODO: Build archive NOT in current directory.
        $tzil->build_archive();
    } catch {
        $self->_set_exception( $_ );
    };
    ok( not $self->exception );
    my $base = $tzil->dist_basename;
    my $archive = Archive::Tar->new( $tzil->archive_filename );
    if ( $expected->{ archive }->{ exist } ) {
        for my $file ( @{ $expected->{ archive }->{ exist } } ) {
            ok( $archive->contains_file( "$base/$file" ), "$file must be in tarball" );
        };
    };
    if ( $expected->{ archive }->{ not_exist } ) {
        for my $file ( @{ $expected->{ archive }->{ not_exist } } ) {
            ok( ! $archive->contains_file( "$base/$file" ), "$file must not be not in tarball" );
        };
    };
};

1;

# end of file #
