use strict;
use warnings;

use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

use lib 'lib';

use Developer::Dashboard::CLI::Complete ();
use Developer::Dashboard::CLI::Suggest ();

{
    package Local::CompleteSuggest;

    sub new { bless {}, shift }
    sub top_level_candidates { return qw(docker doctor docker); }
    sub skill_commands { return qw(alpha.run alpha.run beta.go); }
}

{
    no warnings 'redefine';
    local *Developer::Dashboard::CLI::Suggest::new = sub { return Local::CompleteSuggest->new(); };

    is_deeply(
        [ Developer::Dashboard::CLI::Complete::complete( words => [ 'dashboard', '' ], index => 1 ) ],
        [ qw(docker doctor alpha.run beta.go) ],
        'complete returns deduplicated top-level and skill candidates when the current token is empty',
    );
    is_deeply(
        [ Developer::Dashboard::CLI::Complete::complete( words => [ 'd2', 'do' ], index => 1 ) ],
        [ qw(docker doctor) ],
        'complete filters top-level candidates by the current prefix for d2 as well',
    );
    is_deeply(
        [ Developer::Dashboard::CLI::Complete::complete( words => [ 'dashboard', 'docker' ], index => 3 ) ],
        [ qw(compose list enable disable) ],
        'complete treats an out-of-range completion index as an empty current token for second-level built-ins',
    );
}

for my $case (
    [ skills    => [ qw(install enable disable uninstall update list usage) ] ],
    [ docker    => [ qw(compose list enable disable) ] ],
    [ path      => [ qw(list resolve add del locate project-root) ] ],
    [ indicator => [ qw(set list refresh-core) ] ],
    [ collector => [ qw(write-result status list job output inspect log run start stop restart) ] ],
    [ config    => [ qw(init show) ] ],
    [ auth      => [ qw(add-user list-users remove-user) ] ],
    [ page      => [ qw(new save list show encode decode urls render source) ] ],
    [ action    => [qw(run)] ],
    [ serve     => [ qw(logs workers) ] ],
    [ shell     => [ qw(bash zsh sh ps powershell pwsh) ] ],
)
{
    my ( $command, $expected ) = @{$case};
    is_deeply(
        [ Developer::Dashboard::CLI::Complete::_subcommand_candidates($command) ],
        $expected,
        "_subcommand_candidates returns the expected second-level list for $command",
    );
}

is_deeply(
    [ Developer::Dashboard::CLI::Complete::_subcommand_candidates('unknown') ],
    [],
    '_subcommand_candidates returns an empty list for unsupported built-ins',
);

{
    my $error;
    eval { Developer::Dashboard::CLI::Complete::complete( index => 1 ); 1 } or $error = $@;
    like( $error, qr/Missing completion words/, 'complete rejects missing completion words' );
}
{
    my $error;
    eval { Developer::Dashboard::CLI::Complete::complete( words => [] ); 1 } or $error = $@;
    like( $error, qr/Missing completion index/, 'complete rejects missing completion index' );
}
{
    my $error;
    eval { Developer::Dashboard::CLI::Complete::complete( words => 'dashboard', index => 1 ); 1 } or $error = $@;
    like( $error, qr/Completion words must be an array reference/, 'complete rejects non-array completion snapshots' );
}

my $tmp = tempdir( CLEANUP => 1 );
my $cli_root = File::Spec->catdir( $tmp, 'cli-root' );
make_path($cli_root);
_write_executable( File::Spec->catfile( $cli_root, 'custom-tool' ), "#!/usr/bin/env perl\n" );
make_path( File::Spec->catdir( $cli_root, 'folder-command' ) );
make_path( File::Spec->catdir( $cli_root, 'dd' ) );
make_path( File::Spec->catdir( $cli_root, 'ignored.d' ) );
_write_plain_file( File::Spec->catfile( $cli_root, 'not-executable' ), "plain\n" );

