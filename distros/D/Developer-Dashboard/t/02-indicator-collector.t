use strict;
use warnings;
use utf8;

use Capture::Tiny qw(capture);
use File::Spec;
use Test::More;
use File::Temp qw(tempdir);

use lib 'lib';

use Developer::Dashboard::Collector;
use Developer::Dashboard::IndicatorStore;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::Prompt;

local $ENV{HOME} = tempdir(CLEANUP => 1);
chdir $ENV{HOME} or die "Unable to chdir to $ENV{HOME}: $!";

my $paths = Developer::Dashboard::PathRegistry->new;
my $collector = Developer::Dashboard::Collector->new(paths => $paths);
my $indicators = Developer::Dashboard::IndicatorStore->new(paths => $paths);
my $prompt = Developer::Dashboard::Prompt->new(paths => $paths, indicators => $indicators);

$collector->write_result(
    'example.collector',
    exit_code => 0,
    stdout    => "ok\n",
    stderr    => '',
);

my $status = $collector->read_status('example.collector');
is($status->{last_exit_code}, 0, 'collector status persisted');

$indicators->set_indicator(
    'docker',
    alias          => '🐳',
    label          => 'Docker',
    icon           => '🐳',
    page_status_icon => '&#x2705;',
    status         => 'ok',
    priority       => 10,
    prompt_visible => 1,
);

my @items = $indicators->list_indicators;
is(scalar @items, 1, 'one indicator listed');
is($items[0]{name}, 'docker', 'indicator stored');

my $rendered = $prompt->render(jobs => 2, cwd => '/tmp/project');
like($rendered, qr/^\(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\)/, 'prompt renders legacy timestamp prefix');
like($rendered, qr/✅🐳.*\[\/tmp\/project\]/, 'compact prompt includes status glyph plus indicator icon before the bracketed path');
like($rendered, qr/\(2 jobs\)/, 'job count included');

$indicators->set_indicator(
    'stale',
    label          => 'Stale',
    icon           => 'S',
    status         => 'ok',
    priority       => 5,
    prompt_visible => 1,
);
$indicators->mark_stale('stale');
my $extended = $prompt->render(jobs => 0, cwd => '/tmp/project', mode => 'extended', max_age => 10);
like($extended, qr/SStale/, 'extended prompt still renders stale indicators');
unlike($extended, qr/SStale!/, 'extended prompt does not append invented stale punctuation');
like($extended, qr/✅🐳Docker/, 'extended prompt includes status glyph plus icon and label');
my $colored = $prompt->render(jobs => 0, cwd => '/tmp/project', color => 1);
like($colored, qr/\e\[/, 'prompt can render ANSI color escapes');
my $page_payload = $indicators->page_header_payload;
is_deeply(
    $page_payload->{array},
    [
        { prog => 'docker', alias => '🐳', status => '&#x2705;' },
        { prog => 'stale',  alias => 'S',  status => '&#x2705;' },
    ],
    'page header payload renders legacy status-plus-alias entries',
);
{
    my $repo = "$ENV{HOME}/repo";
    mkdir $repo or die $!;
    mkdir "$repo/.git" or die $!;
    no warnings 'redefine';
    local *Developer::Dashboard::Prompt::_git_branch = sub { 'main' };
    my $with_branch = $prompt->render( jobs => 0, cwd => $repo );
    like( $with_branch, qr/\[~\/repo\].*🌿main/, 'prompt includes git branch in the legacy trailing branch format' );
}

my $core = $indicators->refresh_core_indicators( cwd => "$ENV{HOME}/repo" );
ok(ref($core) eq 'ARRAY' && @$core >= 2, 'core indicators can be refreshed on demand');
{
    my ( $stdout, $stderr, $exit_code ) = capture {
        $indicators->refresh_core_indicators( cwd => "$ENV{HOME}/repo" );
        return 0;
    };
    is( $stderr, '', 'core indicator refresh stays quiet for directories that only contain a placeholder .git path' );
}
{
    my $real_repo = File::Spec->catdir( $ENV{HOME}, 'real-git-repo' );
    mkdir $real_repo or die $!;
    system( 'git', 'init', '-q', $real_repo ) == 0 or die 'git init failed';
    system( 'git', '-C', $real_repo, 'config', 'user.email', 'indicator@example.test' ) == 0 or die 'git config user.email failed';
    system( 'git', '-C', $real_repo, 'config', 'user.name', 'Indicator Coverage' ) == 0 or die 'git config user.name failed';

    my $tracked = File::Spec->catfile( $real_repo, 'README' );
    open my $tracked_fh, '>', $tracked or die $!;
    print {$tracked_fh} "indicator coverage\n";
    close $tracked_fh;
    system( 'git', '-C', $real_repo, 'add', 'README' ) == 0 or die 'git add failed';
    system( 'git', '-C', $real_repo, 'commit', '-q', '-m', 'init' ) == 0 or die 'git commit failed';

    my $clean = $indicators->refresh_core_indicators( cwd => $real_repo );
    my ($clean_git) = grep { $_->{name} eq 'git' } @{$clean};
    is( $clean_git->{status}, 'clean', 'core indicator refresh marks a real clean git work tree as clean' );

    open my $dirty_fh, '>>', $tracked or die $!;
    print {$dirty_fh} "dirty\n";
    close $dirty_fh;

    my $dirty = $indicators->refresh_core_indicators( cwd => $real_repo );
    my ($dirty_git) = grep { $_->{name} eq 'git' } @{$dirty};
    is( $dirty_git->{status}, 'dirty', 'core indicator refresh marks a modified git work tree as dirty' );
}

done_testing;

__END__

=head1 NAME

02-indicator-collector.t - indicator and prompt integration tests

=head1 DESCRIPTION

This test verifies collector output persistence, indicator state storage, and
prompt rendering behavior.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This test is the executable regression contract for collector execution, indicator state, and prompt integration. Read it when you need to understand the real fixture setup, assertions, and failure modes for this slice of the repository instead of guessing from the module names alone.

=head1 WHY IT EXISTS

It exists because collector execution, indicator state, and prompt integration has enough moving parts that a code-only review can miss real regressions. Keeping those expectations in a dedicated test file makes the TDD loop, coverage loop, and release gate concrete.

=head1 WHEN TO USE

Use this file when changing collector execution, indicator state, and prompt integration, when a focused CI failure points here, or when you want a faster regression loop than running the entire suite.

=head1 HOW TO USE

Run it directly with C<prove -lv t/02-indicator-collector.t> while iterating, then keep it green under C<prove -lr t> and the coverage runs before release. 

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, the coverage gates, and the release verification loop all rely on this file to keep this behavior from drifting.

=head1 EXAMPLES

Example 1:

  prove -lv t/02-indicator-collector.t

Run the focused regression test by itself while you are changing the behavior it owns.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/02-indicator-collector.t

Exercise the same focused test while collecting coverage for the library code it reaches.

Example 3:

  prove -lr t

Put the focused fix back through the whole repository suite before calling the work finished.

=for comment FULL-POD-DOC END

=cut
