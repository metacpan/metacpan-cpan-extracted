#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use Capture::Tiny qw(capture);
use Cwd qw(abs_path);
use File::Temp qw(tempdir);

use lib 'lib';

use Developer::Dashboard::CLI::RuntimeControl ();

# Warnings are fatal in this repository: collect any that escape and assert
# the whole run stayed clean.
my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0]; return; };

# Hermetic runtime rooted at a temp home, matching the project's own coverage
# test convention (t/90-cli-paths-coverage.t).
my $home = abs_path( tempdir( CLEANUP => 1 ) );
local $ENV{HOME} = $home;
local $ENV{DEVELOPER_DASHBOARD_PROGRESS};
delete $ENV{DEVELOPER_DASHBOARD_PROGRESS};
chdir $home or die "Unable to chdir to $home: $!";

my $run                 = \&Developer::Dashboard::CLI::RuntimeControl::run_runtime_command;
my $run_lifecycle       = \&Developer::Dashboard::CLI::RuntimeControl::_run_lifecycle_command;
my $run_log             = \&Developer::Dashboard::CLI::RuntimeControl::_run_log_command;
my $collector_logs_text = \&Developer::Dashboard::CLI::RuntimeControl::_collector_logs_text;
my $known_names         = \&Developer::Dashboard::CLI::RuntimeControl::_known_collector_names;
my $collector_known     = \&Developer::Dashboard::CLI::RuntimeControl::_collector_known;
my $lifecycle_progress  = \&Developer::Dashboard::CLI::RuntimeControl::_lifecycle_progress;
my $summary_table       = \&Developer::Dashboard::CLI::RuntimeControl::_lifecycle_summary_table;
my $render_table        = \&Developer::Dashboard::CLI::RuntimeControl::_render_table;
my $pad_row             = \&Developer::Dashboard::CLI::RuntimeControl::_pad_row;
my $tail_log_text       = \&Developer::Dashboard::CLI::RuntimeControl::_tail_log_text;
my $read_log_sources    = \&Developer::Dashboard::CLI::RuntimeControl::_read_log_sources;
my $render_log_sources  = \&Developer::Dashboard::CLI::RuntimeControl::_render_log_sources;
my $follow_log_sources  = \&Developer::Dashboard::CLI::RuntimeControl::_follow_log_sources;
my $timestamp_log_text  = \&Developer::Dashboard::CLI::RuntimeControl::_timestamp_log_text;
my $lifecycle_usage     = \&Developer::Dashboard::CLI::RuntimeControl::_lifecycle_usage;
my $log_usage           = \&Developer::Dashboard::CLI::RuntimeControl::_log_usage;

{
    package Test::RC::Runtime;

    # new(%args)
    # Injectable stand-in for RuntimeManager, recording every call it receives
    # so tests can assert on what was actually asked for without a real
    # process-managing runtime.
    sub new {
        my ( $class, %args ) = @_;
        return bless {
            web_log_result => $args{web_log_result},
            calls          => [],
        }, $class;
    }

    sub restart_progress_tasks { my $self = shift; push @{ $self->{calls} }, [ 'restart_progress_tasks', @_ ]; return []; }
    sub stop_progress_tasks    { my $self = shift; push @{ $self->{calls} }, [ 'stop_progress_tasks',    @_ ]; return []; }

    sub restart_target {
        my $self = shift;
        push @{ $self->{calls} }, [ 'restart_target', @_ ];
        return { web => { status => 'restarted', pid => 111, details => 'ok' } };
    }

    sub stop_target {
        my $self = shift;
        push @{ $self->{calls} }, [ 'stop_target', @_ ];
        return { collectors => [ { name => 'alpha', status => 'stopped', pid => 222, details => 'ok' } ] };
    }

    sub web_log {
        my $self = shift;
        push @{ $self->{calls} }, [ 'web_log', @_ ];
        return ref( $self->{web_log_result} ) eq 'CODE' ? $self->{web_log_result}->() : $self->{web_log_result};
    }
}

{
    package Test::RC::Config;

    sub new {
        my ( $class, %args ) = @_;
        return bless {
            web_settings => $args{web_settings} || { host => 'h', port => 1, workers => 1, ssl => 0 },
            collectors   => $args{collectors}   || [],
        }, $class;
    }

    sub web_settings { my $self = shift; return $self->{web_settings}; }
    sub collectors   { my $self = shift; return $self->{collectors}; }
}

{
    package Test::RC::Collectors;

    sub new {
        my ( $class, %args ) = @_;
        return bless {
            logs       => $args{logs}       || {},
            existing   => $args{existing}   || {},
            persisted  => $args{persisted}  || [],
        }, $class;
    }

    sub read_log          { my ( $self, $name ) = @_; my $text = $self->{logs}{$name}; return ref($text) eq 'CODE' ? $text->() : $text; }
    sub collector_exists  { my ( $self, $name ) = @_; return $self->{existing}{$name} ? 1 : 0; }
    sub list_collectors   { my $self = shift; return @{ $self->{persisted} }; }
}

sub base_args {
    my (%override) = @_;
    return (
        runtime    => $override{runtime}    || Test::RC::Runtime->new,
        config     => $override{config}     || Test::RC::Config->new,
        collectors => $override{collectors} || Test::RC::Collectors->new,
    );
}

# ---------------------------------------------------------- run_runtime_command

