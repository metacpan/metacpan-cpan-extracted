#!perl
#   ---------------------------------------------------------------------- copyright and license ---
#
#   file: t/examples.t
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

use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC';
use lib 'eg';
use lib 't/lib';
use strict;
use version 0.77;
use warnings;

use Path::Tiny;
use Test::Deep qw{ re };
use Test::More;
use Test::Routine;
use Test::Routine::Util;

with 'ManifestWriteTester';

my $ruler = '-' x 80;

#   First line of the freshly generated manifest file may be not the same as the saved manifest,
#   because of plugin version written to the first line comment. This function reads previously
#   saved manifest file, checks it is not empty, makes sure the first line matches the expected
#   regexp, and replaces the first line with regular expression, so version change does not affect
#   the test.
sub manifest($) {
    my ( $manifest ) = @_;
    my $lines = [ path( $manifest )->lines_utf8() ];
        # `lines_utf8( { chomp => 1 } )` works incorrectly,
        # see <https://github.com/dagolden/Path-Tiny/issues/152>.
    chomp( @$lines );
    ok( @$lines > 0, "$manifest is non empty" ) and do {
        ok(
            $lines->[ 0 ] =~ qr{\A\Q# This file was generated with \E(\S+)\s(\S+)\.\z},
            "first line of $manifest"
         ) and do {
            my ( $plugin, $version ) = ( $1, $2 );
            ok( version::is_lax( $version ), "$manifest: version" );
            $lines->[ 0 ] = re( qr{\A\Q# This file was generated with $plugin \E$version::LAX\.\z} );
        };
    };
    return $lines;
};

#   Not an actual test. This method just shows content of built `MANIFEST` file.
test 'Show MANIFEST' => sub {
    my ( $self ) = @_;
    if ( $self->exception ) {
        plan skip_all => 'exception occurred';
    };
    #~ my $manifest = path( $self->tzil->built_in )->child( 'MANIFEST' )->slurp_utf8();
    #~ diag( "\n$ruler\n" . $manifest . "$ruler\n" );
    pass;
};

# --------------------------------------------------------------------------------------------------

require Dist::Zilla;
if ( not $ENV{ AUTHOR_TESTING } ) {
    if ( version->parse( $Dist::Zilla::VERSION ) < 5.038 ) { # Need `:ExtraTestFiles` file finder.
        plan skip_all => 'Dist::Zilla too old';
    };
};

#   Use plugin from the main module synopsis.
run_me 'Synopsis' => {
    name => '=ManifestWithFileSize',
    plugins => [
        'GatherDir',                    # REQUIRE: Dist::Zilla::Plugin::GatherDir
        [ '=ManifestWithFileSize', {
        #  ^^^^^^^^^^^^^^^^^^^^^
            source_provider => 'GatherDir',
            exclude_files   => ':ExtraTestFiles',
        } ],
    ],
    expected => {
        files => {
            MANIFEST => manifest( 'eg/ManifestWithFileSize.out' ),
        },
    },
};

run_me 'Example of MANIFEST' => {
    extra_files => {
        'COPYING'       => 'license',
        'Changes'       => 'release history log',
        'README'        => 'documentation',
    },
    options => {
        source_provider => 'GatherDir',
        exclude_files   => ':ExtraTestFiles',
    },
    extra_plugins => [
        'PkgVersion',                   # REQUIRE: Dist::Zilla::Plugin::PkgVersion
        'Test::Compile',                # REQUIRE: Dist::Zilla::Plugin::Test::Compile
        'Test::EOL',                    # REQUIRE: Dist::Zilla::Plugin::Test::EOL 0.14
            # ^ `Test::EOL` 0.14 generates `eol.t`. Previous versions generate `test-eol.t`.
        'Test::NoTabs',                 # REQUIRE: Dist::Zilla::Plugin::Test::NoTabs 0.09
            # ^ `Test::NoTabs` 0.09 generates author test. Previous versions generate release test.
        'ModuleBuildTiny',              # REQUIRE: Dist::Zilla::Plugin::ModuleBuildTiny
    ],
    expected => {
        # No exception expected.
        files => {
            MANIFEST => manifest( 'eg/MANIFEST' ),
        },
    },
};

done_testing;

exit( 0 );

# end of file #
