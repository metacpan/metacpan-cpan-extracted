#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use Capture::Tiny qw(capture);
use Cwd qw(abs_path cwd);
use File::Basename qw(basename);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);

use lib 'lib';

use Developer::Dashboard::CLI::Paths ();
use Developer::Dashboard::PathRegistry;

# Warnings are fatal in this repository: collect any that escape and assert the
# whole run stayed clean.
my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0]; return; };

# Hermetic runtime rooted at a temp home. The config root resolves from the
# deepest .developer-dashboard layer above the cwd, so chdir into the temp home
# before building any registry or running any command.
my $home = abs_path( tempdir( CLEANUP => 1 ) );
local $ENV{HOME}                           = $home;
local $ENV{DEVELOPER_DASHBOARD_STATE_ROOT} = tempdir( CLEANUP => 1 );
chdir $home or die "Unable to chdir to $home: $!";

my $cwd       = cwd();
my $preferred = basename($cwd);

my $run              = \&Developer::Dashboard::CLI::Paths::run_paths_command;
my $build_paths      = \&Developer::Dashboard::CLI::Paths::_build_paths;
my $normalize_delete = \&Developer::Dashboard::CLI::Paths::_normalize_delete_argument;
my $cdr_payload      = \&Developer::Dashboard::CLI::Paths::_cdr_payload;
my $cdr_completion   = \&Developer::Dashboard::CLI::Paths::_cdr_completion;
my $initial          = \&Developer::Dashboard::CLI::Paths::_cdr_initial_candidates;
my $dir_candidates   = \&Developer::Dashboard::CLI::Paths::_cdr_directory_candidates;
my $paths_table      = \&Developer::Dashboard::CLI::Paths::_paths_table;
my $aliases_table    = \&Developer::Dashboard::CLI::Paths::_aliases_table;
my $list_table       = \&Developer::Dashboard::CLI::Paths::_list_table;
my $mutation_table   = \&Developer::Dashboard::CLI::Paths::_mutation_table;
my $removal_table    = \&Developer::Dashboard::CLI::Paths::_removal_table;
my $render_table     = \&Developer::Dashboard::CLI::Paths::_render_table;

{
    package Test::CLIPaths::PathsStub;

    # new(%args)
    # Builds one injectable stand-in for the path registry so the module's
    # defensive fallbacks can be driven with payloads a real registry never
    # produces.
    # Input: named_paths hash reference or undef, dirs array reference, cwd
    # string, and an expand code reference.
    # Output: Test::CLIPaths::PathsStub object.
    sub new {
        my ( $class, %args ) = @_;
        return bless {%args}, $class;
    }

    # named_paths()
    # Returns the stubbed alias inventory, including the undef payload used to
    # drive the module's empty-registry fallback.
    # Input: none.
    # Output: hash reference or undef.
    sub named_paths { return $_[0]->{named_paths}; }

    # current_working_directory()
    # Returns the stubbed invocation directory.
    # Input: none.
    # Output: directory path string.
    sub current_working_directory { return $_[0]->{cwd}; }

    # locate_dirs_under($root, @terms)
    # Returns the canned match list, including undef, empty, root-equal, and
    # duplicate-basename entries.
    # Input: search root and narrowing terms, both ignored by the stub.
    # Output: list of match entries.
    sub locate_dirs_under {
        my ($self) = @_;
        return @{ $self->{dirs} || [] };
    }

    # _expand_home($path)
    # Delegates to the injected home-expansion code reference.
    # Input: raw alias target string.
    # Output: whatever the injected code reference returns, or dies.
    sub _expand_home {
        my ( $self, $path ) = @_;
        return $self->{expand}->($path);
    }
}

{
    package Test::CLIPaths::ConfigStub;

    # new(%args)
    # Builds one injectable stand-in for the config object.
    # Input: path_aliases hash reference or undef.
    # Output: Test::CLIPaths::ConfigStub object.
    sub new {
        my ( $class, %args ) = @_;
        return bless {%args}, $class;
    }

    # path_aliases()
    # Returns the stubbed alias mapping, including the undef payload used to
    # drive the module's empty-alias fallback.
    # Input: none.
    # Output: hash reference or undef.
    sub path_aliases { return $_[0]->{path_aliases}; }
}