{
    eval { $run->( args => [], runtime => 1, config => 1, collectors => 1 ) };
    like( $@, qr/Missing runtime control command/, 'missing command dies' );

    eval { $run->( command => 'log', runtime => 1, config => 1, collectors => 1 ) };
    like( $@, qr/Missing runtime control argv/, 'missing argv dies' );

    eval { $run->( command => 'log', args => [], config => 1, collectors => 1 ) };
    like( $@, qr/Missing runtime manager/, 'missing runtime dies' );

    eval { $run->( command => 'log', args => [], runtime => 1, collectors => 1 ) };
    like( $@, qr/Missing runtime config/, 'missing config dies' );

    eval { $run->( command => 'log', args => [], runtime => 1, config => 1 ) };
    like( $@, qr/Missing collector store/, 'missing collectors dies' );

    eval { $run->( command => 'log', args => 'nope', runtime => 1, config => 1, collectors => 1 ) };
    like( $@, qr/argv must be an array reference/, 'non-arrayref argv dies' );

    eval { $run->( command => 'nonsense', args => [], base_args() ) };
    like( $@, qr/Unsupported runtime control command 'nonsense'/, 'unknown command dies' );
}

{
    my %a = base_args();
    my ( $out, $err, $rc ) = capture { $run->( command => 'restart', args => [ 'web', '-o', 'json' ], %a ); };
    is( $rc, 0, 'restart dispatches and returns 0' );
    like( $out, qr/"web"/, 'restart json output present' );
}

{
    my %a = base_args();
    my ( $out, $err, $rc ) = capture { $run->( command => 'log', args => [], %a ); };
    is( $rc, 0, 'log dispatches and returns 0' );
}

# ---------------------------------------------------------- _run_lifecycle_command

{
    my %a = base_args();
    my ( $out, $err, $rc ) = capture {
        $run_lifecycle->( command => 'restart', args => [], %a );
    };
    is( $rc, 0, 'lifecycle default scope all, table output, restart' );
    like( $out, qr/web.*dashboard.*restarted/s, 'table renders the restart result' );
}

{
    my %a = base_args( collectors => Test::RC::Collectors->new( existing => { alpha => 1 } ) );
    my ( $out, $err, $rc ) = capture {
        $run_lifecycle->( command => 'stop', args => [ 'collector', 'alpha' ], %a );
    };
    is( $rc, 0, 'lifecycle scoped stop of a named collector' );
    like( $out, qr/collector.*alpha.*stopped/s, 'table renders the stop result' );
}

{
    my %a = base_args( collectors => Test::RC::Collectors->new( existing => { beta => 1 } ) );
    my ( $out, $err, $rc ) = capture {
        $run_lifecycle->( command => 'restart', args => [ 'collector', 'beta', '-o', 'json' ], %a );
    };
    is( $rc, 0, 'known collector target with json output' );
}

{
    my %a = base_args();
    eval {
        capture { $run_lifecycle->( command => 'restart', args => [ '-o', 'xml' ], %a ); };
    };
    like( $@, qr/^Usage: dashboard restart/, 'bad output value dies with usage' );
}

{
    my %a = base_args();
    eval {
        capture { $run_lifecycle->( command => 'restart', args => [ 'extra', 'stuff' ], %a ); };
    };
    like( $@, qr/^Usage: dashboard restart/, 'leftover argv dies with usage' );
}

{
    my %a = base_args();
    eval {
        capture { $run_lifecycle->( command => 'stop', args => [ 'collector', '' ], %a ); };
    };
    like( $@, qr/Collector name is required after 'stop collector'/, 'empty collector target name dies' );
}

{
    my %a = base_args();
    eval {
        capture { $run_lifecycle->( command => 'stop', args => [ 'collector', 'ghost' ], %a ); };
    };
    like( $@, qr/Unknown collector 'ghost'/, 'unknown collector target dies' );
}

{
    eval { $run_lifecycle->( command => 'restart', args => [], runtime => 1, config => Test::RC::Config->new ); };
    like( $@, qr/Missing collector store/, 'lifecycle command itself requires collectors' );
}

# Branch/condition closure: top-level dispatch must exercise BOTH sides of
# each `eq X || eq Y` independently - the earlier tests only hit 'log' and
# 'restart', never 'logs' or 'stop' through run_runtime_command itself.
{
    my %a = base_args();
    my ( $out, $err, $rc ) = capture { $run->( command => 'logs', args => [], %a ); };
    is( $rc, 0, "top-level dispatch accepts 'logs' as well as 'log'" );
}

{
    my %a = base_args( collectors => Test::RC::Collectors->new( existing => { alpha => 1 } ) );
    my ( $out, $err, $rc ) = capture { $run->( command => 'stop', args => [ 'collector', 'alpha' ], %a ); };
    is( $rc, 0, "top-level dispatch accepts 'stop' as well as 'restart'" );
}

# scope detection: argv[0] starting with '-' must NOT be consumed as a scope
# word, so the leading-dash branch of `$argv[0] !~ /^-/` gets its false side.
{
    my %a = base_args();
    my ( $out, $err, $rc ) = capture { $run_lifecycle->( command => 'restart', args => [ '-o', 'json' ], %a ); };
    is( $rc, 0, 'a leading option flag is never mistaken for a scope word' );
}

# scope='collector' but the next token is an option flag, not a target name -
# $target must stay unset rather than swallowing '-o'.
{
    my %a = base_args();
    my ( $out, $err, $rc ) = capture {
        $run_lifecycle->( command => 'restart', args => [ 'collector', '-o', 'json' ], %a );
    };
    is( $rc, 0, 'collector scope with an immediate flag leaves the target unset' );
}

# scope='collector' with no target token at all (not even an empty string) -
# $target stays undef, which must NOT trip the empty-name die.
{
    my %a = base_args();
    my ( $out, $err, $rc ) = capture { $run_lifecycle->( command => 'restart', args => ['collector'], %a ); };
    is( $rc, 0, 'collector scope with no target token at all is not an error' );
}