my $skill_alpha_root = File::Spec->catdir( $tmp, 'skills', 'alpha-skill' );
my $skill_disabled_root = File::Spec->catdir( $tmp, 'skills', 'disabled-skill' );
make_path( File::Spec->catdir( $skill_alpha_root, 'cli' ) );
make_path( File::Spec->catdir( $skill_alpha_root, 'skills', 'nested', 'cli' ) );
make_path( File::Spec->catdir( $skill_disabled_root, 'cli' ) );
_write_executable( File::Spec->catfile( $skill_alpha_root, 'cli', 'run-test' ), "#!/usr/bin/env perl\n" );
_write_executable( File::Spec->catfile( $skill_alpha_root, 'skills', 'nested', 'cli', 'deep' ), "#!/usr/bin/env perl\n" );
_write_executable( File::Spec->catfile( $skill_disabled_root, 'cli', 'run-test' ), "#!/usr/bin/env perl\n" );
_write_plain_file( File::Spec->catfile( $skill_alpha_root, 'cli', 'skip-me' ), "plain\n" );
make_path( File::Spec->catdir( $skill_alpha_root, 'cli', 'ignored-hook.d' ) );

{
    package Local::SuggestPaths;

    sub new { bless $_[1], $_[0] }
    sub cli_roots { return @{ $_[0]{cli_roots} || [] }; }
    sub installed_skill_roots { return @{ $_[0]{skill_roots} || [] }; }
}

{
    package Local::SuggestManager;

    sub new { bless $_[1], $_[0] }

    sub get_skill_path {
        my ( $self, $name, %args ) = @_;
        return undef if !defined $name || $name eq '';
        return undef if !$args{include_disabled} && !$self->{enabled}{$name};
        return $self->{paths}{$name};
    }

    sub is_enabled {
        my ( $self, $name ) = @_;
        return $self->{enabled}{$name} ? 1 : 0;
    }
}

my $suggest_paths = Local::SuggestPaths->new(
    {
        cli_roots   => [ $cli_root, File::Spec->catdir( $tmp, 'missing-cli-root' ) ],
        skill_roots => [ $skill_alpha_root, $skill_disabled_root ],
    }
);
my $suggest_manager = Local::SuggestManager->new(
    {
        paths => {
            'alpha-skill'    => $skill_alpha_root,
            'disabled-skill' => $skill_disabled_root,
        },
        enabled => {
            'alpha-skill'    => 1,
            'disabled-skill' => 0,
        },
    }
);

my $suggest = Developer::Dashboard::CLI::Suggest->new(
    paths   => $suggest_paths,
    manager => $suggest_manager,
);
isa_ok( $suggest, 'Developer::Dashboard::CLI::Suggest', 'new returns a suggestion helper when explicit paths and manager are supplied' );
isa_ok( Developer::Dashboard::CLI::Suggest->new(), 'Developer::Dashboard::CLI::Suggest', 'new also builds default path and manager objects' );

my @top = $suggest->top_level_candidates;
ok( grep( $_ eq 'docker', @top ), 'top_level_candidates includes built-in helpers' );
ok( grep( $_ eq 'custom-tool', @top ), 'top_level_candidates includes custom runnable files' );
ok( grep( $_ eq 'folder-command', @top ), 'top_level_candidates includes directory-backed commands' );
ok( !grep( $_ eq 'dd', @top ), 'top_level_candidates skips the managed dd helper namespace' );
ok( !grep( $_ eq 'not-executable', @top ), 'top_level_candidates skips plain non-runnable files' );
is( scalar grep( $_ eq 'jq', @top ), 1, 'top_level_candidates keeps canonical helper names unique despite aliases' );

is_deeply(
    [ $suggest->skill_commands('alpha-skill') ],
    [ qw(alpha-skill.run-test alpha-skill.nested.deep) ],
    'skill_commands lists one explicit skill including nested skill trees',
);
is_deeply(
    [ $suggest->skill_commands('missing-skill') ],
    [],
    'skill_commands returns an empty list for unknown skills',
);
is_deeply(
    [ $suggest->skill_commands() ],
    [ qw(alpha-skill.run-test alpha-skill.nested.deep disabled-skill.run-test) ],
    'skill_commands without an explicit skill scans all installed skill roots including disabled ones',
);
{
    no warnings 'redefine';
    local *Developer::Dashboard::InternalCLI::helper_names   = sub { return ('docker'); };
    local *Developer::Dashboard::InternalCLI::helper_aliases = sub { return { alias => 'alias-only' }; };
    ok(
        grep( $_ eq 'alias-only', $suggest->top_level_candidates ),
        'top_level_candidates includes canonical helper names that only appear through aliases',
    );
}

