#!perl
#   ---------------------------------------------------------------------- copyright and license ---
#
#   file: t/build.t
#
#   Copyright © 2015 Van de Bugger.
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

package AuthorVDBTesterBuild;

use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC';
use namespace::autoclean;
use utf8;
use version 0.77;
use open ':locale';

use Test::More; ## TODO: drop it.

use Test::Routine;

with 'Test::Dist::Zilla::Build';
with 'Test::Dist::Zilla::BuiltFiles' => { -version => 'v0.3.1' };
    # ^ A bug in v0.3.0 affects the test.

use Path::Tiny;
use Test::Deep qw{ cmp_deeply re };
use Test::More;
use Test::Routine::Util;
use Module::Runtime ();

{
    #   `Test::Version` < 1.07 calls `Path::Class::File->new` without using or requiring
    #   `Path::Class`. It was not a problem in `Dist::Zilla` 5.x, because `Path::Class` was loaded
    #   by `Dist::Zilla`. However, `Dist::Zilla` 6.x does not use `Path::Class` any more, so older
    #   `Test::Version` with newer `Dist::Zilla` causes error, see:
    #       *   <http://www.cpantesters.org/cpan/report/e51e78c2-bbf4-11e6-b1e6-d350d4b23455>,
    #       *   <http://www.cpantesters.org/cpan/report/b06943a4-bbf5-11e6-98c1-c12b4c4af187>,
    #       *   <http://www.cpantesters.org/cpan/report/b06943a4-bbf5-11e6-98c1-c12b4c4af187>.
    require Dist::Zilla;
    require Dist::Zilla::Plugin::Test::Version;
    my $dz = version->parse( Dist::Zilla->VERSION );
    my $tv = version->parse( Dist::Zilla::Plugin::Test::Version->VERSION );
    if ( $dz >= 6.0 and $tv < 1.07 ) {
        Module::Runtime::use_module( 'Path::Class' );
    };
};

# REQUIRE: Dist::Zilla::Plugin::Manifest::Write v0.9.0
    #   v0.9.0 does not show file mungers. The bundle can works with earlier versions, but tests
    #   will fail.
# REQUIRE: Pod::Simple > 3.20
    #   Pod::Simple up to 3.20 munges Unicode charaters (i. e. ©).

# I do not need `version` because `@Author::VDB` have a `Hook::VersionProvider`.
around _build_dist => sub {
    my ( $orig, $self, @args ) = @_;
    my $dist = $self->$orig( @args );
    delete( $dist->{ version } );
    return $dist;
};

sub _build_message_filter {
    my ( $self ) = @_;
    return sub {
        map( { ( my $r = $_ ) =~ s{^\[[^\]]*\] }{}; $r } grep( $_ =~ m{^\Q[Author::VDB]\E }, @_ ) );
    };
};

has options => (
    isa         => 'HashRef',
    is          => 'ro',
    default     => sub { {} },
);

has extra_files => (
    isa         => 'HashRef',
    is          => 'ro',
    default     => sub { {} },
);

sub _build_files {
    my ( $self ) = @_;
    return {
        'doc/copying.pod' => [
            '=encoding UTF-8',
            '',
            '=head1 COPYRIGHT AND LICENSE',
            '',
            'Copyright © 2015 John Doe',
            '',
            '=cut',
            '',
            '# end of file #',
        ],
        'doc/what.pod' => [
            '=encoding UTF-8',
            '',
            '=head1 WHAT?',
            '',
            'That!',
            '',
            '=cut',
        ],
        'doc/why.pod' => [
            '=encoding UTF-8',
            '',
            '=head1 WHY?',
            '',
            'Err...',
            '',
            '=cut',
        ],
        'lib/Dummy.pm' => [
            'package Dummy;',
            '# VERSION',
            '# {{ $dist->version }}',
            '1;',
        ],
        'lib/Dummy/Manual.pod' => [
            '=encoding UTF-8',
            '',
            '=head1 DESCRIPTION',
            '',
            'POD file is a {{ \'template\' }}.',
            # TODO: Use $MY::name, etc.
            '',
            '=cut',
            '',
            '# end of file',
        ],
        'Changes'  => '# Changes #',
        'VERSION'  => 'v0.3.1',
        'MANIFEST' => [
            'doc/                       / Documentation.',
            'doc/what.pod               - ',
            'doc/why.pod                - ',
            'doc/copying.pod            - Do not copy it to the distribution.',
            'lib/                       / Perl modules.',
            'lib/Dummy.pm               + Main module',
            'lib/Dummy/Manual.pod       + User manual.',
            '',
            'Changes                    + Release history.',
            'VERSION                    + Software version.',
        ],
        %{ $self->extra_files },
    };
};

