package Getopt::Yath::Tutorial;
use strict;
use warnings;

our $VERSION = '2.000011';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Getopt::Yath::Tutorial - A step-by-step guide to using Getopt::Yath

=head1 DESCRIPTION

This tutorial walks you through using L<Getopt::Yath> to handle command-line
options in your Perl scripts and modules. It starts with simple examples and
builds up to advanced features.

=head1 YOUR FIRST SCRIPT

Here is the simplest useful script with Getopt::Yath:

    #!/usr/bin/perl
    use strict;
    use warnings;
    use Getopt::Yath;

    option_group {group => 'my', category => 'My Options'} => sub {

        option name => (
            type        => 'Scalar',
            description => 'Your name',
        );

    };

    my $state = parse_options(\@ARGV);
    my $settings = $state->settings;

    print "Hello, " . ($settings->my->name // 'World') . "!\n";

Run it:

    $ perl hello.pl --name Bob
    Hello, Bob!

    $ perl hello.pl
    Hello, World!

=head2 What just happened?

C<use Getopt::Yath> exports several functions into your package:

=over 4

=item L<option|Getopt::Yath/option TITLE>

Define a single command-line option with a name and specification.

=item L<option_group|Getopt::Yath/option_group>

Set shared attributes (group, category, prefix, etc.) for a block of options.

=item L<parse_options|Getopt::Yath/parse_options>

Process an arrayref of command-line arguments and return a state hashref with
settings, remaining args, skipped items, and more.

=item L<include_options|Getopt::Yath/include_options>

Import option definitions from another module that also uses Getopt::Yath.

=item L<option_post_process|Getopt::Yath/option_post_process>

Register a callback to run after all options have been parsed, for
cross-option validation or fixups.

=item L<options|Getopt::Yath/options>

Return the L<Getopt::Yath::Instance> object that holds all defined options.
Used for generating help and documentation output.

=item L<category_sort_map|Getopt::Yath/category_sort_map>

Control the display order of option categories in help output.

=back

Every option needs a B<group> (the key under which it appears in settings) and
a B<type> (how it parses arguments). The B<category> is a human-readable label
used for help output.

=head1 OPTION GROUPS

C<option_group> lets you set shared attributes for a block of options so you
don't have to repeat yourself:

    option_group {group => 'server', category => 'Server Options'} => sub {

        option host => (
            type        => 'Scalar',
            default     => 'localhost',
            description => 'Hostname to bind to',
        );

        option port => (
            type        => 'Scalar',
            short       => 'p',
            default     => 8080,
            description => 'Port to listen on',
        );

        option verbose => (
            type        => 'Bool',
            short       => 'v',
            description => 'Enable verbose output',
        );

    };

    my $state = parse_options(\@ARGV);
    my $settings = $state->settings;

    printf "Starting server on %s:%s\n",
        $settings->server->host,
        $settings->server->port;

Every option declared inside this block inherits C<< group => 'server' >> and
C<< category => 'Server Options' >>. The parsed values are accessed via
C<< $settings->server->host >>, C<< $settings->server->port >>, etc.

=head1 OPTION TYPES

Getopt::Yath provides a rich set of option types. Here they are from simplest
to most specialized.

=head2 Bool

A simple on/off flag. No argument needed.

    option verbose => (
        type        => 'Bool',
        short       => 'v',
        default     => 0,
        description => 'Enable verbose output',
    );

Usage:

    --verbose       # turns it on (1)
    -v              # same thing
    --no-verbose    # turns it off (0)

=head2 Scalar

Takes exactly one value.

    option output => (
        type        => 'Scalar',
        short       => 'o',
        description => 'Output file path',
    );

Usage:

    --output results.txt
    --output=results.txt
    -o results.txt
    -o=results.txt
    -oresults.txt       # short form allows value directly after flag
    --no-output         # clears the value (sets to undef)

=head2 Count

An incrementing counter. Each use bumps the value by one.

    option verbosity => (
        type        => 'Count',
        short       => 'v',
        initialize  => 0,
        description => 'Increase verbosity level',
    );

Usage:

    -v          # 1
    -vvv        # 3 (short flags can be stacked)
    --verbosity # 1
    -v -v -v    # 3
    -v=5        # explicitly set to 5
    --no-verbosity  # reset to 0

=head2 List

Collects multiple values into an arrayref. Can be specified multiple times.

    option include => (
        type        => 'List',
        short       => 'I',
        description => 'Add a directory to the include path',
    );

Usage:

    -I lib -I blib/lib
    --include lib --include blib/lib
    --no-include    # empties the list

Lists also accept JSON arrays:

    --include '["lib","blib/lib"]'

=head3 Splitting values

Use C<split_on> to allow comma-separated (or other delimiter) values:

    option tags => (
        type        => 'List',
        split_on    => ',',
        description => 'Comma-separated list of tags',
    );

    # --tags foo,bar,baz   =>   ['foo', 'bar', 'baz']

=head2 Map

Collects key=value pairs into a hashref. Can be specified multiple times.

    option env_var => (
        type        => 'Map',
        short       => 'E',
        alt         => ['env-var'],
        description => 'Set an environment variable',
    );

Usage:

    -E HOME=/tmp -E USER=test
    --env-var HOME=/tmp
    --env-var '{"HOME":"/tmp","USER":"test"}'   # JSON also works
    --no-env-var    # empties the hash

Like List, Map supports C<split_on> for multiple pairs in one argument, and
C<key_on> to change the key/value delimiter (default is C<=>).

=head2 Auto

A scalar option with an autofill value. C<--opt> uses the autofill value,
C<--opt=val> uses the provided value. B<Does not> support C<--opt val> (the
space-separated form), because without a required argument the next token is
ambiguous.

    option coverage => (
        type        => 'Auto',
        autofill    => '-silent,1',
        description => 'Enable coverage; optionally provide Devel::Cover args',
        long_examples  => ['', '=-silent,1'],
    );

Usage:

    --coverage          # uses autofill: "-silent,1"
    --coverage=-db,cov  # uses the provided value
    --no-coverage       # clears

=head2 AutoList

Combines Auto and List. C<--opt> adds the autofill values to the list.
C<--opt=val> adds a specific value.

    option plugins => (
        type        => 'AutoList',
        autofill    => sub { qw/Foo Bar/ },
        description => 'Plugins to load (defaults to Foo and Bar)',
    );

Usage:

    --plugins           # adds 'Foo' and 'Bar'
    --plugins=Baz       # adds 'Baz'
    --no-plugins        # empties the list

=head2 AutoMap

Combines Auto and Map. C<--opt> adds the autofill key/value pairs.
C<--opt=key=val> adds a specific pair.

    option defaults => (
        type        => 'AutoMap',
        autofill    => sub { timeout => 30, retries => 3 },
        description => 'Default settings',
    );

Usage:

    --defaults              # adds {timeout => 30, retries => 3}
    --defaults=color=red    # adds {color => 'red'}
    --no-defaults           # empties the hash

=head2 PathList

Like List, but values containing wildcards are expanded using glob().

    option test_files => (
        type        => 'PathList',
        split_on    => ',',
        description => 'Test files to run (globs allowed)',
    );

Usage:

    --test-files 't/*.t'
    --test-files t/foo.t,t/bar.t
    --test-files 'lib/**/*.pm'

=head2 AutoPathList

Combines AutoList and PathList. C<--opt> adds autofill paths, C<--opt=glob>
expands the glob.

    option dev_libs => (
        type        => 'AutoPathList',
        short       => 'D',
        name        => 'dev-lib',
        autofill    => sub { 'lib', 'blib/lib', 'blib/arch' },
        description => 'Add dev library paths (default: lib, blib/lib, blib/arch)',
    );

Usage:

    -D              # adds lib, blib/lib, blib/arch
    -D=lib          # adds just lib
    -D='lib/*'      # adds all matches

=head2 BoolMap

Matches a pattern of options dynamically, building a hash of boolean values.
Requires a C<pattern> attribute with a capture group.

    option features => (
        type        => 'BoolMap',
        pattern     => qr/feature-(.+)/,
        description => 'Toggle features on or off',
    );

Usage:

    --feature-color         # {color => 1}
    --feature-unicode       # {unicode => 1}
    --no-feature-color      # {color => 0}

The pattern is embedded into C<< qr/^--(no-)?$pattern$/ >> automatically. Each
captured key gets a true or false value depending on the C<--no-> prefix.

=head1 COMMON OPTION ATTRIBUTES

These attributes work across all option types.

=head2 short

A single-character alias for the option:

    option jobs => (
        type  => 'Scalar',
        short => 'j',
        ...
    );

    # -j4   --jobs 4   --jobs=4   -j 4

=head2 alt and alt_no

Alternate long names for the option:

    option use_stream => (
        type   => 'Bool',
        alt    => ['stream'],       # --stream also works
        alt_no => ['TAP'],          # --TAP is equivalent to --no-use-stream
        description => 'Use streaming format instead of TAP',
    );

=head2 prefix

Adds a prefix to the option name. Especially useful in option groups:

    option_group {group => 'db', category => 'Database', prefix => 'db'} => sub {

        option host => (
            type => 'Scalar',
            description => 'Database host',
        );

        option port => (
            type    => 'Scalar',
            default => 5432,
            description => 'Database port',
        );

    };

    # --db-host myhost --db-port 3306

The values are still accessed as C<< $settings->db->host >> and
C<< $settings->db->port >> -- the prefix only affects the command-line form.

=head2 field and name

By default, the option title determines both the field name (underscores) and
the CLI name (dashes). You can override either:

    option test_args => (
        type  => 'List',
        field => 'args',        # $settings->tests->args (not test_args)
        alt   => ['test-arg'],
        ...
    );

=head2 default

A value used when the option is not provided on the command line and not set
via an environment variable:

    option timeout => (
        type    => 'Scalar',
        default => 60,
        description => 'Timeout in seconds',
    );

    # Can also be a coderef:
    option search => (
        type    => 'PathList',
        default => sub { './t', './t2' },
        ...
    );

=head2 initialize

Set an initial value before parsing begins. This differs from C<default> in
that C<default> is applied after parsing if the option was never set, while
C<initialize> sets a starting value that can then be modified by command-line
arguments.

    option verbosity => (
        type       => 'Count',
        initialize => 0,
        ...
    );

=head1 ENVIRONMENT VARIABLES

=head2 from_env_vars

Read an option's initial value from environment variables. The first one that
is defined wins:

    option verbose => (
        type          => 'Bool',
        from_env_vars => ['MYAPP_VERBOSE', 'VERBOSE'],
        description   => 'Enable verbose output',
    );

Prefix a variable with C<!> to negate its value:

    option quiet => (
        type          => 'Bool',
        from_env_vars => ['!VERBOSE'],     # quiet = true when VERBOSE is false
        description   => 'Suppress output',
    );

=head2 set_env_vars

Set environment variables after parsing is complete (Bool, Scalar, Count, and
Auto types only):

    option cover => (
        type          => 'Auto',
        autofill      => '-silent,1',
        from_env_vars => ['T2_DEVEL_COVER'],
        set_env_vars  => ['T2_DEVEL_COVER'],
        description   => 'Enable Devel::Cover',
    );

The C<!> prefix also works here for inverted env vars.

=head2 clear_env_vars

Clear specified environment variables after parsing:

    option token => (
        type           => 'Scalar',
        from_env_vars  => ['AUTH_TOKEN'],
        clear_env_vars => ['AUTH_TOKEN'],    # don't leak to child processes
        description    => 'Auth token (cleared from env after reading)',
    );

=head1 NORMALIZE AND TRIGGER

=head2 normalize

Transform a value as it is parsed:

    option module => (
        type      => 'Scalar',
        normalize => sub {
            my ($val) = @_;
            $val =~ s/-/::/g;      # Allow Foo-Bar instead of Foo::Bar
            return $val;
        },
        description => 'Module name',
    );

    # --module Foo-Bar  =>  "Foo::Bar"

For List and Map types, normalize is called on each value individually.

=head2 trigger

A callback invoked whenever the option is set or cleared from the command
line. Triggers do B<not> fire for defaults, autofill, or initialization.

    option input_file => (
        type    => 'Scalar',
        trigger => sub {
            my $opt    = shift;
            my %params = @_;

            return unless $params{action} eq 'set';
            my ($file) = @{$params{val}};
            die "File not found: $file\n" unless -f $file;
        },
        description => 'Input file',
    );

The C<%params> hash contains:

    action   => 'set' or 'clear'
    val      => \@values (arrayref, even for scalars)
    ref      => \$field_ref
    state    => $parse_state
    options  => $instance
    settings => $settings
    group    => $group

=head1 ALLOWED VALUES

Restrict what values an option will accept:

    option format => (
        type           => 'Scalar',
        allowed_values => [qw/json csv xml/],
        description    => 'Output format',
    );

    # --format json   # ok
    # --format yaml   # dies: Invalid value

C<allowed_values> can be an arrayref, a regex, or a coderef:

    allowed_values => qr/^\d+$/,            # must be numeric
    allowed_values => sub { $_[1] > 0 },    # must be positive

Use C<allowed_values_text> to customize the help message:

    allowed_values_text => 'json, csv, or xml',

=head1 PARSING OPTIONS

The C<parse_options> function is how you process command-line arguments. It
returns a state hashref with all the parsed data.

=head2 Basic parsing

    my $state = parse_options(\@ARGV);

    my $settings = $state->settings;     # Getopt::Yath::Settings object
    my $remains  = $state->remains;      # args after a stop token
    my $skipped  = $state->skipped;      # skipped non-options
    my $stop     = $state->stop;         # what token stopped parsing
    my $env      = $state->env;          # env vars that were/would be set
    my $cleared  = $state->cleared;      # options cleared via --no-opt
    my $modules  = $state->modules;      # modules whose options were used

=head2 Stops

Use C<stops> to stop parsing at certain tokens. This is most commonly used for
C<-->:

    my $state = parse_options(\@ARGV,
        stops => ['--'],
    );

    # perl script.pl --verbose -- --not-an-option foo bar
    #   $state->stop    = '--'
    #   $state->remains = ['--not-an-option', 'foo', 'bar']

You can define multiple stop tokens. C<::> is commonly used as a separator for
passing arguments through to tests:

    my $state = parse_options(\@ARGV,
        stops => ['--', '::'],
    );

    # perl script.pl --verbose :: --some-test-arg
    #   $state->stop    = '::'
    #   $state->remains = ['--some-test-arg']

=head2 Handling non-options

By default, encountering a non-option (something not starting with C<->)
throws an error. You can change this:

    # Skip non-options (collect them)
    my $state = parse_options(\@ARGV,
        skip_non_opts => 1,
    );
    my @files = @{$state->skipped};

    # Stop at first non-option
    my $state = parse_options(\@ARGV,
        stop_at_non_opts => 1,
    );
    # $state->stop = the non-option that caused the stop
    # $state->remains = everything after it

=head2 Handling invalid options

Similarly, you can control what happens with unrecognized options:

    # Skip invalid options
    my $state = parse_options(\@ARGV,
        skip_invalid_opts => 1,
    );

    # Stop at invalid options
    my $state = parse_options(\@ARGV,
        stop_at_invalid_opts => 1,
    );

=head2 Suppressing env var side effects

Prevent parse_options from modifying C<%ENV>:

    my $state = parse_options(\@ARGV,
        no_set_env => 1,
    );

    # $state->env still shows what would have been set

=head2 Argument groups

Argument groups let you collect arguments between delimiter tokens into an
arrayref. This is useful for passing structured groups of values:

    my $state = parse_options(\@ARGV,
        groups => { ':{' => '}:' },
    );

    # perl script.pl --opt :{ arg1 arg2 arg3 }:
    # The :{ ... }: group is collected as ['arg1', 'arg2', 'arg3']

Groups can be used as option values or as standalone arguments (which end up in
C<skipped> when C<skip_non_opts> is enabled).

=head1 GENERATING HELP OUTPUT

=head2 CLI help

    sub show_help {
        print options()->docs('cli');
    }

This produces formatted terminal output with ANSI colors (when available),
organized by category.

=head2 POD documentation

    sub show_pod {
        print options()->docs('pod', head => 2);
    }

This produces POD markup suitable for embedding in your module's documentation.
The C<head> parameter controls the heading level (e.g., C<=head2>).

=head2 Controlling category order

By default, categories are sorted alphabetically. Use C<category_sort_map> to
control the order:

    category_sort_map(
        'General Options' => 1,
        'Server Options'  => 2,
        'Debug Options'   => 3,
    );

Lower values appear first.

=head1 REUSABLE OPTION LIBRARIES

You can define options in a module and include them elsewhere. This lets you
build composable option sets.

=head2 Defining an option library

    package My::Options::Database;
    use strict;
    use warnings;
    use Getopt::Yath;

    option_group {group => 'db', category => 'Database Options'} => sub {

        option host => (
            type    => 'Scalar',
            default => 'localhost',
            description => 'Database hostname',
        );

        option port => (
            type    => 'Scalar',
            default => 5432,
            description => 'Database port',
        );

        option name => (
            type        => 'Scalar',
            description => 'Database name',
        );

    };

    1;

=head2 Including options from another module

    package My::App;
    use strict;
    use warnings;
    use Getopt::Yath;

    include_options('My::Options::Database');

    option_group {group => 'app', category => 'App Options'} => sub {

        option debug => (
            type        => 'Bool',
            description => 'Debug mode',
        );

    };

    my $state = parse_options(\@ARGV);
    # $state->settings->db->host, ->db->port, etc.
    # $state->settings->app->debug

=head2 Selective inclusion

You can include only specific options from a library:

    include_options(
        'My::Options::Database' => [qw/host port/],
    );

Only the C<host> and C<port> options will be included; C<name> will be
excluded.

=head1 POST-PROCESSING

C<option_post_process> registers a callback that runs after all options have
been parsed but before environment variables are set. This is useful for
validation that depends on multiple options:

    option_post_process sub {
        my ($instance, $state) = @_;

        my $settings = $state->settings;
        my $server   = $settings->server;

        if ($server->ssl && !$server->cert_file) {
            die "--ssl requires --cert-file\n";
        }
    };

=head2 Weighted post-processors

The first argument is a weight that controls execution order (lower runs
first, default is 0):

    option_post_process 10 => sub {
        my ($instance, $state) = @_;
        # Runs after weight-0 post-processors
    };

=head2 Conditional post-processors

An optional C<applicable> coderef controls whether the post-processor runs:

    option_post_process 0 => sub { ... if server group exists ... } => sub {
        my ($instance, $state) = @_;
        ...
    };

If used inside an C<option_group> block, the group's C<applicable> is
inherited automatically.

=head1 DYNAMIC OPTIONS WITH mod_adds_options

Some options specify a module name whose options should be dynamically loaded
when the option is used:

    option runner_class => (
        type             => 'Scalar',
        name             => 'runner',
        field            => 'class',
        default          => 'My::Runner',
        mod_adds_options => 1,
        normalize        => sub { fqmod($_[0], 'My::Runner') },
        description      => 'Runner class to use',
    );

When C<--runner=My::Custom::Runner> is specified, the module is loaded, and
if it has an C<options()> method, those options are included into the current
instance. This allows plugins and extensions to contribute their own
command-line options.

=head1 APPLICABILITY

Options can be conditionally shown/hidden based on runtime state:

    option reloader => (
        type       => 'Auto',
        autofill   => 'My::Reloader',
        applicable => sub {
            my ($opt, $options, $settings) = @_;
            return $settings->runner->preloads && @{$settings->runner->preloads};
        },
        description => 'Module reloader (only available with preloads)',
    );

When C<applicable> returns false, the option is excluded from parsing and
documentation.

=head1 THE SETTINGS OBJECT

The C<< $state->settings >> value is a L<Getopt::Yath::Settings> object.
Groups are accessed as methods:

    $settings->server->host;
    $settings->db->port;

Useful methods:

    # Check if a group exists
    if ($settings->check_group('server')) { ... }

    # Safe access with a default
    my $val = $settings->maybe('server', 'host', 'localhost');

=head1 COMPLETE EXAMPLE

Here is a complete script demonstrating many features together:

    #!/usr/bin/perl
    use strict;
    use warnings;
    use Getopt::Yath;

    option_group {group => 'app', category => 'Application Options'} => sub {

        option verbose => (
            type          => 'Count',
            short         => 'v',
            initialize    => 0,
            from_env_vars => ['MYAPP_VERBOSE'],
            set_env_vars  => ['MYAPP_VERBOSE'],
            description   => 'Increase verbosity (-v, -vv, -vvv)',
        );

        option config => (
            type        => 'Scalar',
            short       => 'c',
            description => 'Path to config file',
            trigger     => sub {
                my $opt    = shift;
                my %params = @_;
                return unless $params{action} eq 'set';
                my ($file) = @{$params{val}};
                die "Config file not found: $file\n" unless -f $file;
            },
        );

        option output_format => (
            type           => 'Scalar',
            short          => 'f',
            default        => 'json',
            allowed_values => [qw/json csv xml/],
            description    => 'Output format',
        );

        option tags => (
            type        => 'List',
            short       => 't',
            split_on    => ',',
            description => 'Tags to apply (comma-separated)',
        );

        option env_vars => (
            type        => 'Map',
            short       => 'E',
            description => 'Extra environment variables (KEY=VAL)',
        );

        option dry_run => (
            type        => 'Bool',
            short       => 'n',
            default     => 0,
            description => 'Dry run, do not make changes',
        );

    };

    option_group {group => 'files', category => 'File Options'} => sub {

        option include => (
            type        => 'PathList',
            short       => 'I',
            description => 'Files to include (globs allowed)',
        );

    };

    category_sort_map(
        'Application Options' => 1,
        'File Options'        => 2,
    );

    option_post_process sub {
        my ($instance, $state) = @_;
        my $settings = $state->settings;

        if ($settings->app->dry_run && $settings->app->verbose < 1) {
            warn "Note: --dry-run without --verbose; enabling verbose=1\n";
            $settings->app->option(verbose => 1);
        }
    };

    # Show help if requested
    if (grep { $_ eq '--help' || $_ eq '-h' } @ARGV) {
        print options()->docs('cli');
        exit 0;
    }

    my $state = parse_options(\@ARGV,
        stops         => ['--', '::'],
        skip_non_opts => 1,
    );

    my $settings = $state->settings;

    printf "Verbosity: %d\n", $settings->app->verbose;
    printf "Format: %s\n",    $settings->app->output_format;
    printf "Dry run: %s\n",   $settings->app->dry_run ? 'yes' : 'no';

    if (my $tags = $settings->app->tags) {
        printf "Tags: %s\n", join(', ', @$tags) if @$tags;
    }

    if (my @files = @{$state->skipped}) {
        printf "Files: %s\n", join(', ', @files);
    }

    if ($state->stop) {
        printf "Stopped at: %s\n", $state->stop;
        printf "Remaining: %s\n", join(' ', @{$state->remains});
    }

=head1 ADVANCED: MULTI-STAGE PARSING WITH SUBCOMMANDS

Many tools follow a C<script [GLOBAL OPTIONS] subcommand [COMMAND OPTIONS]>
pattern, where the script has its own set of options, a subcommand name, and
then the subcommand has its own options. Getopt::Yath supports this through
multi-stage parsing: parse the global options first (stopping at the
subcommand), then load the subcommand and parse its options from the remaining
arguments.

=head2 Step 1: Define global options

Create a package for your script-level options.

    package My::CLI;
    use strict;
    use warnings;
    use Getopt::Yath;

    option_group {group => 'global', category => 'Global Options'} => sub {

        option verbose => (
            type        => 'Count',
            short       => 'v',
            initialize  => 0,
            description => 'Increase verbosity',
        );

        option config => (
            type        => 'Scalar',
            short       => 'c',
            description => 'Path to config file',
        );

    };

=head2 Step 2: Define subcommand option packages

Each subcommand is a separate package with its own options:

    package My::CLI::Command::deploy;
    use strict;
    use warnings;
    use Getopt::Yath;

    option_group {group => 'deploy', category => 'Deploy Options'} => sub {

        option target => (
            type        => 'Scalar',
            short       => 't',
            description => 'Deployment target (staging, production)',
        );

        option dry_run => (
            type        => 'Bool',
            short       => 'n',
            default     => 0,
            description => 'Perform a dry run',
        );

    };

    sub run {
        my ($class, $settings) = @_;
        printf "Deploying to %s (dry_run=%s, verbose=%d)\n",
            $settings->deploy->target // 'default',
            $settings->deploy->dry_run ? 'yes' : 'no',
            $settings->global->verbose;
    }

    package My::CLI::Command::test;
    use strict;
    use warnings;
    use Getopt::Yath;

    option_group {group => 'test', category => 'Test Options'} => sub {

        option jobs => (
            type        => 'Scalar',
            short       => 'j',
            default     => 1,
            description => 'Number of parallel test jobs',
        );

        option tags => (
            type        => 'List',
            split_on    => ',',
            description => 'Filter tests by tag',
        );

    };

    sub run {
        my ($class, $settings) = @_;
        printf "Running tests with %d jobs (verbose=%d)\n",
            $settings->test->jobs,
            $settings->global->verbose;
    }

=head2 Step 3: Two-stage dispatch

Parse global options first, stopping at the subcommand name. Then load the
subcommand module, include its options, and parse the remaining arguments using
the combined option set. Pass the settings object through so both stages share
state.

    package main;

    my %commands = (
        deploy => 'My::CLI::Command::deploy',
        test   => 'My::CLI::Command::test',
    );

    # Stage 1: Parse global options, stop at the subcommand name
    my $stage1 = My::CLI::parse_options(
        \@ARGV,
        stop_at_non_opts => 1,
    );

    my $command_name = $stage1->stop
        or die "Usage: my-cli [global options] <command> [command options]\n";

    my $command_class = $commands{$command_name}
        or die "Unknown command: $command_name\n";

    # Stage 2: Include command options, parse remaining args
    #          Carry forward settings so global values are preserved
    My::CLI::include_options($command_class);

    my $stage2 = My::CLI::parse_options(
        $stage1->remains,
        settings => $stage1->settings,
    );

    # Dispatch — settings object has both global and command groups
    $command_class->run($stage2->settings);

=head2 Example invocations

    $ my-cli -vv deploy --target production --dry-run
    Deploying to production (dry_run=yes, verbose=2)

    $ my-cli --config app.yml test -j8 --tags smoke,unit
    Running tests with 8 jobs (verbose=0)

The key techniques are:

=over 4

=item *

B<stop_at_non_opts> in Stage 1 stops parsing at the subcommand name, placing
it in C<< $state->stop >> and the rest in C<< $state->remains >>.

=item *

B<include_options> merges the subcommand's options into the script's option
instance before Stage 2.

=item *

B<settings> is passed from Stage 1 to Stage 2 so the global values are
preserved and both stages write into the same settings object.

=back

=head1 SEE ALSO

=over 4

=item L<Getopt::Yath> - Main module documentation and API reference

=item L<Getopt::Yath::State> - The parse result object returned by parse_options

=item L<Getopt::Yath::Option> - Base option class and all available attributes

=item L<Getopt::Yath::Settings> - The parsed settings object

=item L<Getopt::Yath::Instance> - Internal option instance (advanced usage)

=back

=head1 SOURCE

The source code repository for Getopt-Yath can be found at
L<http://github.com/Test-More/Getopt-Yath/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/>

=cut