subtest 'run_paths_command rejects malformed dispatch arguments' => sub {
    my $missing_command = eval { $run->( args => [] ); 1 };
    is( $missing_command, undef, 'a missing command name aborts dispatch' );
    like( $@, qr/^Missing command name$/m, 'the missing command name is reported' );

    my $missing_args = eval { $run->( command => 'paths' ); 1 };
    is( $missing_args, undef, 'missing command arguments abort dispatch' );
    like( $@, qr/^Missing command arguments$/m, 'the missing argument list is reported' );

    my $bad_args = eval { $run->( command => 'paths', args => {} ); 1 };
    is( $bad_args, undef, 'a non-array argument payload aborts dispatch' );
    like( $@, qr/^Command arguments must be an array reference$/m, 'the argument type error is reported' );
};

subtest 'paths and path list reject leftover positional arguments' => sub {
    my $paths_extra = eval { $run->( command => 'paths', args => ['leftover'] ); 1 };
    is( $paths_extra, undef, 'dashboard paths refuses a stray positional argument' );
    like( $@, qr/^Usage: dashboard paths \[-o json\|table\]$/m, 'the paths usage message is printed' );

    my $list_extra = eval { $run->( command => 'path', args => [ 'list', 'leftover' ] ); 1 };
    is( $list_extra, undef, 'dashboard path list refuses a stray positional argument' );
    like( $@, qr/^Usage: dashboard path list \[-o json\|table\]$/m, 'the list usage message is printed' );
};

subtest 'path dispatch reports usage for missing verbs and operands' => sub {
    my $no_action = eval { $run->( command => 'path', args => [] ); 1 };
    is( $no_action, undef, 'an empty path argument list falls through to the dispatch usage error' );
    like( $@, qr/^Usage: dashboard path <resolve\|locate\|cdr\|complete-cdr\|add\|del\|rm\|project-root\|list> \.\.\.$/m,
        'the path dispatch usage message is printed' );

    my $no_name = eval { $run->( command => 'path', args => ['resolve'] ); 1 };
    is( $no_name, undef, 'path resolve without a name aborts' );
    like( $@, qr/^Usage: dashboard path resolve <name>$/m, 'the resolve usage message is printed' );
};

subtest 'path complete-cdr defaults a missing or empty completion index' => sub {
    my ( $missing_index_out, $missing_index_err ) = capture {
        $run->( command => 'path', args => ['complete-cdr'] );
    };
    is( $missing_index_out, "\n", 'a missing completion index yields no candidates' );
    is( $missing_index_err, '',   'a missing completion index writes nothing to STDERR' );

    my ( $empty_index_out, $empty_index_err ) = capture {
        $run->( command => 'path', args => [ 'complete-cdr', '' ] );
    };
    is( $empty_index_out, "\n", 'an empty completion index yields no candidates' );
    is( $empty_index_err, '',   'an empty completion index writes nothing to STDERR' );
};

subtest 'path project-root prints nothing outside a project checkout' => sub {
    my ( $stdout, $stderr ) = capture {
        $run->( command => 'path', args => ['project-root'] );
    };
    is( $stdout, '', 'a cwd with no git root above it prints an empty project root' );
    is( $stderr, '', 'the empty project root writes nothing to STDERR' );
};

subtest 'path add reports usage for every incomplete operand form' => sub {
    my $no_operands = eval { $run->( command => 'path', args => ['add'] ); 1 };
    is( $no_operands, undef, 'path add without operands aborts' );
    like( $@, qr/^Usage: dashboard path add <name> <path>$/m, 'the add usage message is printed for no operands' );

    my $lone_name = eval { $run->( command => 'path', args => [ 'add', 'solo' ] ); 1 };
    is( $lone_name, undef, 'a single non-dot operand is not the current-directory shorthand' );
    like( $@, qr/^Usage: dashboard path add <name> <path>$/m, 'the add usage message is printed for a lone alias name' );

    my $empty_name = eval { $run->( command => 'path', args => [ 'add', '', 'target' ] ); 1 };
    is( $empty_name, undef, 'an empty alias name aborts' );
    like( $@, qr/^Usage: dashboard path add <name> <path>$/m, 'the add usage message is printed for an empty alias name' );
};