sub _build_plugins {
    my ( $self ) = @_;
    return [
        [ '@Author::VDB' => $self->options ],
    ];
};

has check => (
    isa         => 'CodeRef',
    is          => 'ro',
    default     => sub { sub {}; },
);

test 'Post-build check' => sub {
    my ( $self ) = @_;
    $self->skip_if_exception;
    $self->check->( $self );
    pass;
};

my $aborting = "Aborting...\n";

# --------------------------------------------------------------------------------------------------

run_me 'No options' => {
    expected => {
        files => {
            'doc/copying.pod'   => undef,   #   These files are not copied to distribution
            'doc/what.pod'      => undef,   #   (`Manifest::Read` works).
            'doc/why.pod'       => undef,
            'COPYING' => [                  #   `COPYING` is generated; it is a plain text, not POD.
                'COPYRIGHT AND LICENSE',    #   BTW, real `doc/copying.pod` file overrides
                '',                         #   file embedded into the bundle.
                'Copyright © 2015 John Doe',
            ],
            'README' => re( qr{^WHAT\?\n\nThat!\n\nWHY\?\n\nErr\.\.\.\n\nNAMING\n} ),
            'lib/Dummy.pm' => [             # Perl code fragments expanded.
                'package Dummy;',
                'our $VERSION = \'v0.3.1\'; # VERSION',     # Hook::VersionProvider + OurPkgVersion.
                '# v0.3.1',
                #  ^^^^^^^ Perl code fragment expanded.
                '1;',
            ],
            'META.json' => re( qr{} ),  # MetaJSON
            'META.yml'  => re( qr{} ),  # MetaYAML
            # TODO: Test PodWeaver.
            'MANIFEST' => [
                re( qr{^# This file was generated with Dist::Zilla::Plugin::Manifest::Write\b} ),
                'Build.PL             # 3rd party file built by ModuleBuildTiny',
                'COPYING              #     Dummy file built by GenerateFile',
                'Changes              #     Dummy file added by Manifest::Read',
                'MANIFEST             #  metainfo file built by Manifest::Write',
                'META.json            #  metainfo file built by MetaJSON',
                'META.yml             #  metainfo file built by MetaYAML',
                'README               #     Dummy file built by GenerateFile',
                'VERSION              #     Dummy file added by Manifest::Read',
                'lib/Dummy.pm         #     Dummy file added by Manifest::Read',
                'lib/Dummy/Manual.pod #     Dummy file added by Manifest::Read',
                't/00-compile.t       # 3rd party file built by Test::Compile',
                # Following files are excluded by `Manifest::Write`:
                # 'xt/author/critic.t           # 3rd party file built by Test::Perl::Critic',
                # 'xt/author/eol.t              # 3rd party file built by Test::EOL',
                # 'xt/author/mojibake.t         # 3rd party file built by MojibakeTests',
                # 'xt/author/no-tabs.t          # 3rd party file built by Test::NoTabs',
                # 'xt/author/pod-coverage.t     # 3rd party file built by PodCoverageTests',
                # 'xt/author/pod-no404s.t       # 3rd party file built by Test::Pod::No404s',
                # 'xt/author/pod-spell.t        # 3rd party file built by Test::PodSpelling',
                # 'xt/author/pod-syntax.t       # 3rd party file built by PodSyntaxTests',
                # 'xt/author/portability.t      # 3rd party file built by Test::Portability',
                # 'xt/author/synopsis.t         # 3rd party file built by Test::Synopsis',
                # 'xt/author/test-version.t     # 3rd party file built by Test::Version',
                # 'xt/release/cpan-changes.t    # 3rd party file built by Test::CPAN::Changes',
                # 'xt/release/dist-manifest.t   # 3rd party file built by Test::DistManifest',
                # 'xt/release/distmeta.t        # 3rd party file built by MetaTests',
                # 'xt/release/fixme.t           # 3rd party file built by Test::Fixme',
                # 'xt/release/kwalitee.t        # 3rd party file built by Test::Kwalitee',
                # 'xt/release/meta-json.t       # 3rd party file built by Test::CPAN::Meta::JSON',
                # 'xt/release/minimum-version.t # 3rd party file built by Test::MinimumVersion',
                # 'xt/release/new-version.t     # 3rd party file built by Test::NewVersion',
                # 'xt/release/pod-linkcheck.t   # 3rd party file built by Test::Pod::LinkCheck',
                # TODO: Check these files were built.
            ],
            'VERSION' => 'v0.3.1',
        },
    },
};

#   Non-default `copying` option.
run_me 'Copying option' => {
    options => {
        'copying' => 'doc/non-default-copying.pod',
    },
    extra_files => {
        'doc/non-default-copying.pod' => [
            '=encoding UTF-8',
            '',
            '=head1 LICENSE AND COPYRIGHT',
            '',
            'Copyleft © 2015 Jane Doe',
            '',
        ],
    },
    expected => {
        files => {
            'doc/non-default-copying.pod' => undef,
            'COPYING' => [
                # `COPYING` file is plain text, not POD.
                'LICENSE AND COPYRIGHT',
                '',
                'Copyleft © 2015 Jane Doe',
            ],
        },
    },
};

run_me 'Empty copying option' => {
    options => {
        'copying' => '',
    },
    expected => {
        files => {
            'COPYING' => undef, # If `copying` is empty, `COPYING` is not generated.
        },
    },
};

#   Non-default `readme` option.
run_me 'Readme option' => {
    options => {
        'readme' => [
            'doc/non-default-what.pod',
            'doc/non-default-copying.pod',
        ],
    },
    extra_files => {
        'doc/non-default-copying.pod' => [
            '=encoding UTF-8',
            '',
            '=head1 LICENSE AND COPYRIGHT',
            '',
            'Copyleft © 2015 Jane Doe',
        ],
        'doc/non-default-what.pod' => [
            '=encoding UTF-8',
            '',
            '=head1 WHAT?',
            '',
            'Nope.',
            '',
            '=cut',
        ],
    },
    expected => {
        files => {
            'doc/non-default-copying.pod' => undef,
            'doc/non-default-what.pod' => undef,
            'README' => [
                'WHAT?',
                '',
                'Nope.',
                '',
                'LICENSE AND COPYRIGHT',
                '',
                'Copyleft © 2015 Jane Doe',
            ],
        },
    },
};

#   Empty `readme` option.
run_me 'Empty readme option' => {
    options => {
        'readme' => '',
    },
    expected => {
        files => {
            'README' => undef,
        },
    },
};

#   Non-default `templates` option.
run_me 'Templates option' => {
    options => {
        templates => ':NoFiles',
        #             ^^^^^^^^ No files are treated as templates.
    },
    expected => {
        files => {
            'lib/Dummy.pm' => [
                'package Dummy;',
                'our $VERSION = \'v0.3.1\'; # VERSION',
                '# {{ $dist->version }}',
                #  ^^^^^^^^^^^^^^^^^^^^ Perl code is not evaluated.
                '1;',
            ],
        },
    },
};

#   Empty `templates` option.
run_me 'Empty templates option' => {
    options => {
        templates => '',
    },
    expected => {
        files => {
            'lib/Dummy.pm' => [
                'package Dummy;',
                'our $VERSION = \'v0.3.1\'; # VERSION',
                '# {{ $dist->version }}',
                #  ^^^^^^^^^^^^^^^^^^^^ Perl code is not evaluated.
                '1;',
            ],
        },
    },
};

done_testing;

exit( 0 );
