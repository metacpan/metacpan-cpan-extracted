use strict;
use warnings;

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
like($rendered, qr/\[\w{3}|\[/, 'prompt rendered');
like($rendered, qr/\] ✅🐳 /, 'compact prompt includes status glyph plus indicator icon');
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
        { prog => 'stale',  alias => 'Stale',  status => '&#x2705;' },
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
    like( $with_branch, qr/\{repo:main\}/, 'prompt includes repo name and git branch' );
}

my $core = $indicators->refresh_core_indicators( cwd => "$ENV{HOME}/repo" );
ok(ref($core) eq 'ARRAY' && @$core >= 2, 'core indicators can be refreshed on demand');

done_testing;

__END__

=head1 NAME

02-indicator-collector.t - indicator and prompt integration tests

=head1 DESCRIPTION

This test verifies collector output persistence, indicator state storage, and
prompt rendering behavior.

=cut
