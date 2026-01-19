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

    # optional: restrict the Landlock functionality that can be used
    ll_set_max_abi_version(4);
    # create a new ruleset with all supported actions
    my $ruleset_fd = ll_create_ruleset()
      or die "ruleset creation failed: $!\n";
    opendir my $dir, '/tmp';
    # allow read and write access to files in /tmp, truncate is typically also needed, depending on the open call
    ll_add_path_beneath_rule($ruleset_fd,
        $LANDLOCK_RULE{PATH_BENEATH},
        $LANDLOCK_ACCESS_FS{READ_FILE} | $LANDLOCK_ACCESS_FS{WRITE} | $LANDLOCK_ACCESS_FS{TRUNCATE},
        $dir,
    );
    # NO_NEW_PRIVS is required for ll_restrict_self() to work, it can be set by any means, e.g. inherited or
    # set via some other module; this implementation just exists for convenience. This cannot be undone.
    set_no_new_privs();
    # apply the ruleset to the current process and future children. This cannot be undone.
    ll_restrict_self($ruleset_fd);

=head1 FUNCTIONS

=over 1

=item ll_get_abi_version()

Int, returns the ABI version of the Landlock implementation. Minimum version is 1.
Returns -1 on error.

=item ll_set_max_abi_version($max_version)

Sets the maximum ABI version to use. This prevents unexpected behaviour changes when
your application is running on a newer ABI version.

This should be set to the highest version you tested with.

If this is not used, or called with an undef argument, the maximum supported ABI
version will be used. This means future kernels could break your application.

=item ll_create_scoped_ruleset(@actions)

Int (file descriptor), creates a new Landlock ruleset that covers "scoped" actions.

=item ll_create_ruleset($fs_actions, $net_actions, $scoped_actions)

Int (file descriptor), creates a new Landlock ruleset that can cover file system,
network, and scoped actions at once. If no arguments are provided, it defaults to all possible
actions at the same time. Returns undef on error.

=item ll_add_path_beneath_rule($ruleset_fd, $allowed_access, $parent)

Add a rule of type C<PATH_BENEATH> to the ruleset. C<$allowed_access> is a bitmask of allowed
accesses, C<$parent> is the filesystem object the rule applies to.

It can be either a Perl file handle or a bare file descriptor and point to either a directory
or a file.

If access rights are not supported by the running kernel, they are silently ignored, in line
with the "best effort" approach recommended by the Landlock documentation.

Returns undef on error or the set of applied access rights on success.

=item ll_add_net_port_rule($ruleset_fd, $allowed_access, $port)

Add a rule of type C<NET_PORT> to the ruleset. C<$allowed_access> is a bitmask of allowed
accesses, C<$port> is the port the rule applies to.

This requires an ABI version of at least 4.

If access rights are not supported by the running kernel, they are silently ignored.
Returns undef on error or the set of applied access rights on success.

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

=item get_no_new_privs()

Get the current state of the NO_NEW_PRIVS flag.

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
    # ABI version 5
    IOCTL_DEV

C<%LANDLOCK_ACCESS_NET>

    # ABI version 4
    BIND_TCP
    CONNECT_TCP

C<%%LANDLOCK_SCOPED>

    ABSTRACT_UNIX_SOCKET
    SIGNAL

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
use List::Util                qw(reduce min);
use POSIX                     qw();
use Linux::Landlock::Syscalls qw(NR Q_pack);
use Math::BigInt;

our $MAX_ABI_VERSION = 6;

# adapted from linux/landlock.ph, architecture independent consts
my $LANDLOCK_CREATE_RULESET_VERSION = (1 << 0);
our %LANDLOCK_ACCESS_FS = (
    # ABI version 1
    EXECUTE     => Math::BigInt->bone->blsft(0),
    WRITE_FILE  => Math::BigInt->bone->blsft(1),
    READ_FILE   => Math::BigInt->bone->blsft(2),
    READ_DIR    => Math::BigInt->bone->blsft(3),
    REMOVE_DIR  => Math::BigInt->bone->blsft(4),
    REMOVE_FILE => Math::BigInt->bone->blsft(5),
    MAKE_CHAR   => Math::BigInt->bone->blsft(6),
    MAKE_DIR    => Math::BigInt->bone->blsft(7),
    MAKE_REG    => Math::BigInt->bone->blsft(8),
    MAKE_SOCK   => Math::BigInt->bone->blsft(9),
    MAKE_FIFO   => Math::BigInt->bone->blsft(10),
    MAKE_BLOCK  => Math::BigInt->bone->blsft(11),
    MAKE_SYM    => Math::BigInt->bone->blsft(12),
    # ABI version 2
    REFER => Math::BigInt->bone->blsft(13),
    # ABI version 3
    TRUNCATE => Math::BigInt->bone->blsft(14),
    # ABI version 5
    IOCTL_DEV => Math::BigInt->bone->blsft(15),
);
our %LANDLOCK_ACCESS_NET = (
    # ABI version 4
    BIND_TCP    => Math::BigInt->bone->blsft(0),
    CONNECT_TCP => Math::BigInt->bone->blsft(1),
);
our %LANDLOCK_SCOPED = (
    # ABI version 6
    ABSTRACT_UNIX_SOCKET => Math::BigInt->bone->blsft(0),
    SIGNAL               => Math::BigInt->bone->blsft(1),
);
our %LANDLOCK_RULE = (
    PATH_BENEATH => 1,
    NET_PORT     => 2,
);
our @EXPORT_OK = qw(
  get_no_new_privs
  ll_get_abi_version
  ll_create_ruleset
  ll_add_path_beneath_rule
  ll_add_net_port_rule
  ll_all_fs_access_supported
  ll_all_net_access_supported
  ll_all_scoped_supported
  ll_restrict_self
  ll_set_max_abi_version
  set_no_new_privs
  %LANDLOCK_ACCESS_FS
  %LANDLOCK_ACCESS_NET
  %LANDLOCK_SCOPED
  %LANDLOCK_RULE
);
our %EXPORT_TAGS = (
    functions => [grep { /^ll_/x } @EXPORT_OK],
    constants => [grep { /^%/x } @EXPORT_OK],
);