# Progress board actually built and finished: needs DEVELOPER_DASHBOARD_PROGRESS
# set so $progress is a true value through a real restart AND a real stop, so
# `$progress ? $progress->callback : undef` and `$progress->finish if $progress`
# both take their true branch, and the tasks() fallback list is exercised.
{
    local $ENV{DEVELOPER_DASHBOARD_PROGRESS} = 1;
    my %a = base_args();
    my ( $out, $err, $rc ) = capture { $run_lifecycle->( command => 'restart', args => [], %a ); };
    is( $rc, 0, 'restart with progress enabled builds and finishes a progress board' );
}

{
    local $ENV{DEVELOPER_DASHBOARD_PROGRESS} = 1;
    my %a = base_args();
    my ( $out, $err, $rc ) = capture { $run_lifecycle->( command => 'stop', args => [], %a ); };
    is( $rc, 0, 'stop with progress enabled builds and finishes a progress board' );
}

# _lifecycle_summary_table's '-' fallback for a falsy details string.
{
    my $table = $summary_table->( {
        web        => { status => 'up', pid => 1, details => '' },
        collectors => [ { name => 'a', status => 'up', pid => 2, details => '' } ],
    } );
    like( $table, qr/web.*dashboard.*up.*1.*-/s,     'falsy web details render as -' );
    like( $table, qr/collector.*a.*up.*2.*-/s,       'falsy collector details render as -' );
}

{
    my $table = $summary_table->( {
        web        => { status => '', pid => 1, details => 'ok' },
        collectors => [ { name => '', status => '', pid => 2, details => 'ok' } ],
    } );
    like( $table, qr/web.*dashboard.*-.*1.*ok/s, 'falsy web status renders as -' );
    like( $table, qr/collector.*-.*-.*2.*ok/s,   'falsy collector name and status render as -' );
}

{
    my $table = $summary_table->( {
        web        => { status => 'up', details => 'ok' },
        collectors => [ { name => 'a', status => 'up', details => 'ok' } ],
    } );
    like( $table, qr/web.*dashboard.*up.*-.*ok/s,      'an undef web pid renders as -' );
    like( $table, qr/collector.*a.*up.*-.*ok/s,        'an undef collector pid renders as -' );
}

# ---------------------------------------------------------- _run_log_command

is_deeply(
    [ Developer::Dashboard::CLI::RuntimeControl::_sort_log_source_names(qw(collector:beta web collector:alpha)) ],
    [qw(web collector:alpha collector:beta)],
    'log source ordering always puts web first and keeps collector sources alphabetical',
);
is_deeply(
    [ Developer::Dashboard::CLI::RuntimeControl::_sort_log_source_names(qw(collector:beta collector:alpha)) ],
    [qw(collector:alpha collector:beta)],
    'log source ordering compares collector names alphabetically when neither source is web',
);

{
    my %a = base_args(
        runtime    => Test::RC::Runtime->new( web_log_result => "web old\nweb newest\n" ),
        collectors => Test::RC::Collectors->new( existing => { alpha => 1 }, logs => { alpha => "collector old\ncollector newest\n" } ),
        config     => Test::RC::Config->new( collectors => [ { name => 'alpha' } ] ),
    );
    my ( $out, $err, $rc ) = capture { $run_log->( args => ['--tail=2'], %a ); };
    is( $rc, 0, 'logs accepts Docker-style --tail=N syntax' );
    is( $out, "collector old\ncollector newest\n", '--tail=N limits combined logs to the final N output lines' );
}

{
    my %a = base_args(
        runtime => Test::RC::Runtime->new( web_log_result => "web event\n" ),
    );
    my ( $out, $err, $rc ) = capture { $run_log->( args => [ '-t', 'web' ], %a ); };
    is( $rc, 0, '-t is accepted for the web log scope' );
    like( $out, qr/\A\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ web event\n\z/, '-t prefixes each web log line with a UTC timestamp' );
}

{
    my %a = base_args(
        collectors => Test::RC::Collectors->new(
            existing => { alpha => 1 },
            logs     => { alpha => "=== collector alpha | \@ 2026-01-02T03:04:05Z | exit=0 ===\n[stdout]\ncollector event\n\n" },
        ),
        config => Test::RC::Config->new( collectors => [ { name => 'alpha' } ] ),
    );
    my ( $out, $err, $rc ) = capture { $run_log->( args => [ 'collector', 'alpha', '-t' ], %a ); };
    is( $rc, 0, '-t is accepted for a named collector log' );
    like( $out, qr/\A2026-01-02T03:04:05Z === collector alpha/, '-t preserves the collector event timestamp' );
    like( $out, qr/2026-01-02T03:04:05Z collector event/, '-t applies the collector event timestamp to its output lines' );
}

{
    my %a = base_args(
        runtime => Test::RC::Runtime->new( web_log_result => "web first\nweb last\n" ),
        collectors => Test::RC::Collectors->new(
            existing => { alpha => 1 },
            logs => { alpha => "=== collector alpha | \@ 2026-01-02T03:04:05Z | exit=0 ===\n[stdout]\ncollector event\n\n" },
        ),
        config => Test::RC::Config->new( collectors => [ { name => 'alpha' } ] ),
    );
    my ( $out, $err, $rc ) = capture { $run_log->( args => [ '-t', '--tail=2' ], %a ); };
    is( $rc, 0, 'timestamp and tail flags combine for mixed logs' );
    like( $out, qr/2026-01-02T03:04:05Z collector event/, 'combined tail keeps collector event timestamp when its record header is outside the tail' );
    unlike( $out, qr/web first|web last/, 'combined tail is applied after the complete timestamped stream is formed' );
}

{
    my $sources = $read_log_sources->(
        scope      => 'collector',
        collectors => Test::RC::Collectors->new,
        config     => Test::RC::Config->new,
    );
    is_deeply( $sources, {}, 'reading web-free logs with no configured collectors produces an empty source map' );
    my $error = eval {
        $read_log_sources->(
            scope      => 'collector',
            name       => 'unknown',
            collectors => Test::RC::Collectors->new,
            config     => Test::RC::Config->new,
        );
        1;
    } ? '' : $@;
    like( $error, qr/^Unknown collector 'unknown'/, 'reading a specifically named unknown collector reports the error' );
}

