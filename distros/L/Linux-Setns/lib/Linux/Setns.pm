package Linux::Setns;

use 5.010001;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Linux::Setns ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	setns CLONE_ALL CLONE_NEWNS CLONE_NEWIPC CLONE_NEWNET CLONE_NEWUTS CLONE_NEWPID CLONE_NEWUSER CLONE_NEWCGROUP
);

our $VERSION = '2.1';

use constant {
	CLONE_ALL => 0,
	CLONE_NEWNS => 0x00020000,
	CLONE_NEWIPC => 0x08000000,
	CLONE_NEWNET => 0x40000000,
	CLONE_NEWUTS => 0x04000000,
	CLONE_NEWPID => 0x20000000,
	CLONE_NEWUSER => 0x10000000,
	CLONE_NEWCGROUP => 0x02000000
};

require XSLoader;
XSLoader::load('Linux::Setns', $VERSION);

# Preloaded methods go here.

sub setns {
	my $ret = setns_wrapper($_[0], $_[1]);
	if ($ret == 0) {
		return 1;
	} elsif ($ret == 1) {
		print STDERR "Error: setns() The calling thread did not have the required privilege (CAP_SYS_ADMIN) for this operation\n";
	} elsif ($ret == 2) {
		print STDERR "Error: setns() Unable to open file $_[0]\n";
	} elsif ($ret == 9) {
		print STDERR "Error: setns() FD is not a valid file descriptor\n";
	} elsif ($ret == 12) {
		print STDERR "Error: setns() Cannot allocate sufficient memory to change the specified namespace\n";
	} elsif ($ret == 22) {
		print STDERR "Error: setns() FD refers to a namespace whose type does not match that specified in nstype, or there is problem with reassociating the the thread with the specified namespace\n";
	}
	return 0;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Linux::Setns - Perl extension for switching the current process namespace to another namespace pointed by a path to the ns file descriptor.

=head1 SYNOPSIS

	use Linux::setns qw(setns CLONE_ALL CLONE_NEWIPC CLONE_NEWNET CLONE_NEWUTS CLONE_NEWUSER CLONE_NEWPID);

	die "setns() requires root privileges\n" if $>;

	setns("/proc/PID/ns/mnt", CLONE_ALL);
	# now your process is in the same namespaces(IPC,NET,UTS,PID,USER,MOUNT) as the /proc/PID/ns/mnt 

	# If you want to change only one of your namespaces you can use any of the bellow examples:

	# Switch your current Mount namespace to the one pointed by /proc/PID/ns/mnt
	setns("/proc/PID/ns/mnt", CLONE_NEWNS);

	# Switch your current IPC namespace to the one pointed by /proc/PID/ns/ipc
	setns("/proc/PID/ns/ipc", CLONE_NEWIPC);

	# Switch your current Network namespace to the one pointed by /proc/PID/ns/net
	setns("/proc/PID/ns/net", CLONE_NEWNET);

	# Switch your current UTS namespace to the one pointed by /proc/PID/ns/uts
	setns("/proc/PID/ns/uts", CLONE_NEWUTS);

	# Switch your current Pid namespace to the one pointed by /proc/PID/ns/pid
	setns("/proc/PID/ns/pid", CLONE_NEWPID);

	# Switch your current User namespace to the one pointed by /proc/PID/ns/user
	setns("/proc/PID/ns/user", CLONE_NEWUSER);

	# Switch your current Cgroup namespace to the one pointed by /proc/PID/ns/user
	setns("/proc/PID/ns/user", CLONE_NEWCGROUP);

=head1 DESCRIPTION

This trivial module provides interface to the Linux setns system call. It
also provides the CLONE_* constants that are used to specify which kind of
namespace you are entering. Also a new CLONE_ALL constat is provided so you
can join/switch to any type of namespace.

The setns system call allows a process to 'join/switch' one of its namespaces
to namespaces pointed by a file descriptor(usually located in /proc/PID/ns/{ipc,mnt,net,pid,user,uts}).

Note: keep in mind that using any specific CLONE_NEW* constant will fail if the FD path 
you gave is not of that type.

RETRUN VALUE
	1 on success
	0 on failure


=head2 EXPORT

 setns			- the subroutine

 CLONE_ALL		- flag that tells that the path can be of any namespace type
 CLONE_NEWNS	- when this flag is used the path must be from another Mount namespace
 CLONE_NEWIPC	- when this flag is used the path must be from another IPC namespace
 CLONE_NEWNET	- when this flag is used the path must be from another Network namespace
 CLONE_NEWUTS	- when this flag is used the path must be from another UTS namespace
 CLONE_NEWPID	- when this flag is used the path must be from another PID namespace
 CLONE_NEWUSER	- when this flag is used the path must be from another User namespace
 CLONE_NEWCGROUP - when this flag is used the path must be from another Cgroup namespace


=head1 SEE ALSO

setns(s) Linux man page.

=head1 AUTHOR

Marian HackMan Marinov, E<lt>hackman@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017-2017 by Marian HackMan Marinov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