my %MAX_FS_SUPPORTED = (
    1 => $LANDLOCK_ACCESS_FS{MAKE_SYM},
    2 => $LANDLOCK_ACCESS_FS{REFER},
    3 => $LANDLOCK_ACCESS_FS{TRUNCATE},
    4 => $LANDLOCK_ACCESS_FS{TRUNCATE},
    5 => $LANDLOCK_ACCESS_FS{IOCTL_DEV},
    6 => $LANDLOCK_ACCESS_FS{IOCTL_DEV},
);
my %MAX_NET_SUPPORTED    = (4 => $LANDLOCK_ACCESS_NET{CONNECT_TCP},);
my %MAX_SCOPED_SUPPORTED = (6 => $LANDLOCK_SCOPED{SIGNAL},);

my ($abi_version, $max_abi_version, $fs_access_supported, $net_port_supported, $scoped_supported);

sub ll_set_max_abi_version {
    my ($max_version) = @_;
    undef $abi_version;
    return $max_abi_version = $max_version;
}

sub ll_all_fs_access_supported {
    if (!defined $fs_access_supported) {
        my $version = min($MAX_ABI_VERSION, ll_get_abi_version());
        $fs_access_supported = reduce { $a | $b } Math::BigInt->new(0),
          grep { $_ <= $MAX_FS_SUPPORTED{$version} // 0 } values %LANDLOCK_ACCESS_FS;
    }
    return $fs_access_supported;
}

sub ll_all_net_access_supported {
    if (!defined $net_port_supported) {
        my $version = ll_get_abi_version();
        $version = min(4, $version);
        $net_port_supported =
          reduce { $a | $b } Math::BigInt->new(0),
          grep { $_ <= $MAX_NET_SUPPORTED{$version} // 0 } values %LANDLOCK_ACCESS_NET;
    }
    return $net_port_supported;
}

sub ll_all_scoped_supported {
    if (!defined $scoped_supported) {
        my $version = ll_get_abi_version();
        $version = min(6, $version);
        $scoped_supported =
          reduce { $a | $b } Math::BigInt->new(0),
          grep { $_ <= $MAX_SCOPED_SUPPORTED{$version} // 0 } values %LANDLOCK_SCOPED;
    }
    return $scoped_supported;
}

sub ll_get_abi_version {
    if (!defined $abi_version) {
        if (my $nr = NR('landlock_create_ruleset')) {
            $abi_version = syscall($nr, undef, 0, $LANDLOCK_CREATE_RULESET_VERSION);
            $abi_version = min($abi_version, $max_abi_version // $abi_version);
        } else {
            $abi_version = -1;
        }
    }
    return $abi_version;
}

sub ll_create_ruleset {
    my ($fs_actions, $net_actions, $scoped_actions) = @_;
    my $allowed = Q_pack($fs_actions // ll_all_fs_access_supported());
    if (ll_get_abi_version >= 4) {
        $allowed .= Q_pack($net_actions // ll_all_net_access_supported());
    }
    if (ll_get_abi_version >= 6) {
        $allowed .= Q_pack($scoped_actions // ll_all_scoped_supported());
    }
    my $nr = NR('landlock_create_ruleset') or return;
    my $fd = syscall($nr, $allowed, length $allowed, 0);
    if ($fd >= 0) {
        return $fd;
    } else {
        return;
    }
}

sub ll_add_path_beneath_rule {
    my ($ruleset_fd, $allowed_access, $parent) = @_;

    my $fd      = ref $parent ? fileno $parent : $parent;
    my $applied = $allowed_access & ll_all_fs_access_supported();
    my $nr      = NR('landlock_add_rule') or return;
    my $result  = syscall($nr, $ruleset_fd, $LANDLOCK_RULE{PATH_BENEATH}, Q_pack($applied) . pack('l', $fd), 0);
    return ($result == 0) ? $applied : undef;
}

sub ll_add_net_port_rule {
    my ($ruleset_fd, $allowed_access, $port) = @_;

    my $applied = $allowed_access & ll_all_net_access_supported();
    my $nr      = NR('landlock_add_rule') or return;
    my $result =
      syscall($nr, $ruleset_fd, $LANDLOCK_RULE{NET_PORT}, Q_pack($applied) . Q_pack(Math::BigInt->new($port)), 0);
    return ($result == 0) ? $applied : undef;
}

sub set_no_new_privs {
    my $PR_SET_NO_NEW_PRIVS = 38;
    my $nr                  = NR('prctl') or return;
    return (syscall($nr, $PR_SET_NO_NEW_PRIVS, 1, 0, 0, 0) == 0) ? 1 : undef;
}

sub get_no_new_privs {
    my $PR_GET_NO_NEW_PRIVS = 39;
    my $nr                  = NR('prctl') or return;
    return syscall($nr, $PR_GET_NO_NEW_PRIVS, 0, 0, 0, 0);
}

sub ll_restrict_self {
    my ($ruleset_fd) = @_;
    my $nr = NR('landlock_restrict_self') or return;
    return (syscall($nr, $ruleset_fd, 0) == 0) ? 1 : undef;
}

1;