like( $suggest->unknown_command_message('dokr'), qr/Unknown dashboard command 'dokr'\./, 'unknown_command_message reports the mistyped top-level command' );
like( $suggest->unknown_command_message('dokr'), qr/Did you mean:\n  dashboard docker\n/s, 'unknown_command_message includes the closest command suggestion when available' );
unlike( $suggest->unknown_command_message('zzzzzzzz'), qr/Did you mean:/, 'unknown_command_message omits the suggestion block when no close match exists' );

like( $suggest->unknown_skill_command_message( 'missing-skill', 'run-tst' ), qr/Skill 'missing-skill' not found\./, 'unknown_skill_command_message reports missing skills' );
like( $suggest->unknown_skill_command_message( 'missing-skill', 'run-tst' ), qr/dashboard alpha-skill\.run-test/, 'missing-skill guidance suggests close installed dotted commands' );
unlike( $suggest->unknown_skill_command_message( 'missing-skill', 'zzzzzzzz' ), qr/Did you mean:/, 'missing-skill guidance omits suggestions when no close dotted match exists' );

is(
    $suggest->unknown_skill_command_message( 'disabled-skill', 'run-test' ),
    "Skill 'disabled-skill' is disabled.\n\nEnable it with:\n  dashboard skills enable disabled-skill\n",
    'unknown_skill_command_message reports the explicit enable guidance for disabled skills',
);

like( $suggest->unknown_skill_command_message( 'alpha-skill', 'run-tst' ), qr/Command 'run-tst' not found in skill 'alpha-skill'\./, 'unknown_skill_command_message reports missing commands inside installed skills' );
like( $suggest->unknown_skill_command_message( 'alpha-skill', 'run-tst' ), qr/dashboard alpha-skill\.run-test/, 'missing command guidance suggests close dotted commands inside one skill' );
like( $suggest->unknown_skill_command_message( 'alpha-skill', 'zzzzzzzz' ), qr/dashboard alpha-skill\.nested\.deep/, 'missing command guidance can still fall back to nested dotted suggestions for distant command tails' );

ok( grep( $_ eq 'docker', $suggest->top_level_suggestions('dokr') ), 'top_level_suggestions returns the closest built-in command' );
ok( grep( $_ eq 'alpha-skill.run-test', $suggest->skill_command_suggestions('alpha-skill.run-tst') ), 'skill_command_suggestions can rank dotted commands across all skills' );
ok( grep( $_ eq 'alpha-skill.run-test', $suggest->skill_command_suggestions( 'run-tst', 'alpha-skill' ) ), 'skill_command_suggestions can rank commands within one explicit skill' );
is_deeply( [ $suggest->skill_command_suggestions('zzzzzzzz') ], [], 'skill_command_suggestions returns an empty list when nothing is close enough' );

is_deeply(
    [ map { $_->{full} } $suggest->_all_skill_command_entries ],
    [ qw(alpha-skill.run-test alpha-skill.nested.deep disabled-skill.run-test) ],
    '_all_skill_command_entries traverses every installed skill root',
);
is_deeply(
    [ map { $_->{full} } $suggest->_skill_command_entries('alpha-skill') ],
    [ qw(alpha-skill.run-test alpha-skill.nested.deep) ],
    '_skill_command_entries traverses one concrete skill root',
);
is_deeply(
    [ map { $_->{full} } $suggest->_skill_command_entries('missing-skill') ],
    [],
    '_skill_command_entries returns an empty list for missing skills',
);
is_deeply(
    [ map { $_->{full} } $suggest->_collect_skill_commands( $skill_alpha_root, 'alpha-skill' ) ],
    [ qw(alpha-skill.run-test alpha-skill.nested.deep) ],
    '_collect_skill_commands recurses into nested skill trees',
);

