package Linux::Landlock;

=head1 NAME

Linux::Landlock - A higher level interface to the Linux Landlock API

=head1 DESCRIPTION

Landlock is a sandboxing feature specific to Linux that allows a process to
restrict its own access to the file system.
Once set, restrictions cannot be undone and they are inherited by all future
child processes.

Since the restrictions are set at runtime, from within the process itself,
you can take into account dynamic information from your configuration.

For example, a server that is supposed to serve files from a specific directory
can restrict itself to that directory and its subdirectories to mitigate any bugs
allowing directory traversal attacks. This is much less intrusive than chroot
and does not require root privileges.

This module provides an object-oriented interface to the Linux Landlock API.
It uses the lower-level interface provided by L<Linux::Landlock::Direct>.

See L<https://docs.kernel.org/userspace-api/landlock.html> for more information
about Landlock.

=head1 METHODS

=head1 SYNOPSIS

      use Linux::Landlock;

      my $ruleset = Linux::Landlock->new(supported_abi_version => 4); # this can die
      $ruleset->add_path_rule('/etc/fstab', qw(read_file));
      $ruleset->add_net_rule(22222, qw(bind_tcp));
      $ruleset->apply();

      print -r '/etc/fstab' ? "allowed\n" : "not allowed\n"; # allowed ...
      IO::File->new('/etc/fstab', 'r') and print "succeeded: $!\n"; # ... and opening works
      print -r '/etc/passwd' ? "allowed\n" : "not allowed\n"; # allowed ...
      IO::File->new('/etc/passwd', 'r') or print "failed\n"; # ... but opening fails because of Landlock

      system('/usr/bin/cat /etc/fstab') and print "failed: $!\n"; # this fails, because we cannot execute cat

      IO::Socket::INET->new(LocalPort => 33333, Proto => 'tcp') or print "failed: $!\n"; # failed
      IO::Socket::INET->new(LocalPort => 22222, Proto => 'tcp') and print "succeeded\n"; # succeeded

=over 1

=item new([handled_fs_actions => \@fs_actions, handled_net_actions => \@net_actions, restricted_ipc => \@ipc_actions, die_on_unsupported => 1|0])

Create a new L<Linux::Landlock> instance.

C<supported_abi_version> indicates the highest ABI version you want to use. It is highly
recommended to set this, typically to the version you are testing with.
The reason is that restrictions added by newer ABI versions might break you program.
If not set, the running kernel's ABI version is used.

C<handled_fs_actions> and C<handled_net_actions> restrict the set of actions that can be used in rules and that
will be prevented if not allowed by any rule. By default, all actions supported by the kernel and known to this
module are covered. This should usually not be changed.

C<restricted_ipc> lists the IPC mechanisms this ruleset should restrict. By default, all IPC mechanisms are
restricted. Note that this cannot be changed after calling new().

Possible IPC mechanisms are:

    abstract_unix_socket
    signal

If C<die_on_unsupported> is set to a true value, the module will die if an unsupported access right is requested.
Otherwise, access rights will be set on a best-effort basis, as intended by the upstream Landlock API design. This
option should usually not be used.

=item apply()

Apply the ruleset to the current process and all future children. Dies on error.

=item get_abi_version()

Int, returns the ABI version of the Landlock kernel module. Can be called as a static method.
A version < 1 means that Landlock is not available.

=item add_path_beneath_rule($path, @allowed)

Add a rule to the ruleset that allows the specified access to the given path.
C<$path> can be a file or a directory. C<@allowed> is a list of access rights to allow.

Possible access rights are:

    execute
    write_file
    read_file
    read_dir
    remove_dir
    remove_file
    make_char
    make_dir
    make_reg
    make_sock
    make_fifo
    make_block
    make_sym
    refer
    truncate
    ioctl_dev

See  L<https://docs.kernel.org/userspace-api/landlock.html> for all possible access rights.

Note that B<refer> is special. It is only available starting at ABI version 2, but its restrictions
are also applied with ABI version 1.

This method dies on error. Errors are: non-existing or non-accessible paths and empty rules.
If C<die_on_unsupported> is used, it will also die if the rules are not supported by the
current kernel.

B<Beware>: While the API accepts a path or user space file descriptor, the rule is actually
checked against the corresponding, kernel internal file system object. This means that you
will lose access if a path or directory you allowed access to is renamed or replaced.

=item add_net_port_rule($port, @allowed)

Add a rule to the ruleset that allows the specified access to the given port.
C<$port> is allowed port, C<@allowed> is a list of allowed operations.

Possible operations are:

    bind_tcp
    connect_tcp

=item allow_perl_inc_access()

A convenience method that adds rules to allow reading files and directories in
all directories in C<@INC>.
This will not allow access to ".", even if it is in C<@INC>.

=back

=head1 LIMITATIONS

This module requires a Linux system supporting the Landlock functionality. As of
2024, this is the case for almost all distributions, however, the version of the
available Landlock ABI varies.

Notably, the C<TRUNCATE> access right is only supported by the kernel since ABI
version 3 (kernel version 6.2 or newer, unless backported).

Network functionality is only available since ABI version 4.

Also keep in mind, that some Perl modules can implicitly rely on operations
that are restricted by the Landlock rules you apply, so test carefully.

=head1 AUTHOR