subtest '_normalize_delete_argument guards its injected dependencies' => sub {
    my $config = Test::CLIPaths::ConfigStub->new( path_aliases => {} );
    my $paths  = Test::CLIPaths::PathsStub->new( expand => sub { return $_[0] } );

    my $no_paths = eval { $normalize_delete->( config => $config, name => 'alpha' ); 1 };
    is( $no_paths, undef, 'a missing path registry aborts alias deletion' );
    like( $@, qr/^Missing paths registry$/m, 'the missing registry is reported' );

    my $no_config = eval { $normalize_delete->( paths => $paths, name => 'alpha' ); 1 };
    is( $no_config, undef, 'a missing config aborts alias deletion' );
    like( $@, qr/^Missing config$/m, 'the missing config is reported' );

    my $no_name = eval { $normalize_delete->( paths => $paths, config => $config ); 1 };
    is( $no_name, undef, 'an undefined alias name aborts alias deletion' );
    like( $@, qr/^Usage: dashboard path del <name>$/m, 'the del usage message is printed for an undefined name' );

    my $empty_name = eval { $normalize_delete->( paths => $paths, config => $config, name => '' ); 1 };
    is( $empty_name, undef, 'an empty alias name aborts alias deletion' );
    like( $@, qr/^Usage: dashboard path del <name>$/m, 'the del usage message is printed for an empty name' );
};

subtest '_normalize_delete_argument falls back to the directory basename' => sub {
    my $identity = Test::CLIPaths::PathsStub->new( expand => sub { return $_[0] } );

    is(
        $normalize_delete->(
            paths  => $identity,
            config => Test::CLIPaths::ConfigStub->new( path_aliases => undef ),
            name   => '.',
        ),
        $preferred,
        'an absent alias mapping falls back to the current directory basename',
    );

    is(
        $normalize_delete->(
            paths  => $identity,
            config => Test::CLIPaths::ConfigStub->new(
                path_aliases => {
                    'aaa-undefined-target' => undef,
                    'bbb-empty-target'     => '',
                },
            ),
            name => '.',
        ),
        $preferred,
        'aliases with undefined or empty targets are skipped during the current-directory scan',
    );
};

subtest '_normalize_delete_argument survives unexpandable alias targets' => sub {
    my $unexpandable = Test::CLIPaths::PathsStub->new( expand => sub { die "unable to expand\n" } );
    my $blanking     = Test::CLIPaths::PathsStub->new( expand => sub { return '' } );
    my $elsewhere    = File::Spec->catdir( $home, 'not-the-current-directory' );

    is(
        $normalize_delete->(
            paths  => $unexpandable,
            config => Test::CLIPaths::ConfigStub->new( path_aliases => { $preferred => $elsewhere } ),
            name   => '.',
        ),
        $preferred,
        'a failing home expansion falls back to the raw alias target and keeps the basename answer',
    );

    is(
        $normalize_delete->(
            paths  => $blanking,
            config => Test::CLIPaths::ConfigStub->new( path_aliases => { $preferred => 'raw-alias-target' } ),
            name   => '.',
        ),
        $preferred,
        'a blank home expansion falls back to the raw alias target and keeps the basename answer',
    );
};

subtest '_build_paths tolerates an empty home environment' => sub {
    local $ENV{HOME} = '';
    delete local $ENV{USERPROFILE};
    delete local $ENV{HOMEDRIVE};
    delete local $ENV{HOMEPATH};

    my $built = eval { $build_paths->() };
    is( $built, undef, 'an empty HOME leaves no resolvable home directory' );
    like( $@, qr/Missing home directory/, 'the unresolvable home directory is reported' );
};

subtest '_cdr_payload guards its arguments and empty term lists' => sub {
    my $paths = Developer::Dashboard::PathRegistry->new( home => $home, cwd => $home );

    my $no_paths = eval { $cdr_payload->( args => [] ); 1 };
    is( $no_paths, undef, 'a missing path registry aborts the cdr payload' );
    like( $@, qr/^Missing paths registry$/m, 'the missing registry is reported' );

    my $bad_args = eval { $cdr_payload->( paths => $paths, args => {} ); 1 };
    is( $bad_args, undef, 'a non-array cdr argument payload aborts' );
    like( $@, qr/^cdr args must be an array reference$/m, 'the cdr argument type error is reported' );

    is_deeply(
        $cdr_payload->( paths => $paths ),
        { target => '', matches => [] },
        'an absent argument list defaults to an empty term list and an empty target',
    );
};

subtest '_cdr_payload treats a blank alias target as no alias' => sub {
    my $alias_cwd = File::Spec->catdir( $home, 'blank-alias-cwd' );
    make_path($alias_cwd);
    my $paths = Developer::Dashboard::PathRegistry->new(
        home        => $home,
        cwd         => $alias_cwd,
        named_paths => { emptyalias => '' },
    );

    is( $paths->resolve_dir('emptyalias'), '', 'the fixture alias really does resolve to a blank target' );
    is_deeply(
        $cdr_payload->( paths => $paths, args => ['emptyalias'] ),
        { target => '', matches => [] },
        'a blank alias target falls through to a current-directory search instead of being used as a root',
    );
};