{
    my $sources = $read_log_sources->(
        scope      => 'collector',
        collectors => Test::RC::Collectors->new( existing => { alpha => 1 }, logs => { alpha => undef } ),
        config     => Test::RC::Config->new( collectors => [ { name => 'alpha' } ] ),
    );
    is( $sources->{'collector:alpha'}, '', 'an undefined collector log is normalized to an empty snapshot' );
}

{
    is( $render_log_sources->( {}, 'web' ), '', 'web rendering returns an empty string for a missing web source' );
    is( $render_log_sources->( { web => undef }, 'web' ), '', 'web rendering normalizes an undefined web source' );
    is( $render_log_sources->( {}, 'collector', 'alpha' ), "No log entries are available yet for collector 'alpha'.\n", 'named collector rendering supplies a placeholder for a missing source key' );
    is( $render_log_sources->( { 'collector:alpha' => '' }, 'collector', 'alpha' ), "No log entries are available yet for collector 'alpha'.\n", 'named collector rendering supplies a placeholder for an empty log' );
    is( $render_log_sources->( {}, 'collector' ), "No collector logs are available yet.\n", 'collector rendering supplies an empty-list placeholder' );
    my $collector_output = $render_log_sources->(
        { 'collector:alpha' => "alpha entry\n", 'collector:beta' => '', 'collector:gamma' => undef },
        'collector',
    );
    like( $collector_output, qr/alpha entry\n/, 'collector rendering includes existing logs' );
    like( $collector_output, qr/No log entries are available yet for collector 'beta'/, 'collector rendering includes placeholders for empty logs' );
    like( $collector_output, qr/No log entries are available yet for collector 'gamma'/, 'collector rendering normalizes an undefined source' );
    my $combined_output = $render_log_sources->(
        { web => "web entry\n", 'collector:alpha' => '', 'collector:beta' => undef },
        'all',
    );
    like( $combined_output, qr/=== dashboard web ===\nweb entry/, 'combined rendering preserves the web header and body' );
    like( $combined_output, qr/No log entries are available yet for collector 'alpha'/, 'combined rendering includes empty collector placeholders' );
    like( $combined_output, qr/No log entries are available yet for collector 'beta'/, 'combined rendering normalizes an undefined source' );
}

is( $timestamp_log_text->(undef), '', 'timestamp formatting returns empty for undefined text' );
is( $timestamp_log_text->(''),    '', 'timestamp formatting returns empty for empty text' );
like( $timestamp_log_text->('unterminated'), qr/\A\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ unterminated\z/, 'timestamp formatting handles a final line without a newline' );

{
    my $poll = 0;
    my $runtime = Test::RC::Runtime->new( web_log_result => sub { ++$poll; return undef } );
    my %a = base_args( runtime => $runtime );
    my $capture_file = File::Spec->catfile( $home, 'follow-undefined-snapshot.log' );
    open my $saved_stdout, '>&', \*STDOUT or die $!;
    open STDOUT, '>', $capture_file or die $!;
    my $sleep_count = 0;
    {
        no warnings 'redefine';
        local *Developer::Dashboard::CLI::RuntimeControl::sleep = sub {
            die "__FOLLOW_STOP__\n" if ++$sleep_count > 1;
            return 0.1;
        };
        eval {
            $follow_log_sources->(
                sources     => { web => "initial\n" },
                scope       => 'web',
                runtime     => $runtime,
                config      => $a{config},
                collectors  => $a{collectors},
                timestamps  => 0,
            );
        };
    }
    my $follow_error = $@;
    open STDOUT, '>&', $saved_stdout or die $!;
    like( $follow_error, qr/__FOLLOW_STOP__/, 'test stops follow after an undefined current snapshot' );
    is( $poll, 1, 'follow handles an undefined source snapshot without printing or dying' );
}

{
    my %a = base_args(
        runtime => Test::RC::Runtime->new( web_log_result => "web oldest\nweb middle\nweb newest\n" ),
    );
    my ( $out, $err, $rc ) = capture { $run_log->( args => [ 'web', '--tail', '2' ], %a ); };
    is( $rc, 0, 'logs accepts --tail N syntax for an explicit web scope' );
    is( $out, "web middle\nweb newest\n", '--tail N prints only the requested trailing web lines' );
}

{
    my %a = base_args(
        collectors => Test::RC::Collectors->new( existing => { alpha => 1 }, logs => { alpha => "old\nmiddle\nnewest\n" } ),
        config     => Test::RC::Config->new( collectors => [ { name => 'alpha' } ] ),
    );
    my ( $out, $err, $rc ) = capture { $run_log->( args => [ 'collector', 'alpha', '--tail', '1' ], %a ); };
    is( $rc, 0, 'tail can be scoped to one collector log' );
    is( $out, "newest\n", 'collector scope prints only its requested trailing lines' );
}

{
    my %a = base_args( runtime => Test::RC::Runtime->new( web_log_result => "one\ntwo\n" ) );
    my ( $out, $err, $rc ) = capture { $run_log->( args => [ '--tail=0', 'web' ], %a ); };
    is( $rc, 0, 'zero tail is accepted as a request for no log lines' );
    is( $out, '', 'zero tail prints no log lines' );
}

{
    my %a = base_args();
    my @parse_warnings;
    my $error;
    {
        local $SIG{__WARN__} = sub { push @parse_warnings, $_[0]; return; };
        eval { capture { $run_log->( args => ['--tail'], %a ); }; };
        $error = $@;
    }
    like( $error, qr/^Usage: dashboard log/, 'tail without its required value is rejected with usage' );
    like( join( '', @parse_warnings ), qr/Option tail requires an argument/, 'Getopt reports the missing tail value explicitly' );
}

