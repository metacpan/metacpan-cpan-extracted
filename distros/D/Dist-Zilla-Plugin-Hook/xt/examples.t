#!perl
#   ---------------------------------------------------------------------- copyright and license ---
#
#   file: xt/examples.t
#
#   Copyright © 2015, 2016 Van de Bugger.
#
#   This file is part of perl-Dist-Zilla-Plugin-Hook.
#
#   perl-Dist-Zilla-Plugin-Hook is free software: you can redistribute it and/or modify it under
#   the terms of the GNU General Public License as published by the Free Software Foundation,
#   either version 3 of the License, or (at your option) any later version.
#
#   perl-Dist-Zilla-Plugin-Hook is distributed in the hope that it will be useful, but WITHOUT ANY
#   WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with
#   perl-Dist-Zilla-Plugin-Hook. If not, see <http://www.gnu.org/licenses/>.
#
#   ---------------------------------------------------------------------- copyright and license ---

#   Test the examples are built with no errors.

package ExampleTester;

use autodie ':all';
use namespace::autoclean;

use CPAN::Meta qw{ load_file };
use Capture::Tiny qw{ capture };
use Dist::Zilla qw{};
use File::chdir;
use Path::Tiny qw{ path tempdir };
use Test::Builder;  # is_passing
use Test::Deep qw{ cmp_deeply };
use Test::More;
use Test::Routine::Util;
use Test::Routine;
use Try::Tiny;

#   If `src_dir` is not a `Path::Tiny` object, create it.
around BUILDARGS => sub {
    my ( $orig, $class, $args ) = @_;
    if ( exists( $args->{ src_dir } ) and not blessed( $args->{ src_dir } ) ) {
        $args->{ src_dir } = path( $args->{ src_dir } );
    };
    return $class->$orig( $args );
};

has name => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

has version => (
    is          => 'ro',
    isa         => 'Str',
    default     => '0.001',
);

has src_dir => (
    is          => 'ro',
    isa         => 'Object',
    lazy        => 1,
    builder     => 'build_src_dir',
);

sub build_src_dir {
    my ( $self ) = @_;
    return path( 'eg' )->child( $self->name );
};

has test_root => (
    is          => 'ro',
    isa         => 'Object',
    lazy        => 1,
    builder     => 'build_test_root',
);

sub build_test_root {
    my ( $self ) = @_;
    my $test_root = path( '.test' );
    if ( not $test_root->is_dir ) {
        $test_root->mkpath();
    };
    return $test_root;
};

has test_dir => (
    is          => 'ro',
    isa         => 'Object',
    lazy        => 1,
    builder     => 'build_test_dir',
);

sub build_test_dir {
    my ( $self ) = @_;
    my $name = $self->name;
    my $test_dir = tempdir( "$name.XXXXXX", DIR => $self->test_root, CLEANUP => 0 );
        # ^ Do not delete directory automatically. I want to keep it if the test fails.
    return $test_dir;
};

{

    my $test_root;

    sub DEMOLISH {
        my ( $self, $global ) = @_;
        my $tb = Test::Builder->new();
        my $test_dir = $self->test_dir;
        if ( $tb->is_passing ) {
            #   Delete directory if the test passes.
            $test_dir->remove_tree();
        } else {
            #   Report directory otherwise, so developer can investigate the failure.
            diag( "Test failed; see $test_dir" );
        };
        if ( $test_root ) {
            "$test_root" eq $self->test_root or die "oops";
        } else {
            $test_root = $self->test_root;
        };
    };

    END {
        #   Delete test root directory, if it is empty.
        if ( defined( $test_root ) and not $test_root->children() ) {
            rmdir( $test_root );
        };
    };

}

has dist_dir => (
    is          => 'ro',
    isa         => 'Object',
    lazy        => 1,
    builder     => 'build_dist_dir',
);

sub build_dist_dir {
    my ( $self ) = @_;
    return $self->test_dir->child( sprintf( '%s-%s', $self->name, $self->version ) );
};

has stdout => (
    is          => 'ro',
    isa         => 'Str',
    writer      => '_set_stdout',
);

has stderr => (
    is          => 'ro',
    isa         => 'Str',
    writer      => '_set_stderr',
);

sub copy_files {
    my ( $self ) = @_;
    for my $file ( $self->src_dir->children ) {
        $file->copy( $self->test_dir );
    };
};

sub dzil {
    my ( $self, $command ) = @_;
    my ( $ok, $exception );
    my ( $stdout, $stderr ) =
        capture {
            try {
                {
                    local $CWD = $self->test_dir;
                    system( 'dzil', $command );
                }
                $ok = 1;
            } catch {
                chomp( $_ );
                $exception = $_;
            };
        };
    $self->_set_stdout( $stdout );
    $self->_set_stderr( $stderr );
    if ( $ok ) {
        pass;
    } else {
        diag(
            "\n",
            "Command: dzil $command\n",
            "Exception:\n$exception\n(end)\n",
            "Stdout:\n$stdout(end)\n",
            "Stderr:\n$stderr(end)\n"
        );
        fail;
    };
};

