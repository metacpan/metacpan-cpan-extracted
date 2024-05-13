package Linux::Landlock::Direct;

=head1 NAME

Linux::Landlock::Direct - Direct, low-level interface to the Linux Landlock API

=head1 DESCRIPTION

This module provides a functional interface to the Linux Landlock API.
It is a relatively thin wrapper around the Landlock system calls.

See L<Linux::Landlock> for a higher-level OO and exception based interface.

See L<https://docs.kernel.org/userspace-api/landlock.html> for more information about Landlock.

=head1 SYNOPSIS

    use Linux::Landlock::Direct qw(:functions :constants set_no_new_privs);

    # create a new ruleset with all supported actions
    my $ruleset_fd = ll_create_ruleset();
    opendir my $dir, '/tmp';
    # allow read and write access to files in /tmp, truncate is typically also needed, depending on the open call
    ll_add_path_beneath_rule($ruleset_fd,
        $LANDLOCK_RULE{PATH_BENEATH},
        $LANDLOCK_ACCESS_FS{READ_FILE} | $LANDLOCK_ACCESS_FS{WRITE} | $LANDLOCK_ACCESS_FS{TRUNCATE},
        $dir,
    );
    # NO_NEW_PRIVS is required for ll_restrict_self() to work, it can be set by any means, e.g. inherited or
    # set via some other module; this implementation just exists for convenience
    set_no_new_privs();
    # apply the ruleset to the current process and future children. This cannot be undone.
    ll_restrict_self($ruleset_fd);

=head1 FUNCTIONS

=over 1

=item ll_get_abi_version()

Int, returns the ABI version of the Landlock implementation. Minimum version is 1.
Returns -1 on error.

=item ll_create_fs_ruleset(@actions)

Int (file descriptor), creates a new Landlock ruleset that covers the specified file system
actions.

If no actions are specified, all supported actions are covered.

Returns the file descriptor of the new ruleset on success, or undef on error.

=item ll_create_net_ruleset(@actions)

Int (file descriptor), like L</ll_create_fs_ruleset(@actions)>, but for network actions.

This requires an ABI version of at least 4.

=item ll_create_ruleset($fs_actions, $net_actions)

Int (file descriptor), creates a new Landlock ruleset that can cover file system
and network actions at the same time.

=item ll_add_path_beneath_rule($ruleset_fd, $allowed_access, $parent)

Add a rule of type C<PATH_BENEATH> to the ruleset. C<$allowed_access> is a bitmask of allowed
accesses, C<$parent> is the filesystem object the rule applies to.

It can be either a Perl file handle or a bare file descriptor and point to either a directory
or a file.

If access rights are not supported by the running kernel, they are silently ignored.

=item ll_add_net_port_rule($ruleset_fd, $allowed_access, $port)

Add a rule of type C<NET_PORT> to the ruleset. C<$allowed_access> is a bitmask of allowed
accesses, C<$port> is the port the rule applies to.

This requires an ABI version of at least 4.

If access rights are not supported by the running kernel, they are silently ignored.

=item ll_all_fs_access_supported()

Returns a bitmask of all file system access rights that are known to this module and supported
by the running kernel.

=item ll_all_net_access_supported()

Returns a bitmask of all network access rights that are known to this module and supported
by the running kernel.

=item ll_restrict_self($ruleset_fd)

Apply the ruleset to the current process and all future children. This cannot be undone.
C<NO_NEW_PRIVS> must have been applied to the current process before calling this function.

=item set_no_new_privs()

Set the NO_NEW_PRIVS flag for the current process. This is required for L</ll_restrict_self($ruleset_fd)>
to work. See L<https://docs.kernel.org/userspace-api/no_new_privs.html> for more information.

This is technically not part of Landlock and only added for convenience.

=back

=head1 EXPORTS

Nothing is exported by default. The following tags are available:

=over 1

=item :functions

All functions, except for C<set_no_new_privs>.

=item :constants

All constants:

C<%LANDLOCK_ACCESS_FS>

    # ABI version 1
    EXECUTE
    WRITE_FILE
    READ_FILE
    READ_DIR
    REMOVE_DIR
    REMOVE_FILE
    MAKE_CHAR
    MAKE_DIR
    MAKE_REG
    MAKE_SOCK
    MAKE_FIFO
    MAKE_BLOCK
    MAKE_SYM
    # ABI version 2
    REFER
    # ABI version 3
    TRUNCATE

C<%LANDLOCK_ACCESS_NET>

    # ABI version 4
    BIND_TCP
    CONNECT_TCP

C<%LANDLOCK_RULE>

    PATH_BENEATH
    NET_PORT

See L<https://docs.kernel.org/userspace-api/landlock.html> for more information.

=item set_no_new_privs

The C<set_no_new_privs> helper function.

=back

=head1 THREADS

Landlock rules are per thread. So either apply them before spawning other threads or
ensure that the rules are applied in each thread.

=cut

use strict;
use warnings;
use Exporter 'import';
use List::Util                qw(reduce);
use POSIX                     qw();
use Linux::Landlock::Syscalls qw(NR Q_pack);