{
    my %a = base_args();
    my @parse_warnings;
    my $error;
    {
        local $SIG{__WARN__} = sub { push @parse_warnings, $_[0]; return; };
        eval { capture { $run_log->( args => ['--tail=not-a-number'], %a ); }; };
        $error = $@;
    }
    like( $error, qr/^Usage: dashboard log/, 'a non-integer tail value is rejected with usage' );
    like( join( '', @parse_warnings ), qr/Value .* invalid for option tail/, 'Getopt reports the malformed tail value explicitly' );
}

{
    my %a = base_args();
    eval { capture { $run_log->( args => ['--tail=-1'], %a ); }; };
    like( $@, qr/^Usage: dashboard log/, 'negative tail count is rejected with usage' );
}

is( $tail_log_text->( undef, 1 ), '', 'tailing an undefined log returns empty output' );
is( $tail_log_text->( '', 1 ), '', 'tailing an empty log returns empty output' );
is( $tail_log_text->( "one\ntwo", 4 ), "one\ntwo", 'tail larger than the log keeps all lines without adding a newline' );
is( $tail_log_text->( "\n", 1 ), "\n", 'tailing a blank newline preserves the newline' );

{
    my %a = base_args( runtime => Test::RC::Runtime->new( web_log_result => "web line\n" ) );
    my ( $out, $err, $rc ) = capture { $run_log->( args => [ 'web', '-n', '5' ], %a ); };
    is( $rc, 0, 'log web scope returns 0' );
    like( $out, qr/web line/, 'log web scope prints the web log' );
}

{
    my %a = base_args( runtime => Test::RC::Runtime->new( web_log_result => "streamed\n" ) );
    {
        no warnings 'redefine';
        local *Developer::Dashboard::CLI::RuntimeControl::sleep = sub { die "__FOLLOW_STOP__\n" };
        eval { capture { $run_log->( args => [ 'web', '-f' ], %a ); } };
    }
    like( $@, qr/__FOLLOW_STOP__/, 'follow mode enters the web polling loop' );
}

{
    my %a = base_args();
    {
        no warnings 'redefine';
        local *Developer::Dashboard::CLI::RuntimeControl::sleep = sub { die "__FOLLOW_STOP__\n" };
        eval { capture { $run_log->( args => [ 'collector', '-f' ], %a ); } };
    }
    like( $@, qr/__FOLLOW_STOP__/, 'follow mode enters the collector polling loop' );
}

{
    my $poll = 0;
    my $runtime = Test::RC::Runtime->new(
        web_log_result => sub { return ++$poll == 1 ? "web before\n" : "web before\nweb after\n" },
    );
    my %a = base_args( runtime => $runtime );
    my $capture_file = File::Spec->catfile( $home, 'follow-output.log' );
    open my $saved_stdout, '>&', \*STDOUT or die $!;
    open STDOUT, '>', $capture_file or die $!;
    my $sleep_count = 0;
    {
        no warnings 'redefine';
        local *Developer::Dashboard::CLI::RuntimeControl::sleep = sub {
            die "__FOLLOW_STOP__\n" if ++$sleep_count > 1;
            return 0.1;
        };
        eval { $run_log->( args => [ 'web', '-f' ], %a ); };
    }
    my $follow_error = $@;
    open STDOUT, '>&', $saved_stdout or die $!;
    open my $follow_fh, '<', $capture_file or die $!;
    local $/;
    my $follow_output = <$follow_fh>;
    close $follow_fh;
    like( $follow_error, qr/__FOLLOW_STOP__/, 'test stops web follow after one poll' );
    like( $follow_output, qr/web before\nweb after\n\z/, 'web follow emits the initial log and newly appended lines once' );
}

{
    my ( $web_poll, $collector_poll ) = ( 0, 0 );
    my $runtime = Test::RC::Runtime->new(
        web_log_result => sub { return ++$web_poll == 1 ? "web initial\n" : "web initial\nweb appended\n" },
    );
    my $collectors = Test::RC::Collectors->new(
        existing => { alpha => 1 },
        logs => { alpha => sub { return ++$collector_poll == 1 ? "collector initial\n" : "collector initial\ncollector appended\n" } },
    );
    my %a = base_args(
        runtime    => $runtime,
        collectors => $collectors,
        config     => Test::RC::Config->new( collectors => [ { name => 'alpha' } ] ),
    );
    my $capture_file = File::Spec->catfile( $home, 'follow-mixed-output.log' );
    open my $saved_stdout, '>&', \*STDOUT or die $!;
    open STDOUT, '>', $capture_file or die $!;
    my $sleep_count = 0;
    {
        no warnings 'redefine';
        local *Developer::Dashboard::CLI::RuntimeControl::sleep = sub {
            die "__FOLLOW_STOP__\n" if ++$sleep_count > 1;
            return 0.1;
        };
        eval { $run_log->( args => [ '-t', '-f', '--tail=2' ], %a ); };
    }
    my $follow_error = $@;
    open STDOUT, '>&', $saved_stdout or die $!;
    open my $follow_fh, '<', $capture_file or die $!;
    local $/;
    my $follow_output = <$follow_fh>;
    close $follow_fh;
    like( $follow_error, qr/__FOLLOW_STOP__/, 'test stops mixed follow after one poll' );
    like( $follow_output, qr/\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ collector initial\n/, 'mixed follow starts with a timestamped combined tail' );
    unlike( $follow_output, qr/web initial\n/, 'mixed follow applies --tail before entering follow mode' );
    like( $follow_output, qr/\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ web appended\n/, 'mixed follow timestamps appended web lines' );
    like( $follow_output, qr/\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ collector appended\n/, 'mixed follow timestamps appended collector lines' );
}

