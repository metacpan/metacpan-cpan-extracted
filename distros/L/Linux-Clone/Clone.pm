=head1 NAME

Linux::Clone - an interface to the linux clone, unshare, setns, pivot_root and kcmp syscalls

=head1 SYNOPSIS

 use Linux::Clone;

=head1 DESCRIPTION

This module exposes the linux clone(2), unshare(2) and related syscalls to
Perl.

=over 4

=item $retval = unshare $flags

The following CLONE_ flag values (without CLONE_ prefix) are supported for
unshare, if found, in this release. See the documentation for unshare(2)
for more info on what they do:

   Linux::Clone::FILES
   Linux::Clone::FS
   Linux::Clone::NEWNS   (in unshare, implies FS)
   Linux::Clone::VM      (in unshare, implies SIGHAND)
   Linux::Clone::THREAD  (in unshare, implies VM, SIGHAND)
   Linux::Clone::SIGHAND
   Linux::Clone::SYSVSEM
   Linux::Clone::NEWUSER (in unshare, implies CLONE_THREAD)
   Linux::Clone::NEWPID
   Linux::Clone::NEWUTS
   Linux::Clone::NEWIPC
   Linux::Clone::NEWNET
   Linux::Clone::NEWCGROUP

Example: unshare the network namespace and prove that by calling ifconfig,
showing only an unconfigured lo interface.

   Linux::Clone::unshare Linux::Clone::NEWNET
      and "unshare: $!";
   system "ifconfig -a";

Example: unshare the network namespace, initialise the loopback interface,
create a veth interface pair, put one interface into the parent processes
namespace (use ifconfig -a from another shell), configure the other
interface with 192.168.99.2 -> 192.168.99.1 and start a shell.

   use Linux::Clone;

   # unshare our network namespace
   Linux::Clone::unshare Linux::Clone::NEWNET
     and "unshare: $!";

   my $ppid = getppid;

   system "
      # configure loopback interface
      ip link set lo up
      ip route add 127.0.0.0/8 dev lo

      # create veth pair
      ip link add name veth_master type veth peer name veth_slave

      # move veth_master to our parent process' namespace
      ip link set veth_master netns $ppid

      # configure the local interface
      ip link set veth_slave up
      ip addr add 192.168.99.2/32 dev veth_slave
      ip route add 192.168.99.1/32 dev veth_slave
   ";

   print <<EOF;
   say hi to your new network namespace, use exit to return.

   try this from another shell to get networking up:

   ip link set veth_master up
   ip addr add 192.168.99.1/32 dev veth_master
   ip route add 192.168.99.2/32 dev veth_master

   EOF
   system "bash";

Example: unshare the filesystem namespace and make a confusing bind mount
only visible to the current process.

   use Linux::Clone;

   Linux::Clone::unshare Linux::Clone::NEWNS
      and die "unshare: $!";

   # now bind-mount /lib over /etc and ls -l /etc - scary
   system "mount -n --bind /lib /etc";
   system "ls -l /etc";

=item $retval = Linux::Clone::clone $coderef, $stacksize, $flags[, $ptid, $tls, $ctid]

Clones a new process as specified via C<$flags> and calls C<$coderef>
without any arguments (a closure might help you if you need to pass
arguments without global variables). The return value from coderef is
returned to the system.

The C<$stacksize> specifies how large a stack to allocate for the
child. If it is C<0>, then a default stack size (currently 4MB) will be
allocated. There is currently no way to free this area again in the child.

C<$ptid>, if specified, will receive the thread id, C<$tls>, if specified,
must contain a C<struct user_desc> and C<$ctid> is currently totally
unsupported and must not be specified.

Since this call basically bypasses both perl and your libc (for example,
C<$$> might reflect the parent I<or> child pid in the child), you need to
be very careful when using this call, which means you should probably have
a very good understanding of perl memory management and how fork and clone
work.

The following flags are supported for clone, in addition to all flags
supported by C<unshare>, above, and a signal number. When in doubt, refer
to the clone(2) manual page.

   Linux::Clone::PTRACE
   Linux::Clone::VFORK
   Linux::Clone::SETTLS         (not yet implemented)
   Linux::Clone::PARENT_SETTID  (not yet implemented)
   Linux::Clone::CHILD_SETTID   (not yet implemented)
   Linux::Clone::CHILD_CLEARTID (not yet implemented)
   Linux::Clone::DETACHED
   Linux::Clone::UNTRACED
   Linux::Clone::IO

Note that for practical reasons you basically must not use
C<Linux::Clone::VM> or C<Linux::Clone::VFORK>, as perl is unlikely to cope
with that.

This is the glibc clone call, it cannot be used to emulate fork.

Example: do a fork-like clone, sharing nothing, slightly confusing perl
and your libc, and exit immediately.

   my $pid = Linux::Clone::clone sub { warn "in child"; 77 }, 0, POSIX::SIGCHLD;

=item Linux::Clone::setns $fh_or_fd[, $nstype]

Calls setns(2) on the file descriptor (or file handle) C<$fh_or_fd>. If
C<$nstype> is missing, then C<0> is used.

The argument C<$nstype> can be C<0>, C<Linux::Clone::NEWIPC>,
C<Linux::Clone::NEWNET>, C<Linux::Clone::NEUTS>, C<Linux::Clone::NEWCGROUP>,
C<Linux::Clone::NEWNS>, C<Linux::Clone::NEWPID> or C<Linux::Clone::NEWUSER>.

=item Linux::Clone::pivot_root $new_root, $old_root

Calls pivot_root(2) - refer to its manpage for details.

=item Linux::Clone::kcmp $pid1, $pid2, $type[, $idx1, $idx2]

Calls kcmp(2) - refer to its manpage for details on operations.

The following C<$type> constants are available if the kcmp syscall number
was available during compilation:

C<Linux::Clone::KCMP_FILE>, C<Linux::Clone::KCMP_VM>, C<Linux::Clone::KCMP_FILES>,
C<Linux::Clone::KCMP_FS>, C<Linux::Clone::KCMP_SIGHAND>, C<Linux::Clone::KCMP_IO> and
C<Linux::Clone::KCMP_SYSVSEM>.


=back

=cut

package Linux::Clone;

# use common::sense;

BEGIN {
   our $VERSION = '1.2';

   require XSLoader;
   XSLoader::load (__PACKAGE__, $VERSION);
}

1;

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