our $VERSION = '0.5';
# adapted from linux/landlock.ph, architecture independent consts
my $LANDLOCK_CREATE_RULESET_VERSION = (1 << 0);
our %LANDLOCK_ACCESS_FS = (
    # ABI version 1
    EXECUTE     => (1 << 0),
    WRITE_FILE  => (1 << 1),
    READ_FILE   => (1 << 2),
    READ_DIR    => (1 << 3),
    REMOVE_DIR  => (1 << 4),
    REMOVE_FILE => (1 << 5),
    MAKE_CHAR   => (1 << 6),
    MAKE_DIR    => (1 << 7),
    MAKE_REG    => (1 << 8),
    MAKE_SOCK   => (1 << 9),
    MAKE_FIFO   => (1 << 10),
    MAKE_BLOCK  => (1 << 11),
    MAKE_SYM    => (1 << 12),
    # ABI version 2
    REFER => (1 << 13),
    # ABI version 3
    TRUNCATE => (1 << 14),
);
our %LANDLOCK_ACCESS_NET = (
    # ABI version 4
    BIND_TCP    => (1 << 0),
    CONNECT_TCP => (1 << 1),
);
our %LANDLOCK_RULE = (
    PATH_BENEATH => 1,
    NET_PORT     => 2,
);
our @EXPORT_OK = qw(
  ll_get_abi_version
  ll_create_ruleset
  ll_create_fs_ruleset
  ll_create_net_ruleset
  ll_add_path_beneath_rule
  ll_add_net_port_rule
  ll_all_fs_access_supported
  ll_all_net_access_supported
  ll_restrict_self
  set_no_new_privs
  %LANDLOCK_ACCESS_FS
  %LANDLOCK_ACCESS_NET
  %LANDLOCK_RULE
);
our %EXPORT_TAGS = (
    functions => [grep { /^ll_/x } @EXPORT_OK],
    constants => [grep { /^%/x } @EXPORT_OK],
);

my %MAX_FS_SUPPORTED = (
    -1 => 0,
    1  => $LANDLOCK_ACCESS_FS{MAKE_SYM},
    2  => $LANDLOCK_ACCESS_FS{REFER},
    3  => $LANDLOCK_ACCESS_FS{TRUNCATE},
);
my %MAX_NET_SUPPORTED = (
    -1 => 0,
    1  => 0,
    2  => 0,
    3  => 0,
    4  => $LANDLOCK_ACCESS_NET{CONNECT_TCP},
);

my ($abi_version, $fs_access_supported, $net_port_supported);

sub ll_all_fs_access_supported {
    if (!defined $fs_access_supported) {
        my $version = ll_get_abi_version();
        $version             = 3 if $version > 3;
        $fs_access_supported = reduce { $a | $b } 0,
          grep { $_ <= $MAX_FS_SUPPORTED{$version} } values %LANDLOCK_ACCESS_FS;
    }
    return $fs_access_supported;
}

sub ll_all_net_access_supported {
    if (!defined $net_port_supported) {
        my $version = ll_get_abi_version();
        $version = 4 if $version > 4;
        $net_port_supported =
          reduce { $a | $b } 0, grep { $_ <= $MAX_NET_SUPPORTED{$version} } values %LANDLOCK_ACCESS_NET;
    }
    return $net_port_supported;
}

sub ll_get_abi_version {
    $abi_version = syscall(NR('landlock_create_ruleset'), undef, 0, $LANDLOCK_CREATE_RULESET_VERSION);
    return $abi_version;
}

sub ll_create_fs_ruleset {
    my (@actions) = @_;
    # handle all known and supported actions if none are specified
    @actions = ll_all_fs_access_supported() unless @actions;
    return ll_create_ruleset(\@actions, []);
}

sub ll_create_net_ruleset {
    my (@actions) = @_;
    # handle all known and supported actions if none are specified
    @actions = ll_all_net_access_supported() unless @actions;
    return ll_create_ruleset([], \@actions);
}

sub ll_create_ruleset {
    my ($fs_actions, $net_actions) = @_;

    my $allowed = Q_pack(reduce { $a | $b } 0, @$fs_actions);
    if (ll_get_abi_version >= 4) {
        $allowed .= Q_pack(reduce { $a | $b } 0, @$net_actions);
    }
    my $fd = syscall(NR('landlock_create_ruleset'), $allowed, length $allowed, 0);
    if ($fd >= 0) {
        return $fd;
    } else {
        return;
    }
}

sub ll_add_path_beneath_rule {
    my ($ruleset_fd, $allowed_access, $parent) = @_;

    my $fd     = ref $parent ? fileno $parent : $parent;
    my $result = syscall(
        NR('landlock_add_rule'), $ruleset_fd,
        $LANDLOCK_RULE{PATH_BENEATH},
        Q_pack($allowed_access & ll_all_fs_access_supported) . pack('l', $fd), 0
    );
    return ($result == 0) ? 1 : undef;
}

sub ll_add_net_port_rule {
    my ($ruleset_fd, $allowed_access, $port) = @_;

    my $result = syscall(
        NR('landlock_add_rule'), $ruleset_fd,
        $LANDLOCK_RULE{NET_PORT},
        Q_pack($allowed_access & ll_all_net_access_supported) . Q_pack($port), 0
    );
    return ($result == 0) ? 1 : undef;
}

sub set_no_new_privs {
    my $PR_SET_NO_NEW_PRIVS = 38;
    return (syscall(NR('prctl'), $PR_SET_NO_NEW_PRIVS, 1, 0, 0, 0) == 0) ? 1 : undef;
}

sub ll_restrict_self {
    my ($ruleset_fd) = @_;
    return (syscall(NR('landlock_restrict_self'), $ruleset_fd, 0) == 0) ? 1 : undef;
}

1;