{
    my $poll = 0;
    my $collectors = Test::RC::Collectors->new(
        existing => { alpha => 1 },
        logs => { alpha => sub { return ++$poll == 1 ? "old\nnew\n" : "old\nnew\nlater\n" } },
    );
    my %a = base_args(
        collectors => $collectors,
        config     => Test::RC::Config->new( collectors => [ { name => 'alpha' } ] ),
    );
    my $capture_file = File::Spec->catfile( $home, 'follow-named-collector-output.log' );
    open my $saved_stdout, '>&', \*STDOUT or die $!;
    open STDOUT, '>', $capture_file or die $!;
    my $sleep_count = 0;
    {
        no warnings 'redefine';
        local *Developer::Dashboard::CLI::RuntimeControl::sleep = sub {
            die "__FOLLOW_STOP__\n" if ++$sleep_count > 1;
            return 0.1;
        };
        eval { $run_log->( args => [ 'collector', 'alpha', '-t', '-f', '--tail=1' ], %a ); };
    }
    my $follow_error = $@;
    open STDOUT, '>&', $saved_stdout or die $!;
    open my $follow_fh, '<', $capture_file or die $!;
    local $/;
    my $follow_output = <$follow_fh>;
    close $follow_fh;
    like( $follow_error, qr/__FOLLOW_STOP__/, 'test stops named collector follow after one poll' );
    like( $follow_output, qr/\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ new\n/, 'named collector follow starts with its timestamped tail' );
    like( $follow_output, qr/\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ later\n/, 'named collector follow streams and timestamps new entries' );
    unlike( $follow_output, qr/ old\n/, 'named collector follow does not print lines excluded by --tail' );
}

{
    my $web_poll = 0;
    my %collector_poll = ( alpha => 0, beta => 0 );
    my $runtime = Test::RC::Runtime->new(
        web_log_result => sub { return ++$web_poll == 1 ? "short web\n" : "short web\n" },
    );
    my $collectors = Test::RC::Collectors->new(
        existing => { alpha => 1, beta => 1 },
        logs => {
            alpha => sub { return ++$collector_poll{alpha} ? "alpha entry\n" : "alpha entry\n" },
            beta  => sub { return ++$collector_poll{beta}  ? "beta entry\n"  : "beta entry\n" },
        },
    );
    my %a = base_args(
        runtime    => $runtime,
        collectors => $collectors,
        config     => Test::RC::Config->new( collectors => [ { name => 'alpha' }, { name => 'beta' } ] ),
    );
    my $capture_file = File::Spec->catfile( $home, 'follow-rotation-output.log' );
    open my $saved_stdout, '>&', \*STDOUT or die $!;
    open STDOUT, '>', $capture_file or die $!;
    my $sleep_count = 0;
    {
        no warnings 'redefine';
        local *Developer::Dashboard::CLI::RuntimeControl::sleep = sub {
            die "__FOLLOW_STOP__\n" if ++$sleep_count > 2;
            return 0.1;
        };
        eval {
            $follow_log_sources->(
                sources => { web => "a much longer prior log snapshot\n", 'collector:alpha' => undef },
                scope => 'all',
                runtime => $runtime,
                config => $a{config},
                collectors => $collectors,
                timestamps => 0,
            );
        };
    }
    my $follow_error = $@;
    open STDOUT, '>&', $saved_stdout or die $!;
    open my $follow_fh, '<', $capture_file or die $!;
    local $/;
    my $follow_output = <$follow_fh>;
    close $follow_fh;
    like( $follow_error, qr/__FOLLOW_STOP__/, 'test stops follow polling after an unchanged second snapshot' );
    like( $follow_output, qr/short web\n/, 'follow restarts at the beginning after a web-log truncation' );
    like( $follow_output, qr/alpha entry\n/, 'follow starts a newly observed source with no prior offset' );
    like( $follow_output, qr/beta entry\n/, 'follow merges a second collector source into mixed output' );
    is( scalar( () = $follow_output =~ /short web/g ), 1, 'follow emits no duplicate data when the next poll is unchanged' );
}

{
    my %a = base_args( collectors => Test::RC::Collectors->new( existing => { alpha => 1 }, logs => { alpha => "log body\n" } ) );
    my ( $out, $err, $rc ) = capture { $run_log->( args => [ 'collector', 'alpha' ], %a ); };
    is( $rc, 0, 'log collector scope with a named collector returns 0' );
    like( $out, qr/log body/, 'named collector log is printed' );
}

{
    my %a = base_args();
    my ( $out, $err, $rc ) = capture { $run_log->( args => ['collector'], %a ); };
    is( $rc, 0, 'log collector scope with no name returns 0' );
}

{
    my %a = base_args( runtime => Test::RC::Runtime->new( web_log_result => "web body\n" ) );
    my ( $out, $err, $rc ) = capture { $run_log->( args => [], %a ); };
    is( $rc, 0, 'log all scope returns 0' );
    like( $out, qr/=== dashboard web ===/, 'all scope prints the web header' );
}

{
    my %a = base_args( runtime => Test::RC::Runtime->new( web_log_result => "sized\n" ) );
    my ( $out, $err, $rc ) = capture { $run_log->( args => [ '-n', '5' ], %a ); };
    is( $rc, 0, 'a leading option flag at the top is never mistaken for a scope word' );
}

{
    my %a = base_args(
        runtime    => Test::RC::Runtime->new( web_log_result => undef ),
        collectors => Test::RC::Collectors->new( existing => { alpha => 1 }, logs => { alpha => "collector line\n" } ),
        config     => Test::RC::Config->new( collectors => [ { name => 'alpha' } ] ),
    );
    my ( $out, $err, $rc ) = capture { $run_log->( args => [], %a ); };
    is( $rc, 0, 'all scope with an undef web log still returns 0' );
    unlike( $out, qr/=== dashboard web ===/, 'an undef web log omits the web header' );
    like( $out, qr/collector line/,          'the collector log still prints' );
}

