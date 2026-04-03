use strict;
use warnings;

use Cwd qw(getcwd);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

use lib 'lib';

use Developer::Dashboard::ActionRunner;
use Developer::Dashboard::Auth;
use Developer::Dashboard::Collector;
use Developer::Dashboard::CollectorRunner;
use Developer::Dashboard::Config;
use Developer::Dashboard::DockerCompose;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::IndicatorStore;
use Developer::Dashboard::PageDocument;
use Developer::Dashboard::PageResolver;
use Developer::Dashboard::PageRuntime;
use Developer::Dashboard::PageStore;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::Prompt;
use Developer::Dashboard::SessionStore;
use Developer::Dashboard::Web::App;

# dies_like($code, $pattern, $label)
# Runs a code reference and asserts that it dies with the expected pattern.
# Input: code reference, regex pattern, and test label.
# Output: Test::More assertion result.
sub dies_like {
    my ( $code, $pattern, $label ) = @_;
    my $error = eval { $code->(); 1 } ? '' : $@;
    like( $error, $pattern, $label );
}

my $home = tempdir(CLEANUP => 1);
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";

my $repo = File::Spec->catdir( $home, 'projects', 'coverage-app' );
my $bin  = File::Spec->catdir( $home, 'bin' );
make_path( File::Spec->catdir( $repo, '.git' ), $bin );

open my $compose_fh, '>', File::Spec->catfile( $repo, 'compose.yaml' ) or die $!;
print {$compose_fh} "services:\n  app:\n    image: perl:latest\n";
close $compose_fh;
open my $compose_dev_fh, '>', File::Spec->catfile( $repo, 'compose.dev.yaml' ) or die $!;
print {$compose_dev_fh} "services:\n  app:\n    environment:\n      MODE: dev\n";
close $compose_dev_fh;
open my $compose_worker_fh, '>', File::Spec->catfile( $repo, 'compose.worker.yaml' ) or die $!;
print {$compose_worker_fh} "services:\n  worker:\n    image: perl:latest\n";
close $compose_worker_fh;
open my $compose_debug_fh, '>', File::Spec->catfile( $repo, 'compose.debug.yaml' ) or die $!;
print {$compose_debug_fh} "services:\n  debug:\n    image: alpine\n";
close $compose_debug_fh;
open my $compose_test_fh, '>', File::Spec->catfile( $repo, 'compose.test.yaml' ) or die $!;
print {$compose_test_fh} "services:\n  test:\n    image: alpine\n";
close $compose_test_fh;

open my $repo_cfg_fh, '>', File::Spec->catfile( $repo, '.developer-dashboard.json' ) or die $!;
print {$repo_cfg_fh} <<'JSON';
{
  "nested": { "repo": 1 },
  "collectors": [
    { "name": "repo.collector", "command": "printf repo", "cwd": "home", "interval": 5 },
    { "name": "cfg.collector", "command": "printf cfg", "cwd": "home", "interval": 7 }
  ],
  "providers": [
    { "id": "cfg-provider", "title": "Config Provider", "body": "cfg page body" },
    { "id": "shared-provider", "page": { "id": "shared-provider", "title": "Shared Provider", "layout": { "body": "shared body" } } }
  ],
  "docker": {
    "files": ["compose.dev.yaml", "compose.test.yaml"],
    "project_overlays": ["compose.test.yaml"],
    "services": {
      "worker": { "files": ["compose.worker.yaml"] }
    },
    "addons": {
      "debug": {
        "files": ["compose.debug.yaml"],
        "modes": ["dev"],
        "env": { "DEBUG_ENABLED": "1" }
      },
      "extra": {
        "files": ["compose.debug.yaml"]
      }
    },
    "modes": {
      "dev": {
        "files": ["compose.dev.yaml"],
        "env": { "APP_MODE": "dev" }
      }
    }
  }
}
JSON
close $repo_cfg_fh;

open my $docker_bin_fh, '>', File::Spec->catfile( $bin, 'docker' ) or die $!;
print {$docker_bin_fh} <<"SH";
#!/bin/sh
printf 'ARGS:%s\n' "\$*"
printf 'DEBUG:%s\n' "\${DEBUG_ENABLED:-}"
printf 'MODE:%s\n' "\${APP_MODE:-}"
SH
close $docker_bin_fh;
chmod 0755, File::Spec->catfile( $bin, 'docker' );
local $ENV{PATH} = $bin . ':' . ( $ENV{PATH} || '' );

