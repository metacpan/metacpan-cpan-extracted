package Developer::Dashboard::EnvAudit;

use strict;
use warnings;

our $VERSION = '3.09';

use Developer::Dashboard::JSON qw(json_decode json_encode);

our %AUDIT;

# clear()
# Resets the in-process env audit inventory and removes the exported process
# copy so child processes do not inherit stale records.
# Input: none.
# Output: true value.
sub clear {
    %AUDIT = ();
    delete $ENV{DEVELOPER_DASHBOARD_ENV_AUDIT};
    return 1;
}

# record($key, $value, $envfile)
# Records one effective environment key, value, and source file after an env
# layer has been loaded.
# Input: environment key string, scalar value, and absolute env file path.
# Output: true value.
sub record {
    my ( $class, $key, $value, $envfile ) = @_;
    die "Missing env audit key\n" if !defined $key || $key eq '';
    die "Missing env audit source file\n" if !defined $envfile || $envfile eq '';
    $class->_load_from_env();
    $AUDIT{$key} = {
        value   => $value,
        envfile => $envfile,
    };
    $class->_sync_to_env();
    return 1;
}

# key($key)
# Returns the effective recorded audit entry for one environment key when the
# key was loaded from a dashboard-managed env file.
# Input: environment key string.
# Output: hash reference with value and envfile, or undef for untracked keys.
sub key {
    my ( $class, $key ) = @_;
    return undef if !defined $key || $key eq '';
    my $audit = $class->_audit_copy();
    return undef if !exists $audit->{$key};
    return $audit->{$key};
}

# keys()
# Returns the full effective audit inventory for all environment keys loaded
# by dashboard-managed env files.
# Input: none.
# Output: hash reference keyed by environment variable name.
sub keys {
    my ($class) = @_;
    return $class->_audit_copy();
}

# _audit_copy()
# Returns a deep copy of the current audit inventory so callers cannot mutate
# the shared in-process state accidentally.
# Input: none.
# Output: hash reference of audit entries.
sub _audit_copy {
    my ($class) = @_;
    $class->_load_from_env();
    my %copy = map {
        $_ => {
            value   => $AUDIT{$_}{value},
            envfile => $AUDIT{$_}{envfile},
        }
    } CORE::keys %AUDIT;
    return \%copy;
}

# _load_from_env()
# Lazily rehydrates the audit inventory from the exported process environment
# so exec'd child helpers can inspect the same env provenance.
# Input: none.
# Output: true value.
sub _load_from_env {
    my ($class) = @_;
    return 1 if %AUDIT;
    my $raw = $ENV{DEVELOPER_DASHBOARD_ENV_AUDIT} || '';
    return 1 if $raw eq '';
    my $decoded = json_decode($raw);
    die "DEVELOPER_DASHBOARD_ENV_AUDIT must decode to a hash\n" if ref($decoded) ne 'HASH';
    %AUDIT = map {
        $_ => {
            value   => $decoded->{$_}{value},
            envfile => $decoded->{$_}{envfile},
        }
    } CORE::keys %{$decoded};
    return 1;
}

# _sync_to_env()
# Serializes the in-process audit inventory back into the environment so exec'd
# child processes can inspect the same env provenance.
# Input: none.
# Output: true value.
sub _sync_to_env {
    my ($class) = @_;
    $ENV{DEVELOPER_DASHBOARD_ENV_AUDIT} = json_encode( $class->_audit_copy );
    return 1;
}

1;

__END__

=pod

=head1 NAME

Developer::Dashboard::EnvAudit - inspect dashboard-loaded env key provenance

=head1 SYNOPSIS

  use Developer::Dashboard::EnvAudit;

  my $entry = Developer::Dashboard::EnvAudit->key('FOO');
  my $all   = Developer::Dashboard::EnvAudit->keys;

=head1 DESCRIPTION

This module records which dashboard-managed env file supplied each effective
environment variable so runtime code, custom commands, and skill commands can
inspect where a value came from after layered env loading has completed.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module is the runtime audit trail for env loading. Read it when you need to know which file supplied an effective environment key after the DD-OOP-LAYERS env chain and any skill-local env files have been applied.

=head1 WHY IT EXISTS

It exists because env files can now come from multiple runtime layers and skill roots. Without a stable audit inventory, contributors and runtime commands would have to guess which layer won for a given key.

=head1 WHEN TO USE

Use this module when a command, hook, or runtime helper needs to explain where an env key came from, or when tests need to verify that the deepest participating layer really supplied the winning value.

=head1 HOW TO USE

Call C<Developer::Dashboard::EnvAudit-E<gt>key('FOO')> to inspect one key, or C<Developer::Dashboard::EnvAudit-E<gt>keys> to retrieve the full recorded inventory. The module also mirrors the audit inventory into C<DEVELOPER_DASHBOARD_ENV_AUDIT> so exec'd child processes can inspect the same provenance.

=head1 WHAT USES IT

It is used by dashboard env loading, custom commands, skill commands, and regression tests that verify layered env precedence and env provenance reporting.

=head1 EXAMPLES

Example 1:

  my $entry = Developer::Dashboard::EnvAudit->key('DATABASE_URL');

Returns the effective value and source file for one env key when dashboard loaded it from a managed env file.

Example 2:

  my $keys = Developer::Dashboard::EnvAudit->keys;

Returns the full effective env audit inventory keyed by environment variable name.

Example 3:

  Developer::Dashboard::EnvAudit->clear;

Clears the current process audit state before a fresh env-loading pass.

=for comment FULL-POD-DOC END

=cut