{
    my %a = base_args( runtime => Test::RC::Runtime->new( web_log_result => '' ) );
    my ( $out, $err, $rc ) = capture { $run_log->( args => [], %a ); };
    is( $rc, 0, 'all scope with an empty-string web log still returns 0' );
    unlike( $out, qr/=== dashboard web ===/, 'an empty-string web log omits the web header' );
}

{
    my %a = base_args();
    eval { capture { $run_log->( args => ['bogus'], %a ); } };
    like( $@, qr/^Usage: dashboard log/, 'unknown scope dies with usage' );
}

{
    my %a = base_args();
    eval { capture { $run_log->( args => ['-'], %a ); } };
    like( $@, qr/^Usage: dashboard log/, 'a lone dash is not consumed as the log scope' );
}

{
    my %a = base_args();
    eval { capture { $run_log->( args => [ 'collector', '-' ], %a ); } };
    like( $@, qr/^Usage: dashboard log/, 'a lone dash is not consumed as a collector name' );
}

{
    my %a = base_args();
    eval { capture { $run_log->( args => [ 'web', 'extra' ], %a ); } };
    like( $@, qr/^Usage: dashboard log/, 'leftover log argv dies with usage' );
}

# ---------------------------------------------------------- _collector_logs_text

{
    my $collectors = Test::RC::Collectors->new( existing => { a => 1 }, logs => { a => "hello\n" } );
    my $text = $collector_logs_text->( collectors => $collectors, config => Test::RC::Config->new, name => 'a' );
    like( $text, qr/hello/, 'named collector with a log returns its text' );
}

{
    my $collectors = Test::RC::Collectors->new( existing => { a => 1 } );
    my $text = $collector_logs_text->( collectors => $collectors, config => Test::RC::Config->new, name => 'a' );
    like( $text, qr/No log entries are available yet for collector 'a'/, 'named collector with no log gets the placeholder' );
}

{
    my $collectors = Test::RC::Collectors->new( existing => { a => 1 }, logs => { a => '' } );
    my $text = $collector_logs_text->( collectors => $collectors, config => Test::RC::Config->new, name => 'a' );
    like( $text, qr/No log entries are available yet for collector 'a'/, 'an explicit empty-string log also gets the placeholder' );
}

{
    my $collectors = Test::RC::Collectors->new;
    eval { $collector_logs_text->( collectors => $collectors, config => Test::RC::Config->new, name => 'ghost' ) };
    like( $@, qr/Unknown collector 'ghost'/, 'named unknown collector dies' );
}

{
    my $config = Test::RC::Config->new( collectors => [ { name => 'a' } ] );
    my $collectors = Test::RC::Collectors->new( logs => { a => "one\n" } );
    my $text = $collector_logs_text->( collectors => $collectors, config => $config, name => undef );
    like( $text, qr/one/, 'unnamed sweep with one configured collector prints its log' );
}

{
    my $collectors = Test::RC::Collectors->new;
    my $text = $collector_logs_text->( collectors => $collectors, config => Test::RC::Config->new, name => '' );
    like( $text, qr/No collector logs are available yet/, 'unnamed sweep with no known collectors' );
}

{
    my $config = Test::RC::Config->new( collectors => [ { name => 'a' } ] );
    my $collectors = Test::RC::Collectors->new;
    my $text = $collector_logs_text->( collectors => $collectors, config => $config );
    like( $text, qr/No log entries are available yet for collector 'a'/, 'unnamed sweep placeholder per collector with no log' );
}

{
    my $config = Test::RC::Config->new( collectors => [ { name => 'a' } ] );
    my $collectors = Test::RC::Collectors->new( logs => { a => '' } );
    my $text = $collector_logs_text->( collectors => $collectors, config => $config );
    like( $text, qr/No log entries are available yet for collector 'a'/, 'unnamed sweep placeholder for an explicit empty-string log' );
}

# ---------------------------------------------------------- _known_collector_names

{
    my $config = Test::RC::Config->new( collectors => [ { name => 'a' }, { name => 'a' }, { name => 'b' }, 'not-a-hash', { name => '' } ] );
    my $collectors = Test::RC::Collectors->new( persisted => [ { name => 'b' }, { name => 'c' }, 'not-a-hash', { name => '' } ] );
    my @names = $known_names->( $collectors, $config );
    is_deeply( \@names, [ 'a', 'b', 'c' ], 'union of configured and persisted names, deduped, order preserved' );
}

# ---------------------------------------------------------- _collector_known

{
    my $config = Test::RC::Config->new( collectors => [ { name => 'a' } ] );
    ok( $collector_known->( Test::RC::Collectors->new, $config, 'a' ), 'known via config' );
    ok( $collector_known->( Test::RC::Collectors->new( existing => { b => 1 } ), Test::RC::Config->new, 'b' ), 'known via persisted store' );
    ok( !$collector_known->( Test::RC::Collectors->new, Test::RC::Config->new, 'ghost' ), 'not known anywhere' );
    ok( !$collector_known->( Test::RC::Collectors->new, Test::RC::Config->new, undef ), 'undef name is not known' );
    ok( !$collector_known->( Test::RC::Collectors->new, Test::RC::Config->new, '' ), 'empty name is not known' );

    my $mixed_config = Test::RC::Config->new( collectors => [ 'not-a-hash', { name => 'other' }, { name => 'target' } ] );
    ok( $collector_known->( Test::RC::Collectors->new, $mixed_config, 'target' ),
        'known via config among a non-hash entry and a non-matching name' );

    my $nameless_config = Test::RC::Config->new( collectors => [ {}, { name => 'target' } ] );
    ok( $collector_known->( Test::RC::Collectors->new, $nameless_config, 'target' ),
        'known via config among a hash entry with no name key at all' );
}