subtest '_cdr_completion guards its injected arguments' => sub {
    my $paths = Developer::Dashboard::PathRegistry->new( home => $home, cwd => $home );

    my $no_paths = eval { $cdr_completion->( words => [], index => 0 ); 1 };
    is( $no_paths, undef, 'a missing path registry aborts completion' );
    like( $@, qr/^Missing paths registry$/m, 'the missing registry is reported' );

    my $no_words = eval { $cdr_completion->( paths => $paths, index => 0 ); 1 };
    is( $no_words, undef, 'a missing word list aborts completion' );
    like( $@, qr/^Missing completion words$/m, 'the missing word list is reported' );

    my $no_index = eval { $cdr_completion->( paths => $paths, words => [] ); 1 };
    is( $no_index, undef, 'a missing completion index aborts completion' );
    like( $@, qr/^Missing completion index$/m, 'the missing completion index is reported' );

    my $bad_words = eval { $cdr_completion->( paths => $paths, words => 'cdr', index => 0 ); 1 };
    is( $bad_words, undef, 'a non-array word list aborts completion' );
    like( $@, qr/^cdr completion words must be an array reference$/m, 'the word list type error is reported' );

    is_deeply( [ $cdr_completion->( paths => $paths, words => [], index => 0 ) ],
        [], 'an empty word list yields no candidates' );
};

subtest '_cdr_completion handles out-of-range indexes and blank alias roots' => sub {
    my $alias_cwd = File::Spec->catdir( $home, 'completion-cwd' );
    make_path($alias_cwd);
    my $paths = Developer::Dashboard::PathRegistry->new(
        home        => $home,
        cwd         => $alias_cwd,
        named_paths => { emptyalias => '' },
    );

    is_deeply(
        [ $cdr_completion->( paths => $paths, words => ['cdr'], index => 5 ) ],
        [],
        'an index past the end of the word list yields no candidates and no unresolvable alias root',
    );

    is_deeply(
        [ $cdr_completion->( paths => $paths, words => [ 'cdr', 'emptyalias', 'x' ], index => 2 ) ],
        [],
        'a blank alias target is narrowed under the current directory rather than used as a completion root',
    );
};

subtest '_cdr_initial_candidates guards its arguments and empty registries' => sub {
    my $stub = Test::CLIPaths::PathsStub->new( named_paths => undef, dirs => [] );

    my $no_paths = eval { $initial->( include => [] ); 1 };
    is( $no_paths, undef, 'a missing path registry aborts initial completion' );
    like( $@, qr/^Missing paths registry$/m, 'the missing registry is reported' );

    my $bad_roots = eval { $initial->( paths => $stub, prefix => '', include => 'nope' ); 1 };
    is( $bad_roots, undef, 'a non-array include list aborts initial completion' );
    like( $@, qr/^cdr completion include roots must be an array reference$/m, 'the include list type error is reported' );

    is_deeply( [ $initial->( paths => $stub, include => [] ) ],
        [], 'an empty alias registry and an absent prefix yield no candidates' );

    is_deeply(
        [ $initial->( paths => Test::CLIPaths::PathsStub->new( named_paths => { alpha => '/alpha' } ), prefix => '' ) ],
        ['alpha'],
        'an absent include list defaults to no extra directory roots',
    );
};

subtest '_cdr_initial_candidates filters unusable roots and blank aliases' => sub {
    my $root = File::Spec->catdir( $home, 'initial-root' );
    make_path($root);
    my $stub = Test::CLIPaths::PathsStub->new(
        named_paths => { '' => '/blank-alias-name', 'alpha' => '/alpha' },
        dirs        => [ File::Spec->catdir( $root, 'beta' ) ],
    );

    is_deeply(
        [ $initial->( paths => $stub, prefix => '', include => [ undef, '', $root ] ) ],
        [ 'alpha', 'beta' ],
        'undefined and blank include roots are skipped and blank alias names never become candidates',
    );
};

subtest '_cdr_directory_candidates guards its arguments' => sub {
    my $stub = Test::CLIPaths::PathsStub->new( dirs => [] );

    my $no_paths = eval { $dir_candidates->( root => '/somewhere' ); 1 };
    is( $no_paths, undef, 'a missing path registry aborts directory completion' );
    like( $@, qr/^Missing paths registry$/m, 'the missing registry is reported' );

    is_deeply( [ $dir_candidates->( paths => $stub ) ], [], 'an absent search root yields no candidates' );

    my $bad_terms = eval { $dir_candidates->( paths => $stub, root => '/somewhere', terms => 'nope' ); 1 };
    is( $bad_terms, undef, 'a non-array term list aborts directory completion' );
    like( $@, qr/^cdr completion terms must be an array reference$/m, 'the term list type error is reported' );
};