Marc Ballarin, <ballarin.marc@gmx.de>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024-2025 by Marc Ballarin

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

use strict;
use warnings;
use POSIX      ();
use List::Util qw(reduce);
use Math::BigInt;
use Linux::Landlock::Direct qw(
  %LANDLOCK_ACCESS_FS
  %LANDLOCK_ACCESS_NET
  %LANDLOCK_SCOPED
  ll_add_path_beneath_rule
  ll_add_net_port_rule
  ll_all_fs_access_supported
  ll_all_net_access_supported
  ll_all_scoped_supported
  ll_restrict_self
  ll_get_abi_version
  ll_create_ruleset
  ll_set_max_abi_version
  set_no_new_privs
);

our $VERSION = '0.009003';

sub new {
    my ($class, %args) = @_;

    if ($args{supported_abi_version}) {
        ll_set_max_abi_version($args{supported_abi_version});
    }
    my $kernel_abi_version = ll_get_abi_version();
    my $self = bless {}, $class;
    $self->{die_on_unsupported} = $args{die_on_unsupported};
    if ($kernel_abi_version < 1) {
        warn "Landlock is not available\n";
        return $self;
    }
    $self->{_rule_fd} = ll_create_ruleset(
        __reduce_path_beneath_rules($args{handled_fs_actions}),
        __reduce_net_port_rules($args{handled_net_actions}),
        __reduce_ipc_scopes($args{restricted_ipc}),
    );
    return $self;
}

sub _is_available {
    my ($self) = @_;
    if (!defined $self->{_rule_fd}) {
        if ($self->{die_on_unsupported}) {
            die "Landlock is not available\n";
        }
    } else {
        return 1;
    }
}

sub apply {
    my ($self) = @_;

    if ($self->_is_available()) {
        set_no_new_privs()                  or die "Failed to set no_new_privs: $!\n";
        ll_restrict_self($self->{_rule_fd}) or die "Failed to restrict self: $!\n";
        return 1;
    } else {
        return;
    }
}

sub get_abi_version {
    return ll_get_abi_version();
}

sub add_path_beneath_rule {
    my ($self, $path, @allowed) = @_;

    if ($self->_is_available()) {
        my $is_dir = -d $path;
        if (my $fd = $is_dir ? POSIX::opendir($path) : POSIX::open($path)) {
            my $allowed = __reduce_path_beneath_rules(\@allowed);
            my $result  = ll_add_path_beneath_rule($self->{_rule_fd}, $allowed, $fd);
            if ($is_dir) {
                POSIX::closedir($fd);
            } else {
                POSIX::close($fd);
            }
            die "Failed to add rule: $!\n" unless $result;
            if ($result != $allowed && $self->{die_on_unsupported}) {
                die "Unsupported access rights: $allowed vs. $result\n";
            }
            return $result;
        } else {
            die "Failed to open $path: $!\n";
        }
    }
}

sub __reduce_path_beneath_rules {
    if (defined $_[0] && @{$_[0]}) {
        return reduce { $a | $b } Math::BigInt->bzero,
          map { $LANDLOCK_ACCESS_FS{ uc $_ } // die "invalid filesystem access right: '$_'\n" } @{$_[0]};
    } elsif (defined $_[0]) {
        return Math::BigInt->bzero;
    } else {
        return ll_all_fs_access_supported();
    }
}

sub __reduce_net_port_rules {
    if (defined $_[0] && @{$_[0]}) {
        return reduce { $a | $b } Math::BigInt->bzero,
          map { $LANDLOCK_ACCESS_NET{ uc $_ } // die "invalid network access right: '$_'\n" } @{$_[0]};
    } elsif (defined $_[0]) {
        return Math::BigInt->bzero;
    } else {
        return ll_all_net_access_supported();
    }
}

sub __reduce_ipc_scopes {
    if (defined $_[0] && @{$_[0]}) {
        return reduce { $a | $b } Math::BigInt->bzero,
          map { $LANDLOCK_SCOPED{ uc $_ } // die "invalid IPC mechanism: '$_'\n" } @{$_[0]};
    } elsif (defined $_[0]) {
        return Math::BigInt->bzero;
    } else {
        return ll_all_scoped_supported();
    }
}

sub add_net_port_rule {
    my ($self, $port, @allowed) = @_;

    if ($self->_is_available()) {
        my $allowed = __reduce_net_port_rules(\@allowed);
        my $result = ll_add_net_port_rule($self->{_rule_fd}, $allowed, $port) or die "Failed to add rule: $!\n";
        if ($result != $allowed && $self->{die_on_unsupported}) {
            die "Unsupported access rights: $allowed vs. $result\n";
        }
        return $result;
    }
}

sub allow_perl_inc_access {
    my ($self) = @_;

    my $result = 1;
    for (@INC) {
        next unless -d $_;
        next if $_ eq '.';
        $result &&= $self->add_path_beneath_rule($_, qw(read_file read_dir));
    }
    return $result;
}

sub allow_std_dev_access {
    my ($self) = @_;

    my $result = 1;
    for (qw(null zero random urandom)) {
        $result &&= $self->add_path_beneath_rule("/dev/$_", qw(read_file write_file));
    }
    return $result;
}

sub DESTROY {
    my ($self) = @_;
    POSIX::close($self->{_rule_fd}) if defined $self->{_rule_fd};
    return;
}

1;