is_deeply( [ $suggest->_rank_candidates( undef, [qw(alpha)] ) ], [], '_rank_candidates ignores undefined queries' );
is_deeply( [ $suggest->_rank_candidates( '', [qw(alpha)] ) ], [], '_rank_candidates ignores empty queries' );
is_deeply(
    [ map { $_->{value} } $suggest->_rank_candidates( 'dok', [ qw(docker docker doctor alpha beta gamma delta epsilon) ] ) ],
    [ qw(docker doctor) ],
    '_rank_candidates de-duplicates and sorts close matches',
);
is_deeply(
    [ map { $_->{value} } $suggest->_rank_candidates( 'dok', [ undef, '', qw(docker docker) ] ) ],
    [qw(docker)],
    '_rank_candidates skips undef and empty candidate values before scoring',
);
is_deeply(
    [ map { $_->{value} } $suggest->_rank_candidates( 'foo', [ qw(foog foof fooe food fooc foob fooa) ] ) ],
    [ qw(fooa foob fooc food fooe) ],
    '_rank_candidates applies deterministic tie-break sorting and truncates to the best five suggestions',
);

is( Developer::Dashboard::CLI::Suggest::_candidate_score( 'docker', 'docker' ), 0, '_candidate_score returns zero for exact matches' );
is( Developer::Dashboard::CLI::Suggest::_candidate_score( 'doc', 'doctor' ), 1, '_candidate_score prefers prefix matches' );
ok( !defined Developer::Dashboard::CLI::Suggest::_candidate_score( 'x', 'very-different' ), '_candidate_score rejects distant matches' );
is( Developer::Dashboard::CLI::Suggest::_normalize_token('Alpha-skill.run_test'), 'alphaskillruntest', '_normalize_token strips punctuation and lowercases command tokens' );
is( Developer::Dashboard::CLI::Suggest::_normalize_token(undef), '', '_normalize_token treats undef as an empty token' );
is( Developer::Dashboard::CLI::Suggest::_levenshtein_distance( 'kitten', 'sitting' ), 3, '_levenshtein_distance computes edit distance without extra dependencies' );
is( Developer::Dashboard::CLI::Suggest::_logical_command_name('tool.go'), 'tool', '_logical_command_name strips supported source-script extensions' );
is( Developer::Dashboard::CLI::Suggest::_logical_command_name(undef), '', '_logical_command_name returns an empty string for undef input' );

done_testing;

sub _write_executable {
    my ( $path, $content ) = @_;
    open my $fh, '>', $path or die "Unable to write $path: $!";
    print {$fh} $content;
    close $fh or die "Unable to close $path: $!";
    chmod 0755, $path or die "Unable to chmod $path: $!";
    return 1;
}

sub _write_plain_file {
    my ( $path, $content ) = @_;
    open my $fh, '>', $path or die "Unable to write $path: $!";
    print {$fh} $content;
    close $fh or die "Unable to close $path: $!";
    return 1;
}

__END__

=pod

=head1 NAME

t/39-cli-suggest-complete-coverage.t - focused branch coverage for CLI suggestion and completion helpers

=head1 SYNOPSIS

  prove -lv t/39-cli-suggest-complete-coverage.t

=head1 DESCRIPTION

This test file exercises the pure-Perl branch logic in
C<Developer::Dashboard::CLI::Complete> and
C<Developer::Dashboard::CLI::Suggest> so the shell-completion and typo-guidance
helpers stay fully covered.

=head1 PURPOSE

It exists to pin every branch in the new command-completion and command-
suggestion modules, including disabled-skill guidance, no-suggestion paths,
deduplication, and nested skill discovery.

=head1 WHY IT EXISTS

The broader CLI smoke tests prove the public behavior, but they do not hit
every error branch and every small helper in these two lightweight modules.
This file closes that gap so the repo can keep the 100 percent coverage rule.

=head1 WHEN TO USE

Run this test after changing shell completion, typo guidance, or dotted skill
command discovery.

=head1 HOW TO USE

Execute it directly with C<prove -lv> during focused TDD, then include it in
the normal full-suite and C<Devel::Cover> gates.

=head1 WHAT USES IT

Developers use it while changing the switchboard UX. The coverage gate uses it
indirectly through the normal repository test run.

=head1 EXAMPLES

Example 1:

  prove -lv t/39-cli-suggest-complete-coverage.t

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/39-cli-suggest-complete-coverage.t

=cut