my $paths = Developer::Dashboard::PathRegistry->new(
    home            => $home,
    workspace_roots => [ File::Spec->catdir( $home, 'projects' ) ],
    project_roots   => [ File::Spec->catdir( $home, 'projects' ) ],
);
my $files = Developer::Dashboard::FileRegistry->new( paths => $paths );
my $config = Developer::Dashboard::Config->new( files => $files, paths => $paths, repo_root => $repo );
$config->save_global(
    {
        nested     => { global => 1 },
        collectors => [
            { name => 'global.collector', command => 'printf global', cwd => 'home', interval => 3 },
        ],
    }
);

my $merged = $config->merged;
ok( $merged->{nested}{global}, 'config merged keeps global nested hash values' );
ok( $merged->{nested}{repo}, 'config merged keeps repo nested hash values' );
my $jobs = $config->collectors;
is( scalar( grep { $_->{name} eq 'repo.collector' } @$jobs ), 1, 'config collectors include repo collectors' );
is( scalar( grep { $_->{name} eq 'cfg.collector' } @$jobs ), 1, 'config collectors include additional config collectors' );

my $pages = Developer::Dashboard::PageStore->new( paths => $paths );
my $actions = Developer::Dashboard::ActionRunner->new( files => $files, paths => $paths );
my $resolver = Developer::Dashboard::PageResolver->new(
    actions => $actions,
    config  => $config,
    pages   => $pages,
    paths   => $paths,
);

my $listed_page = Developer::Dashboard::PageDocument->new(
    id     => 'listed-saved',
    title  => 'Listed Saved',
    layout => { body => 'listed' },
);
$pages->save_page($listed_page);
ok( scalar( grep { $_ eq 'shared-provider' } $resolver->list_pages ), 'page resolver lists config page providers' );
ok( scalar( grep { $_ eq 'listed-saved' } $resolver->list_pages ), 'page resolver lists saved pages alongside providers' );
like( $resolver->load_named_page('system-status')->as_hash->{layout}{body}, qr/runtime paths/i, 'page resolver loads builtin system status page' );
like( $resolver->load_named_page('project-context')->as_hash->{layout}{body}, qr/Current project root/, 'page resolver loads builtin project context page' );
is( $resolver->load_named_page('cfg-provider')->as_hash->{title}, 'Config Provider', 'page resolver loads fallback provider pages' );

my $instruction = <<'PAGE';
TITLE: Coverage Page
:--------------------------------------------------------------------------------:
ICON: @
:--------------------------------------------------------------------------------:
BOOKMARK: coverage-page
:--------------------------------------------------------------------------------:
NOTE: Coverage page description
:--------------------------------------------------------------------------------:
STASH:
:--------------------------------------------------------------------------------:
HTML: coverage body
:--------------------------------------------------------------------------------:
CODE0: say "hi";
PAGE

my $page = Developer::Dashboard::PageDocument->from_instruction($instruction);
is_deeply( $page->as_hash->{state}, {}, 'page document normalizes invalid STASH sections to empty hash' );
like( $page->canonical_instruction, qr/^ICON:\s+\@/m, 'page document preserves ICON section' );
like( $page->canonical_instruction, qr/^CODE0:\s+say "hi";/m, 'page document preserves CODE sections' );
is( $page->instruction_text, $page->canonical_instruction, 'instruction_text aliases canonical instruction' );

my $script_page = Developer::Dashboard::PageDocument->new(
    id       => 'script-page',
    title    => 'Script Page',
    layout   => { body => 'body' },
    inputs   => [ { name => 'name', default => 'Michael' } ],
    state    => { name => 'Michael' },
    meta     => {
        scripts => [ undef, { bad => 1 }, 'console.log("ok");' ],
        codes   => [ { bad => 1 }, { id => 'BAD' }, { id => 'CODE1', body => 'print 1;' } ],
    },
    actions  => [],
);
my $script_html = $script_page->render_html( page_url => '/app/script-page' );
like( $script_html, qr/<section class="body">body<\/section>/, 'page render keeps bookmark body content' );
like( $script_page->canonical_instruction, qr/^CODE1:\s+print 1;/m, 'page document serializes valid meta code entries only' );

