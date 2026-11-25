use strict;
use warnings;

use Capture::Tiny qw(capture);
use Test::More;
use File::Spec;
use File::Temp ();

use lib 'lib';

{
    package Local::WatchSentinel;
    # close()
    # Represents successful cleanup for the test watcher sentinel.
    # Input: the sentinel object.
    # Output: true, indicating that no cleanup error occurred.
    sub close { return 1 }
}

require Developer::Dashboard::HtmlEscape;
require Developer::Dashboard::IndicatorStore::Watch;
require Developer::Dashboard::SkillDispatcher;
require Developer::Dashboard::Web::App;

my @warnings;
my $watcher = bless {}, 'Local::WatchSentinel';
my $missing_root = File::Spec->catdir(
    File::Spec->tmpdir,
    'dd-watch-module-stability-intentionally-missing',
);

{
    no strict 'refs';
    no warnings 'once';
    local $INC{'Developer/Dashboard/IndicatorStore/Watch.pm'} = undef;
    local $Developer::Dashboard::Web::App::MODULE_SOURCE_PATH =
      File::Spec->catfile( $missing_root, 'Web', 'App.pm' );
    local *{'Developer::Dashboard::IndicatorStore::Watch::new'} = sub { $watcher };
    local $SIG{__WARN__} = sub { push @warnings, @_ };

    my $app = bless {}, 'Developer::Dashboard::Web::App';
    is(
        $app->_config_snapshot_watcher,
        $watcher,
        'configuration snapshot watcher reuses a loaded package if its INC key is absent',
    );
}

{
    no strict 'refs';
    no warnings 'once';
    local $INC{'Developer/Dashboard/IndicatorStore/Watch.pm'} = undef;
    local $Developer::Dashboard::Web::App::MODULE_SOURCE_PATH =
      File::Spec->catfile( $missing_root, 'Web', 'App.pm' );
    local *{'Developer::Dashboard::IndicatorStore::Watch::new'} = sub { $watcher };
    local $SIG{__WARN__} = sub { push @warnings, @_ };

    my $app = bless {}, 'Developer::Dashboard::Web::App';
    is(
        $app->_saved_nav_items_watcher,
        $watcher,
        'saved navigation watcher reuses a loaded package if its INC key is absent',
    );
}

{
    no strict 'refs';
    no warnings 'once';
    local $INC{'Developer/Dashboard/IndicatorStore/Watch.pm'} = undef;
    local $Developer::Dashboard::SkillDispatcher::MODULE_SOURCE_PATH =
      File::Spec->catfile( $missing_root, 'SkillDispatcher.pm' );
    local *{'Developer::Dashboard::IndicatorStore::Watch::new'} = sub { $watcher };
    local $SIG{__WARN__} = sub { push @warnings, @_ };

    my $dispatcher = bless {}, 'Developer::Dashboard::SkillDispatcher';
    is(
        $dispatcher->_skill_nav_pages_watcher,
        $watcher,
        'skill navigation watcher reuses a loaded package if its INC key is absent',
    );
}

is_deeply( \@warnings, [], 'loaded Watch package is not recompiled or warned about' );

my $repo_lib = File::Spec->rel2abs('lib');
my $canonical_load_probe = <<'PERL';
use strict;
use warnings;
require Developer::Dashboard::Web::App;
my $app = bless {}, 'Developer::Dashboard::Web::App';
$app->_config_snapshot_watcher;
print exists $INC{'Developer/Dashboard/IndicatorStore/Watch.pm'} ? "canonical=1\n" : "canonical=0\n";
PERL
# The probe goes through a script file, not -e: a multi-line -e argument
# holding double quotes does not survive the Windows command line.
my $probe_dir    = File::Temp::tempdir( CLEANUP => 1 );
my $probe_script = File::Spec->catfile( $probe_dir, 'canonical-load-probe.pl' );
open my $probe_fh, '>', $probe_script or die "Unable to write $probe_script: $!";
print {$probe_fh} $canonical_load_probe;
close $probe_fh or die "Unable to close $probe_script: $!";
my ( $probe_stdout, $probe_stderr, $probe_exit ) = capture {
    system( $^X, "-I$repo_lib", $probe_script );
};
is( $probe_exit, 0, 'watcher loader probe exits successfully' );
is( $probe_stdout, "canonical=1\n", 'lazy watcher loading registers the canonical module key' );
is( $probe_stderr, '', 'canonical watcher loading emits no warnings' );

done_testing;

__END__

=pod

=head1 NAME

t/678-watch-module-load-stability.t - avoid duplicate watcher module loading

=head1 PURPOSE

Proves that watcher consumers do not recompile the same Perl package just
because its conventional C<%INC> key is absent while its methods are already
loaded. A fresh interpreter also verifies that lazy watcher loading is cached
under the canonical Perl module key, so a later ordinary C<require> does not
evaluate the file a second time.

=head1 WHY IT EXISTS

Coverage and runtime test paths can load the watcher using a canonical module
name and later clear or vary the C<%INC> entry while retaining package symbols.
The consumers also resolve a source path to survive working-directory changes.
Loading that path under an absolute require key and then loading it by its
canonical module name redefines every method and emits warnings. The regression
test verifies that all lazy watcher call sites reuse the existing package and
that a fresh load records the canonical key.

=head1 WHEN TO USE

Run this test when changing lazy watcher loading in the web application or skill
dispatcher, or when changing the coverage runner's module loading behaviour.

=head1 HOW TO USE

  d2 docker compose exec dev prove -Iblib/arch -Iblib/lib -Ilib -lv t/678-watch-module-load-stability.t

The shared XS module should be built in the same development container before
running the broader suite.

=head1 WHAT USES IT

The watcher consumers in C<Developer::Dashboard::Web::App> and
C<Developer::Dashboard::SkillDispatcher> are exercised directly.

=head1 EXAMPLES

Example 1: run the regression test by itself.

  prove -Iblib/arch -Iblib/lib -Ilib -lv t/678-watch-module-load-stability.t

Example 2: run it with all tests inside the Docker development environment.

  d2 docker compose exec dev prove -Iblib/arch -Iblib/lib -Ilib -lr t

=cut
