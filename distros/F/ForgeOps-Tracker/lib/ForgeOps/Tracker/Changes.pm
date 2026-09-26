package ForgeOps::Tracker::Changes;

use strict;
use warnings;
use POSIX qw(strftime);
use Time::HiRes ();

# Payloads for "what changed": one explicit record_change() call (POST /api/v1/changes), and the
# startup snapshot (POST /api/v1/change_snapshots) that ForgeOps diffs against the previous boot's
# to record what changed between deploys. Mirrors gems/forge_ops_tracker's Change and
# ChangeSnapshot.
#
# The snapshot leaves out any key it can't determine reliably rather than guessing, since the
# server reads a missing key as "unknown", never as "everything was removed". That's why there's no
# dependencies key here: Perl has no single reliable record of which module versions an app runs
# (no lockfile every app has, and %INC only lists what happened to be loaded so far), so the
# snapshot carries the Perl version and, when opted in, environment variable names. Names only,
# never values.

# The server rejects any other kind outright (422), so an unknown one is sent as "other" rather
# than dropped: the change still gets recorded, just less specifically categorized.
our @KINDS = qw(feature_flag config migration dependency infrastructure other);
my %KNOWN_KIND = map { $_ => 1 } @KINDS;
my $MAX_TITLE_LENGTH = 200;
my $MAX_ENV_VAR_NAMES = 3000;

# Host-specific variables that differ from one box to the next (or one boot to the next) without
# anything about the deploy having changed, so a fleet doesn't look like it's changing on every
# restart. The client's own FORGE_OPS_* settings are dropped too.
my %ENV_VAR_DENYLIST = map { $_ => 1 } qw(
    HOSTNAME HOST HOME PATH PWD OLDPWD SHLVL _ TERM USER LOGNAME SHELL LANG TMPDIR TZ PORT DYNO
    INVOCATION_ID JOURNAL_STREAM
);
my @ENV_VAR_DENYLIST_PATTERNS = (
    qr/^LC_/, qr/^SYSTEMD_/, qr/^MEMORY_PRESSURE_/, qr/^KUBERNETES_/, qr/^FORGE_OPS_/,
    qr/_SERVICE_HOST$/, qr/_SERVICE_PORT/, qr/_PORT_.*_TCP/,
);

sub normalize_kind {
    my ($kind) = @_;
    return defined $kind && $KNOWN_KIND{$kind} ? $kind : 'other';
}

# build_change($configuration, %change): the body for one record_change() call, or undef when
# there's nothing sendable (a blank title: the server requires one, so posting it anyway would only
# ever come back 422). occurred_at is an ISO 8601 string or epoch seconds, defaulting to now.
sub build_change {
    my ($configuration, %change) = @_;

    my $title = defined $change{title} ? "$change{title}" : '';
    $title =~ s/\A\s+|\s+\z//g;
    return undef unless length $title;

    my %payload = (
        kind        => normalize_kind($change{kind}),
        title       => substr($title, 0, $MAX_TITLE_LENGTH),
        details     => ref $change{details} eq 'HASH' ? $change{details} : {},
        environment => defined $change{environment} ? "$change{environment}" : $configuration->{environment},
        occurred_at => _iso8601($change{occurred_at}),
    );
    for my $key (qw(service actor url id)) {
        $payload{$key} = "$change{$key}" if defined $change{$key};
    }
    return \%payload;
}

sub _iso8601 {
    my ($value) = @_;
    return "$value" if defined $value && $value !~ /\A\d+(?:\.\d+)?\z/;

    my $time = defined $value ? $value : Time::HiRes::time();
    return strftime('%Y-%m-%dT%H:%M:%S', gmtime(int $time)) . sprintf('.%03dZ', int(($time - int $time) * 1000));
}

sub is_denied_env_var {
    my ($name) = @_;
    return 1 if $ENV_VAR_DENYLIST{$name};
    for my $pattern (@ENV_VAR_DENYLIST_PATTERNS) {
        return 1 if $name =~ $pattern;
    }
    return 0;
}

# env_var_names(\%env): names only, never values, sorted so the same set always serializes the same
# way. Defaults to this process's %ENV.
sub env_var_names {
    my ($env) = @_;
    $env ||= \%ENV;
    my @names = sort grep { !is_denied_env_var($_) } keys %$env;
    splice(@names, $MAX_ENV_VAR_NAMES) if @names > $MAX_ENV_VAR_NAMES;
    return \@names;
}

sub runtime {
    return sprintf('perl %vd', $^V);
}

sub build_snapshot {
    my ($configuration) = @_;
    my %state = (runtime => runtime());
    $state{env_var_names} = env_var_names() if $configuration->{track_env_var_names};
    return { environment => $configuration->{environment}, state => \%state };
}

1;
