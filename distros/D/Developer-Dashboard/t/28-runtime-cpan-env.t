use strict;
use warnings;

use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

use lib 'lib';

use Developer::Dashboard::PageRuntime;

{
    package Local::FakePaths;

    sub new {
        my ( $class, %args ) = @_;
        return bless {
            root  => $args{root},
            roots => $args{roots} || [ $args{root} ],
        }, $class;
    }

    sub runtime_root {
        my ($self) = @_;
        return $self->{root};
    }

    sub runtime_roots {
        my ($self) = @_;
        return @{ $self->{roots} };
    }

    sub runtime_layers {
        my ($self) = @_;
        return reverse @{ $self->{roots} };
    }

    sub dashboards_roots {
        my ($self) = @_;
        return map { File::Spec->catdir( $_, 'dashboards' ) } @{ $self->{roots} };
    }

    sub runtime_local_lib_roots {
        my ($self) = @_;
        return map { File::Spec->catdir( $_, 'local', 'lib', 'perl5' ) } @{ $self->{roots} };
    }
}

my $parent_root = tempdir( CLEANUP => 1 );
my $root        = File::Spec->catdir( $parent_root, 'leaf-runtime' );
make_path($root);
my $paths   = Local::FakePaths->new( root => $root, roots => [ $root, $parent_root ] );
my $runtime = Developer::Dashboard::PageRuntime->new( paths => $paths );
my $lib_dir = File::Spec->catdir( $root, 'local', 'lib', 'perl5' );
my $parent_lib_dir = File::Spec->catdir( $parent_root, 'local', 'lib', 'perl5' );

{
    local $ENV{PERL5LIB} = 'alpha:beta';
    my %env = $runtime->_saved_ajax_env(
        path   => '/tmp/example.pl',
        page   => 'sql-dashboard',
        type   => 'json',
        params => { one => 1 },
    );
    is( $env{PERL5LIB}, 'alpha:beta', 'saved ajax env leaves PERL5LIB unchanged when the runtime local lib does not exist' );
}

make_path($lib_dir);
{
    local $ENV{PERL5LIB} = 'alpha:beta';
    my %env = $runtime->_saved_ajax_env(
        path   => '/tmp/example.pl',
        page   => 'sql-dashboard',
        type   => 'json',
        params => { one => 1 },
    );
    is(
        $env{PERL5LIB},
        join( ':', $lib_dir, 'alpha', 'beta' ),
        'saved ajax env prepends the runtime local lib when it exists',
    );
}

make_path($parent_lib_dir);
{
    local $ENV{PERL5LIB} = 'alpha:beta';
    my %env = $runtime->_saved_ajax_env(
        path   => '/tmp/example.pl',
        page   => 'sql-dashboard',
        type   => 'json',
        params => { one => 1 },
    );
    is(
        $env{PERL5LIB},
        join( ':', $lib_dir, $parent_lib_dir, 'alpha', 'beta' ),
        'saved ajax env prepends every layered runtime local lib in lookup order',
    );
    is(
        $env{DEVELOPER_DASHBOARD_RUNTIME_LAYERS},
        join( "\n", $parent_root, $root ),
        'saved ajax env exports the full runtime layer chain for detached ajax workers',
    );
}

{
    local $ENV{PERL5LIB} = join( ':', $lib_dir, $parent_lib_dir, 'alpha' );
    my %env = $runtime->_saved_ajax_env(
        path   => '/tmp/example.pl',
        page   => 'sql-dashboard',
        type   => 'json',
        params => { one => 1 },
    );
    is(
        $env{PERL5LIB},
        join( ':', $lib_dir, $parent_lib_dir, 'alpha' ),
        'saved ajax env does not duplicate layered runtime local libs in PERL5LIB',
    );
}

{
    my $dashboard = File::Spec->catfile( File::Spec->curdir, 'bin', 'dashboard' );
    open my $fh, '<', $dashboard or die "Unable to read $dashboard: $!";
    my $source = do { local $/; <$fh> };
    close $fh or die "Unable to close $dashboard: $!";
    unlike( $source, qr/Developer::Dashboard::CPANManager/, 'dashboard script keeps runtime-local cpan support script-local instead of introducing a dedicated CPAN manager module' );
}

done_testing;

__END__

=head1 NAME

28-runtime-cpan-env.t - verify runtime-local Perl module exposure without a dedicated CPAN manager module

=head1 DESCRIPTION

This test verifies that saved Ajax workers inherit the runtime-local
C<.developer-dashboard/local/lib/perl5> path directly from the active runtime
root and that the dashboard script no longer depends on a dedicated
C<Developer::Dashboard::CPANManager> module.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This test is the executable regression contract for environment overrides and persisted configuration behavior. Read it when you need to understand the real fixture setup, assertions, and failure modes for this slice of the repository instead of guessing from the module names alone.

=head1 WHY IT EXISTS

It exists because environment overrides and persisted configuration behavior has enough moving parts that a code-only review can miss real regressions. Keeping those expectations in a dedicated test file makes the TDD loop, coverage loop, and release gate concrete.

=head1 WHEN TO USE

Use this file when changing environment overrides and persisted configuration behavior, when a focused CI failure points here, or when you want a faster regression loop than running the entire suite.

=head1 HOW TO USE

Run it directly with C<prove -lv t/28-runtime-cpan-env.t> while iterating, then keep it green under C<prove -lr t> and the coverage runs before release. 

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, the coverage gates, and the release verification loop all rely on this file to keep this behavior from drifting.

=head1 EXAMPLES

Example 1:

  prove -lv t/28-runtime-cpan-env.t

Run the focused regression test by itself while you are changing the behavior it owns.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/28-runtime-cpan-env.t

Exercise the same focused test while collecting coverage for the library code it reaches.

Example 3:

  prove -lr t

Put the focused fix back through the whole repository suite before calling the work finished.

=for comment FULL-POD-DOC END

=cut