test 'build test' => sub {
    my ( $self ) = @_;
    $self->copy_files();
    $self->dzil( 'build' );
    done_testing;
};

has check => (
    is          => 'ro',
    isa         => 'CodeRef',
);

test 'post-build checks' => sub {
    my ( $self ) = @_;
    if ( $self->check ) {
        $self->check->( $self );
    } else {
        plan skip_all => 'no post-build checks';
    };
};

run_me( 'AdaptiveTestVersion', {
    name    => 'AdaptiveTestVersion',
    check   => sub {
        my ( $self ) = @_;
        my $test;
        #   `Test::Version` can generate either author or release test, it depends on its version.
        #   Let us try to accept both variants.
        for my $type ( qw{ author release } ) {
            my $file = $self->dist_dir->child( "xt/$type/test-version.t" );
            if ( $file->exists ) {
                $test = $file;
                last;
            };
        };
        isnt( $test, undef, "test-version.t found" );
        like( $test->slurp(), qr{^\s*is_strict\s*=>\s*1,\s*$}m, "is_strict => 1" );
        done_testing;
    },
} );

#   Run `dzil build`, make sure `META.json` contains description.
run_me( 'Description', {
    name    => 'Description',
    check   => sub {
        my ( $self ) = @_;
        my $meta = CPAN::Meta->load_file( $self->dist_dir->child( 'META.json' ) );
        ok( exists( $meta->{ description } ), 'description exists' );
        is(
            $meta->{ description },
            "This is not short one-line abstract,\n" .
                "but more detailed description,\n" .
                "which spans several lines.",
            'description value'
        );
        done_testing;
    },
} );

run_me( 'TemplateVariables', {
    name    => 'TemplateVariables',
    check   => sub {
        my ( $self ) = @_;
        my $mail = 'mailto:bug-TemplateVariables@bt.example.org';
        my $web  = 'https://bt.example.org/display.html?name=TemplateVariables';
        #   Check `META.json` contains `bugtracker` resource with expected values.
        my $meta = CPAN::Meta->load_file( $self->dist_dir->child( 'META.json' ) );
        ok( exists( $meta->{ resources } ), 'resources exist' );
        ok( exists( $meta->{ resources }->{ bugtracker } ), 'bugtracker exists' );
        my $bugtracker = $meta->{ resources }->{ bugtracker };
        cmp_deeply( $bugtracker, { mailto => $mail, web => $web }, 'bugtracker has proper values' );
        my $bugs = $self->dist_dir->child( 'BUGS.pod' )->slurp_utf8;
        #   Check `BUGS.pod` does not contain variables but contains bugtracker mail and web addrs.
        unlike( $bugs, qr{\{\{\s*\$MY::(mail|web)\s*\}\}}, 'BUGS.pod does not contain variables' );
        like( $bugs, qr{\Q$mail\E}, 'BUGS.pod has mail' );
        like( $bugs, qr{\Q$web\E},  'BUGS.pod has web'  );
        done_testing;
    },
} );

run_me( 'VersionHandling', {
    name    => 'VersionHandling',
    check   => sub {
        my ( $self ) = @_;
        #   Check `META.json` contains `bugtracker` resource with expected values.
        my $meta = CPAN::Meta->load_file( $self->dist_dir->child( 'META.json' ) );
        is( $meta->version, $self->version, 'version' );
        my $version = $self->test_dir->child( 'VERSION' );
        is( $version->slurp_utf8 =~ s{\s*\z}{}gr, $self->version, 'version is not bumped' );
        $self->dzil( 'release' );
        is( $version->slurp_utf8 =~ s{\s*\z}{}gr, $self->version . '_01', 'version is bumped' );
        $self->dzil( 'release' );
        is( $version->slurp_utf8 =~ s{\s*\z}{}gr, $self->version . '_02', 'version is bumped' );
        done_testing;
    },
} );

run_me( 'UnwantedDependencies', {
    name    => 'UnwantedDependencies',
    check   => sub {
        my ( $self ) = @_;
        #   Check `META.json` contains dependency on `DDP`.
        my $meta = CPAN::Meta->load_file( $self->dist_dir->child( 'META.json' ) );
        cmp_deeply( $meta->{ prereqs }->{ runtime }->{ requires }, { DDP => 0 }, 'dependency' );
        #~ $self->dzil( 'release' ); # TODO: Finish the test.
        done_testing;
    },
} );

done_testing;
exit( 0 );

# end of file #
