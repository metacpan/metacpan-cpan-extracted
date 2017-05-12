#!perl
#   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#
#   file: t/example.t
#
#   Copyright © 2015 Van de Bugger
#
#   This file is part of perl-Dist-Zilla-Plugin-MetaResources-Template.
#
#   perl-Dist-Zilla-Plugin-MetaResources-Template is free software: you can redistribute it and/or
#   modify it under the terms of the GNU General Public License as published by the Free Software
#   Foundation, either version 3 of the License, or (at your option) any later version.
#
#   perl-Dist-Zilla-Plugin-MetaResources-Template is distributed in the hope that it will be
#   useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#   FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with
#   perl-Dist-Zilla-Plugin-MetaResources-Template. If not, see <http://www.gnu.org/licenses/>.
#
#   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

package ExampleTester;

use autodie ':all';
use namespace::autoclean;

use Dist::Zilla qw{};
use File::chdir;
use Path::Tiny qw{ path tempdir };
use Test::More;
use Test::Routine;
use Test::Routine::Util;
use Try::Tiny;
use Capture::Tiny qw{ capture };

has dist_ini => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

test 'build distribution' => sub {
    my ( $self ) = @_;
    plan tests => 1;
    my $dist_ini  = path( $self->dist_ini );
    my $test_root = path( '.test' );
    if ( not $test_root->is_dir ) {
        $test_root->mkpath();
    };
    my $test_dir = tempdir( 'example.XXXXXX', DIR => "$test_root", CLEANUP => 0 );
    $dist_ini->copy( $test_dir );
    my ( $ok, $exception );
    my ( $stdout, $stderr ) =
        capture {
            try {
                {
                    local $CWD = "$test_dir";
                    system( 'dzil', 'build' );
                }
                $ok = 1;
            } catch {
                chomp( $_ );
                $exception = $_;
            };
        };
    if ( $ok ) {
        $test_dir->remove_tree();
        pass();
    } else {
        diag(
            "\n",
            "Exception:\n$exception\n(end)\n",
            "Stdout:\n$stdout(end)\n",
            "Stderr:\n$stderr(end)\n"
        );
        fail();
    };
    done_testing;
};

plan tests => 1;

run_me( 'example', {
    dist_ini => 'ex/Assa/dist.ini',
} );

done_testing;

exit( 0 );

# end of file #