my $legacy_nested = Developer::Dashboard::PageDocument->new(
    id    => 'legacy-nested',
    title => 'Legacy Nested',
    state => {
        list => [ 'a', 'b' ],
        map  => { one => 1 },
    },
    meta => { source_format => 'legacy' },
);
like( $legacy_nested->canonical_instruction, qr/list => \[/, 'legacy instruction serializes array stash values' );
like( $legacy_nested->canonical_instruction, qr/map => \{/, 'legacy instruction serializes hash stash values' );

my $form_page = Developer::Dashboard::PageDocument->new(
    id     => 'form-page',
    title  => 'Form Page',
    layout => {
        body    => 'body',
        form    => '<form>FORM</form>',
        form_tt => '<div>FORMTT</div>',
    },
    meta => {
        runtime_errors => ['runtime failure'],
    },
);
my $form_html = $form_page->render_html( page_url => '/app/form-page' );
like( $form_html, qr/<form>FORM<\/form>/, 'page render includes legacy FORM blocks' );
like( $form_html, qr/<div>FORMTT<\/div>/, 'page render includes legacy FORM\.TT blocks' );
like( $form_html, qr/runtime-error/, 'page render includes runtime error markup' );

my $saved_page = Developer::Dashboard::PageDocument->new(
    id          => 'saved-page',
    title       => 'Saved Page',
    layout      => { body => 'saved body' },
    actions     => [
        { id => 'alias-run', kind => 'command', command => 'printf alias-ok', cwd => 'home' },
    ],
    permissions => {},
);
$pages->save_page($saved_page);
my $alias_result = $actions->run_page_action(
    action => $saved_page->as_hash->{actions}[0],
    page   => $saved_page,
    source => 'saved',
);
like( $alias_result->{stdout}, qr/alias-ok/, 'action runner resolves named cwd aliases' );

my $background_result = $actions->run_command_action(
    command    => 'printf background-ok',
    cwd        => $repo,
    background => 1,
    timeout_ms => 1000,
);
ok( $background_result->{pid} > 0, 'background action forks a child process' );
waitpid( $background_result->{pid}, 0 );
ok( !kill( 0, $background_result->{pid} ), 'background action child exits cleanly after running' );

ok(
    !$actions->_is_action_trusted(
        action => { id => 'blocked' },
        page   => Developer::Dashboard::PageDocument->new( permissions => { allow_untrusted_actions => 1, trusted_actions => ['other'] } ),
        source => 'transient',
    ),
    'action runner rejects transient actions missing from trusted_actions allowlist',
);
ok(
    !$actions->_is_action_trusted(
        action => { id => 'blocked' },
        page   => Developer::Dashboard::PageDocument->new( permissions => { allow_untrusted_actions => 1 } ),
        source => 'transient',
    ),
    'action runner rejects transient actions without a trusted_actions array',
);

my $collector = Developer::Dashboard::Collector->new( paths => $paths );
my $indicators = Developer::Dashboard::IndicatorStore->new( paths => $paths );
my $runner = Developer::Dashboard::CollectorRunner->new(
    collectors => $collector,
    files      => $files,
    indicators => $indicators,
    paths      => $paths,
);

my $collector_result = $runner->run_once(
    {
        name      => 'coverage.collector',
        command   => 'printf collector-ok',
        cwd       => 'home',
        interval  => 2,
        indicator => { name => 'coverage.collector', icon => 'C' },
    }
);
is( $collector_result->{exit_code}, 0, 'collector runner executes collector jobs from named cwd aliases' );
is( $indicators->get_indicator('coverage.collector')->{prompt_visible}, 1, 'collector indicator defaults prompt visibility to true' );
my $collector_code_result = $runner->run_once(
    {
        name      => 'coverage.collector.code',
        code      => q{return 0;},
        cwd       => 'home',
        interval  => 2,
        indicator => { name => 'coverage.collector.code', icon => 'K' },
    }
);
is( $collector_code_result->{exit_code}, 0, 'collector runner executes perl code collectors from named cwd aliases' );
ok( $runner->_job_is_due( { schedule => 'cron', cron => '* * * * *' }, 'coverage.collector' ), 'collector runner treats cron jobs as due on first slot' );
ok( !$runner->_cron_due( 'bogus', 'coverage.collector' ), 'collector runner rejects invalid cron expressions' );
my @now = localtime();
my $current_cron = join ' ', $now[1], $now[2], $now[3], $now[4] + 1, $now[6];
ok( $runner->_cron_due( $current_cron, 'coverage.collector.explicit' ), 'collector runner accepts explicit matching cron slots' );
ok( !$runner->_cron_due( $current_cron, 'coverage.collector.explicit' ), 'collector runner de-duplicates repeated explicit cron slots' );
ok( Developer::Dashboard::CollectorRunner::_cron_match( '1-5', 3 ), 'collector runner cron matcher supports numeric ranges' );

my $runtime = Developer::Dashboard::PageRuntime->new;
my $runtime_page = Developer::Dashboard::PageDocument->new(
    id    => 'runtime-page',
    title => 'Runtime Page',
    state => { alpha => 'one' },
    meta  => {
        codes => [
            { id => 'CODE1', body => 'print "OUT"; return { beta => "two" };' },
        ],
    },
);
my $runtime_result = $runtime->run_code_blocks( page => $runtime_page, source => 'saved' );
is( $runtime_page->as_hash->{state}{beta}, 'two', 'page runtime merges returned hash values into page state' );
like( join( '', @{ $runtime_result->{outputs} } ), qr/OUT/, 'page runtime captures printed output' );
like( join( '', @{ $runtime_result->{outputs} } ), qr/beta => 'two'/, 'page runtime dumps returned hash values into runtime output' );
unlike( join( '', @{ $runtime_result->{outputs} } ), qr/OUT1/, 'page runtime does not append Perl print return values to output' );
is( $runtime->_runtime_value_text(undef), '', 'runtime value serializer ignores undefined values' );
is( $runtime->_runtime_value_text('plain text'), '', 'runtime value serializer ignores non-reference scalar values' );
like( $runtime->_runtime_value_text( [ 'one', { two => 2 } ] ), qr/\[\s+'one',\s+\{\s+two => 2\s+\}\s+\]/s, 'runtime value serializer formats array values for runtime output' );
is( Developer::Dashboard::PageRuntime::_runtime_legacy_value(undef), 'undef', 'legacy runtime serializer formats undefined values explicitly' );
is( Developer::Dashboard::PageRuntime::_runtime_legacy_value(12), 12, 'legacy runtime serializer leaves numeric scalars unquoted' );
is( Developer::Dashboard::PageRuntime::_runtime_legacy_value(q{it's}), q{'it\\'s'}, 'legacy runtime serializer quotes plain strings safely' );

my $silent_merge_page = Developer::Dashboard::PageDocument->new(
    meta => {
        codes => [
            { id => 'CODE1', body => q{{foo => "hello"}} },
            { id => 'CODE2', body => q{{bar => "world"}} },
            { id => 'CODE3', body => q{print "$foo $bar"} },
        ],
    },
);
my $silent_merge_result = $runtime->run_code_blocks( page => $silent_merge_page, source => 'saved' );
like( join( '', @{ $silent_merge_result->{outputs} } ), qr/foo => 'hello'/, 'returned hash values are dumped into runtime output' );
like( join( '', @{ $silent_merge_result->{outputs} } ), qr/bar => 'world'/, 'later returned hash values are also dumped into runtime output' );
like( join( '', @{ $silent_merge_result->{outputs} } ), qr/hello world/, 'later CODE blocks can still use merged stash values' );

my $same_page_package_page = Developer::Dashboard::PageDocument->new(
    meta => {
        codes => [
            { id => 'CODE1', body => q{our $persist = "shared"; return;} },
            { id => 'CODE2', body => q{our $persist; print $persist;} },
        ],
    },
);
my $same_page_package_result = $runtime->run_code_blocks( page => $same_page_package_page, source => 'saved' );
is( join( '', @{ $same_page_package_result->{outputs} } ), 'shared', 'page runtime reuses one sandpit package across CODE blocks in the same page run' );

my $isolated_page_one = Developer::Dashboard::PageDocument->new(
    meta => {
        codes => [
            { id => 'CODE1', body => q{our $persist = "leak-test"; print $persist;} },
        ],
    },
);
my $isolated_page_two = Developer::Dashboard::PageDocument->new(
    meta => {
        codes => [
            { id => 'CODE1', body => q{our $persist; print defined $persist ? $persist : "fresh";} },
        ],
    },
);
my $isolated_page_one_result = $runtime->run_code_blocks( page => $isolated_page_one, source => 'saved' );
my $isolated_page_two_result = $runtime->run_code_blocks( page => $isolated_page_two, source => 'saved' );
is( join( '', @{ $isolated_page_one_result->{outputs} } ), 'leak-test', 'first page run can use package globals inside its own sandpit' );
is( join( '', @{ $isolated_page_two_result->{outputs} } ), 'fresh', 'later page runs get a fresh sandpit package with no leaked package globals' );

my $hide_result = $runtime->run_code_blocks(
    page => Developer::Dashboard::PageDocument->new(
        meta => { codes => [ { id => 'CODE1', body => 'hide();' } ] },
    ),
    source => 'saved',
);
is_deeply( $hide_result->{outputs}, [], 'page runtime hide helper suppresses block output' );

my $legacy_hide_signal_result = $runtime->run_code_blocks(
    page => Developer::Dashboard::PageDocument->new(
        meta => {
            codes => [
                { id => 'CODE1', body => 'die "__DD_HIDE__";' },
                { id => 'CODE2', body => 'print "after-hide";' },
            ],
        },
    ),
    source => 'saved',
);
is( join( '', @{ $legacy_hide_signal_result->{outputs} } ), 'after-hide', 'page runtime still honors legacy hide sentinel errors by skipping only the current block' );
is_deeply( $legacy_hide_signal_result->{errors}, [], 'legacy hide sentinel does not surface as a visible error' );

my $prepare_merge_page = Developer::Dashboard::PageDocument->new(
    title  => 'Developer Dashboard',
    layout => { body => '<h1>[% title %]</h1>[% stash.a %]' },
    meta   => {
        codes => [
            { id => 'CODE1', body => '{ a => 1 }' },
            { id => 'CODE2', body => 'hide print $a' },
        ],
    },
);
my $prepare_merge_result = $runtime->prepare_page(
    page   => $prepare_merge_page,
    source => 'saved',
);
like( $prepare_merge_result->{layout}{body}, qr{<h1>Developer Dashboard</h1>1}, 'prepare_page renders returned CODE hash values into HTML stash data' );
like( join( '', @{ $prepare_merge_result->{meta}{runtime_outputs} || [] } ), qr/a => 1/, 'returned CODE hash values are dumped into rendered runtime output' );
like( join( '', @{ $prepare_merge_result->{meta}{runtime_outputs} || [] } ), qr/1/, 'hide print keeps printed output but suppresses the print return value' );

my $stop_result = $runtime->run_code_blocks(
    page => Developer::Dashboard::PageDocument->new(
        meta => { codes => [ { id => 'CODE1', body => 'stop("halt");' }, { id => 'CODE2', body => 'print "later";' } ] },
    ),
    source => 'saved',
);
like( $stop_result->{errors}[0], qr/^halt\b/, 'page runtime stop helper captures stop message and halts further blocks' );

my $error_result = $runtime->run_code_blocks(
    page => Developer::Dashboard::PageDocument->new(
        meta => { codes => [ { id => 'CODE1', body => 'die "boom";' } ] },
    ),
    source => 'saved',
);
like( $error_result->{errors}[0], qr/boom/, 'page runtime captures generic code errors' );

my $transient_code_page = Developer::Dashboard::PageDocument->new(
    meta => { codes => [ { id => 'CODE1', body => 'print "transient-code";' } ] },
);
my $transient_code_result = $runtime->run_code_blocks( page => $transient_code_page, source => 'transient' );
like( join( '', @{ $transient_code_result->{outputs} } ), qr/transient-code/, 'page runtime allows transient code through the legacy runtime' );

dies_like(
    sub {
        $runtime->_run_single_block( code => 'not perl !!!', state => {} );
    },
    qr/syntax error|Bareword|Compilation failed/s,
    'page runtime surfaces code compilation failures',
);

my $docker = Developer::Dashboard::DockerCompose->new(
    config  => $config,
    paths   => $paths,
);
my $resolved = $docker->resolve(
    project_root => $repo,
    addons       => ['debug'],
    modes        => [],
    services     => ['worker'],
    args         => ['config'],
);
ok( scalar( grep { $_ =~ /compose\.debug\.yaml$/ } @{ $resolved->{files} } ), 'docker resolve includes addon overlays' );
ok( scalar( grep { $_ eq 'dev' } @{ $resolved->{modes} } ), 'docker resolve pulls addon-provided modes into the resolution' );

my $docker_run = $docker->run(
    project_root => $repo,
    addons       => ['debug'],
    services     => ['worker'],
    args         => ['config'],
);
is( $docker_run->{exit_code}, 0, 'docker compose wrapper executes stub docker successfully' );
like( $docker_run->{stdout}, qr/DEBUG:1/, 'docker compose wrapper injects addon environment into command execution' );
like( $docker_run->{stdout}, qr/MODE:dev/, 'docker compose wrapper injects mode environment into command execution' );

{
    package Local::ActionMock;
    # new()
    # Constructs a mock action runner returning generic hash results.
    # Input: none.
    # Output: Local::ActionMock object.
    sub new { bless {}, shift }
    # run_page_action()
    # Returns a generic action result without a body field.
    # Input: ignored.
    # Output: hash reference.
    sub run_page_action    { return { ok => 1 } }
    # run_encoded_action()
    # Returns a generic encoded action result without a body field.
    # Input: ignored.
    # Output: hash reference.
    sub run_encoded_action { return { ok => 1 } }
}

{
    package Local::ActionDie;
    # new()
    # Constructs a mock action runner that always throws.
    # Input: none.
    # Output: Local::ActionDie object.
    sub new { bless {}, shift }
    # run_page_action()
    # Throws a page action denial error for coverage of web error handling.
    # Input: ignored.
    # Output: never returns.
    sub run_page_action    { die "denied\n" }
    # run_encoded_action()
    # Throws an encoded action denial error for coverage of web error handling.
    # Input: ignored.
    # Output: never returns.
    sub run_encoded_action { die "encoded denied\n" }
}

my $auth = Developer::Dashboard::Auth->new( files => $files, paths => $paths );
my $sessions = Developer::Dashboard::SessionStore->new( paths => $paths );

my $web_json = Developer::Dashboard::Web::App->new(
    actions  => Local::ActionMock->new,
    auth     => $auth,
    pages    => $pages,
    resolver => $resolver,
    sessions => $sessions,
);
my $web_die = Developer::Dashboard::Web::App->new(
    actions  => Local::ActionDie->new,
    auth     => $auth,
    pages    => $pages,
    resolver => $resolver,
    sessions => $sessions,
);

my $web_page = $saved_page;
my $json_action = $web_json->_action_response(
    id     => 'alias-run',
    page   => $web_page,
    source => 'saved',
    params => {},
);
is( $json_action->[0], 200, 'web app wraps bodyless action results in JSON responses' );
like( $json_action->[2], qr/"ok"\s*:\s*1/, 'web app JSON-encodes generic action results' );

my $encoded_token = $actions->encode_action_payload(
    action => { id => 'enc', kind => 'builtin', builtin => 'page.state', safe => 1 },
    page   => $web_page,
    source => 'saved',
);
my $json_encoded = $web_json->_encoded_action_response( token => $encoded_token, params => {} );
is( $json_encoded->[0], 200, 'web app wraps bodyless encoded action results in JSON responses' );
like( $json_encoded->[2], qr/"ok"\s*:\s*1/, 'web app JSON-encodes generic encoded action results' );

my $die_action = $web_die->_action_response(
    id     => 'alias-run',
    page   => $web_page,
    source => 'saved',
    params => {},
);
is( $die_action->[0], 403, 'web app converts action runner exceptions into 403 responses' );

my $die_encoded = $web_die->_encoded_action_response( token => $encoded_token, params => {} );
is( $die_encoded->[0], 403, 'web app converts encoded action exceptions into 403 responses' );

my $prompt = Developer::Dashboard::Prompt->new( indicators => $indicators, paths => $paths );
my $project_only_prompt = $prompt->render( cwd => $repo, jobs => 0 );
like( $project_only_prompt, qr/\{coverage-app\}/, 'prompt renders project-only context when git branch is unavailable' );

{
    no warnings 'redefine';
    local *Developer::Dashboard::Prompt::_git_branch = sub { return 'main' };
    local *Developer::Dashboard::PathRegistry::project_root_for = sub { return undef };
    my $branch_only_prompt = $prompt->render( cwd => File::Spec->catdir( $home, 'outside' ), jobs => 0 );
    like( $branch_only_prompt, qr/\{main\}/, 'prompt renders branch-only context when no project root resolves' );
}

done_testing;

__END__

=head1 NAME

11-coverage-closure.t - targeted branch coverage closure tests

=head1 DESCRIPTION

This test hits the remaining private and fallback branches needed to keep the
Developer Dashboard library coverage at 100 percent.

=cut
