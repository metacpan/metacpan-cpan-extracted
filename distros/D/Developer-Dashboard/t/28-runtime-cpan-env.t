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

Test file in the Developer Dashboard codebase. This file tests runtime-local cpan environment handling and helper exposure.
Open this file when you need the implementation, regression coverage, or runtime entrypoint for that responsibility rather than guessing which part of the tree owns it.

=head1 WHY IT EXISTS

It exists to enforce the TDD contract for this behaviour, stop regressions from shipping, and keep the mandatory coverage and release gates honest.

=head1 WHEN TO USE

Use this file when you are reproducing or fixing behaviour in its area, when you want a focused regression check before the full suite, or when you need to extend coverage without waiting for every unrelated test.

=head1 HOW TO USE

Run it directly with C<prove -lv t/28-runtime-cpan-env.t> while iterating, then keep it green under C<prove -lr t> before release. Add or update assertions here before changing the implementation that it covers.

=head1 WHAT USES IT

It is used by developers during TDD, by the full C<prove -lr t> suite, by coverage runs, and by release verification before commit or push.

=head1 EXAMPLES

  prove -lv t/28-runtime-cpan-env.t

Run that command while working on the behaviour this test owns, then rerun C<prove -lr t> before release.

=for comment FULL-POD-DOC END

=cut