subtest '_cdr_directory_candidates skips unusable and duplicate matches' => sub {
    my $root = '/directory-candidates-root';
    my $stub = Test::CLIPaths::PathsStub->new(
        dirs => [
            undef,
            '',
            $root,
            "$root/alpha",
            "$root/nested/alpha",
            "$root/beta",
        ],
    );

    is_deeply(
        [ $dir_candidates->( paths => $stub, root => $root ) ],
        [ 'alpha', 'beta' ],
        'undefined, blank, root-equal, and duplicate-basename matches are all dropped without a prefix filter',
    );
};

subtest 'summary tables tolerate absent payloads' => sub {
    like( $paths_table->(undef),          qr/^Path\s+Value$/m,          'the paths table renders headers for an absent inventory' );
    like( $aliases_table->(undef),        qr/^Alias\s+Path$/m,          'the aliases table renders headers for an absent registry' );
    like( $list_table->( 'Path', undef ), qr/^Path$/m,                  'the list table renders headers for an absent item list' );
    like( $mutation_table->( alias => 'solo' ), qr/^solo\s*$/m,         'the mutation table blanks every absent column' );
    like( $removal_table->( removed => 0 ),     qr/^\s*no\s+no-change/m, 'the removal table reports a no-change removal with a blank alias' );
};

subtest '_render_table tolerates absent headers, rows, and cells' => sub {
    is( $render_table->( undef, undef ), "\n\n", 'an absent header and row set render as an empty table' );
    is( $render_table->( ['Head'], undef ), "Head\n----\n", 'an absent row set renders header and rule only' );
    is( $render_table->( [undef], [] ), "\n\n", 'an undefined header cell renders as a zero-width column' );
};

is_deeply( \@warnings, [], 'no warnings escaped the CLI::Paths coverage run' );

done_testing;

__END__

=pod

=head1 NAME

t/90-cli-paths-coverage.t - branch and condition coverage for the path CLI runtime

=head1 PURPOSE

This test drives every remaining decision point in
C<Developer::Dashboard::CLI::Paths> that the behavioural suites never reach: the
dispatch argument guards, the usage errors for each C<dashboard path> verb, the
current-directory delete shorthand when alias targets are missing, blank, or
unexpandable, the C<cdr> payload and completion helpers when an alias resolves
to a blank target or the completion index runs past the supplied words, and the
table renderers when headers, rows, or cells are absent.

=head1 WHY IT EXISTS

The repository gate requires C<lib/> to sit at 100.0 on all four Devel::Cover
metrics, statement, subroutine, branch, and condition. The path CLI is almost
entirely defensive at its edges: it validates injected registries, config
objects, argument references, and completion indexes that the normal shell
helpers never send it malformed. Those guards are the ones that keep C<cdr>,
C<dd_cdr>, and C<which_dir> from emitting raw Perl errors into an interactive
shell, so they need executable coverage rather than an annotation.

=head1 WHEN TO USE

Use this file when changing the argument validation, usage messages, alias
loading, current-directory shorthand, C<cdr> target selection, shell-completion
candidates, or table rendering inside the path CLI runtime.

=head1 HOW TO USE

Run C<prove -lv t/90-cli-paths-coverage.t> while iterating, and keep it green
under C<prove -lr t> before release. The file is hermetic: it roots a temporary
home, chdirs into it so the layered runtime resolves from that directory, and
injects small stand-in registry and config objects for the payloads a real
C<Developer::Dashboard::PathRegistry> or C<Developer::Dashboard::Config> cannot
produce, such as an absent alias inventory, an alias target that fails home
expansion, or a directory search that returns undefined entries. To confirm the
coverage contribution, run the suite under
C<HARNESS_PERL_SWITCHES=-MDevel::Cover> and check the branch and condition
columns for the path CLI module.

=head1 WHAT USES IT

The repository test suite, the Devel::Cover gate, and developers changing the
path CLI runtime use this file to keep the defensive edges of C<dashboard path>
and C<dashboard paths> behaving as documented.

=head1 EXAMPLES

Example 1:

  prove -lv t/90-cli-paths-coverage.t

Run the path CLI coverage checks on their own while iterating.

Example 2:

  prove -lr t

Run them inside the full repository suite before release.

Example 3:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t

Run them under the coverage gate to confirm the path CLI branch and condition
columns stay at 100.

=cut