# ---------------------------------------------------------- _lifecycle_progress

{
    local $ENV{DEVELOPER_DASHBOARD_PROGRESS} = '';
    delete $ENV{DEVELOPER_DASHBOARD_PROGRESS};
    my $progress = $lifecycle_progress->( title => 't', tasks => [] );
    ok( !defined $progress, 'progress is undef when disabled and STDERR is not a tty' );
}

{
    local $ENV{DEVELOPER_DASHBOARD_PROGRESS} = 1;
    my $progress = $lifecycle_progress->( title => 't', tasks => [ { id => 'x' } ] );
    ok( defined $progress, 'progress is built when explicitly enabled' );
    isa_ok( $progress, 'Developer::Dashboard::CLI::Progress' );
}

{
    local $ENV{DEVELOPER_DASHBOARD_PROGRESS} = 1;
    my $progress = $lifecycle_progress->();
    ok( defined $progress, 'progress falls back to a default title and empty task list when neither is given' );
}

# ---------------------------------------------------------- _lifecycle_summary_table

{
    my $table = $summary_table->( { web => { status => 'up', pid => 1, details => 'ok' } } );
    like( $table, qr/web.*dashboard.*up.*1.*ok/s, 'summary table renders a web row' );
}

{
    my $table = $summary_table->( {} );
    unlike( $table, qr/web/, 'summary table with no web key omits the web row' );
}

# ---------------------------------------------------------- _render_table / _pad_row

{
    my $table = $render_table->( [ 'H1', 'H2' ], [ [ 'a', 'bb' ], [ 'ccc', 'd' ] ] );
    like( $table, qr/H1 .*H2/, 'render_table includes the header' );
    like( $table, qr/-+  -+/, 'render_table includes a separator row' );
}

{
    my $table = $render_table->( [ 'H1', 'H2' ], [ [ 'a', undef ] ] );
    like( $table, qr/H1/, 'render_table tolerates an undef cell when computing column widths' );
}

{
    # sprintf('%-*s',3,'a') = 'a  ' (3 chars), joined with '  ', then
    # sprintf('%-*s',3,'') = '   ' (3 chars) for the undef cell.
    my $row = $pad_row->( [ 'a', undef ], [ 3, 3 ] );
    is( $row, 'a  ' . '  ' . '   ', 'pad_row treats an undef cell as an empty string' ) or diag($row);
}

# ---------------------------------------------------------- usage strings

{
    like( $lifecycle_usage->('restart'), qr/^Usage: dashboard restart/, 'lifecycle usage names the command' );
    like( $log_usage->(),                qr/^Usage: dashboard log/,     'log usage text' );
}

is( scalar(@warnings), 0, 'no warnings escaped the run' ) or diag( join "\n", @warnings );

done_testing;

__END__

=head1 NAME

t/26-cli-runtimecontrol-coverage.t - Devel::Cover gate for the runtime control CLI

=head1 PURPOSE

Exercises every function in C<Developer::Dashboard::CLI::RuntimeControl> - the
shared parser and default output renderer behind C<dashboard restart>,
C<dashboard stop>, and C<dashboard log[s]> (including Docker-style timestamps,
follow mode, and tail options) - against injected stand-in objects
for the runtime manager, config, and collector store it is handed, so the
module can reach 100.0 on all four Devel::Cover metrics without a real
process-managing runtime.

=head1 WHY IT EXISTS

C<lib/Developer/Dashboard/CLI/RuntimeControl.pm> shipped with no test file at
all - hunt-monitor's C<imp-untested-modules> check found it named by no test
(DD-640). The module's public entry point dispatches to two private command
parsers, each with several die paths, scope/target parsing branches, and
output-format choices, none of which had ever been exercised.

=head1 WHEN TO USE

Use this file when changing C<run_runtime_command>, the restart/stop lifecycle
parser, the log/logs parser and timestamp/follow/tail behavior, collector name resolution,
the optional progress board, or the default table/JSON rendering for
runtime-control commands. The source-name sorter test also pins web-first and
alphabetical collector ordering for follow-mode output.

=head1 HOW TO USE

Run C<prove -lv t/26-cli-runtimecontrol-coverage.t> while iterating, and keep
it green under C<prove -lr t> before release. The file is hermetic: it roots a
temporary home and chdirs into it, then calls the module's public and private
functions directly (via C<\&Package::_func> references) against three small
injectable stand-ins - C<Test::RC::Runtime>, C<Test::RC::Config>, and
C<Test::RC::Collectors> - rather than through the CLI dispatch layer or a real
C<Developer::Dashboard::RuntimeManager>, so no board write and no process
lifecycle action is ever at risk of actually happening. To confirm the coverage
contribution, run the suite under C<HARNESS_PERL_SWITCHES=-MDevel::Cover> and
check the branch and condition columns for the runtime control module.

=head1 WHAT USES IT

The repository test suite, the Devel::Cover gate, and developers changing the
runtime-control CLI use this file to keep C<dashboard restart>,
C<dashboard stop>, and C<dashboard log[s]> behaving as documented.

=head1 EXAMPLES

Example 1:

  prove -lv t/26-cli-runtimecontrol-coverage.t

Run the runtime-control CLI coverage checks on their own while iterating.

Example 2:

  prove -lr t

Run them inside the full repository suite before release.

Example 3:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t

Run them under the coverage gate to confirm the runtime-control branch and
condition columns stay at 100.

Example 4:

  d2 logs --tail 25
  d2 logs --tail=25

Exercise both public spellings for limiting combined dashboard and collector
logs to the last 25 output lines.

=cut
