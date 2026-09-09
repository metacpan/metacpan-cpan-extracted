# ex:ts=8 sw=4:
# $OpenBSD$
#
# Copyright (c) 2025 Dick Olsson <hi@senzilla.io>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

use v5.36;

package Fugu::Privdrop;
our $VERSION = '0.4.0';

# The English names below keep the group assignments parseable for
# the lint: PPI pairs a literal "$(" with the next "$)".
use English    qw(-no_match_vars);
use File::Path qw(make_path);
use POSIX      qw(setuid setgid);

# Fugu::Privdrop - give up root permanently.
#
# The module keeps no state and has two public class methods. A daemon
# prepares its state directory while it is still root, then drops to an
# unprivileged user for the event loop. Both steps fail loudly: a
# partial privilege drop is worse than no drop at all.

# $class->prepare_statedir(%args):
#	Create the state directory when it is absent, then give it and
#	its files to the unprivileged user. Root runs this before the
#	drop. Directories under /var/run disappear at every boot, so
#	the create step is not a first-install special case.
#
#	%args:
#		path    => $dir     # Required: the state directory
#		user    => $name    # Required: owner after the drop
#		group   => $name    # Optional: default is the user's primary group
#		mode    => $octal   # Optional: directory mode (default: 0700)
#		on_warn => sub($msg)# Optional: report a file that stays unchanged
#
#	The method returns 1 on success. It returns undef when the
#	directory itself is not usable. It dies only for a missing
#	argument or an unknown user or group.
sub prepare_statedir ( $class, %args )
{
	my $path = $args{path}
	    or die 'path parameter required for prepare_statedir';
	my $user = $args{user}
	    or die 'user parameter required for prepare_statedir';
	my $mode    = $args{mode}    // 0700;
	my $on_warn = $args{on_warn} // sub ($) { };

	my ( $uid, $gid ) = $class->_resolve( $user, $args{group} );

	if ( !-d $path ) {
		make_path( $path, { mode => $mode, error => \my $errors } );
		if ( !-d $path ) {

			# make_path reports through a structure. Reduce
			# it to one human-readable line: a daemon log is
			# not the place for a nested data dump.
			my $why = @{ $errors // [] } ? "$!" : 'unknown error';
			$on_warn->("Cannot create $path: $why");
			return;
		}
	}

	unless ( chmod $mode, $path ) {
		$on_warn->("Cannot chmod $path: $!");
		return;
	}
	unless ( chown $uid, $gid, $path ) {
		$on_warn->("Cannot chown $path: $!");
		return;
	}

	# The files inside come from an earlier run as another user, or
	# from the install. One of them that stays root-owned is a
	# warning, not a startup failure: the daemon may never need it.
	opendir my $dh, $path or do {
		$on_warn->("Cannot opendir $path: $!");
		return 1;
	};
	while ( my $entry = readdir $dh ) {
		next if $entry eq '.' || $entry eq '..';
		my $file = "$path/$entry";
		chown $uid, $gid, $file
		    or $on_warn->("Cannot chown $file: $!");
	}
	closedir $dh;

	return 1;
}

# $class->drop_privileges(%args):
#	Drop privileges from root to the specified user and group.
#	This is a common pattern in OpenBSD daemons. The daemon starts
#	as root to bind privileged ports and prepare its state. It then
#	drops to an unprivileged user for the main event loop.
#
#	%args:
#		user        => $username  # Username to drop to (required)
#		group       => $groupname # Group to drop to (optional, default: the user's primary group)
#		keep_groups => 0|1        # Keep root's supplementary groups (default: 0)
#
#	The method returns 1 for a verified drop. It returns 0 for a
#	process that was never root: the method then changes nothing,
#	and the caller can tell the no-op from a drop. It dies on
#	every error, and for a mixed root state, and for uid 0 as the
#	target.
#
#	Example:
#		# Start as root. Do the privileged operations.
#		Fugu::Privdrop->prepare_statedir(
#			path => '/var/run/myapp',
#			user => '_myapp',
#		);
#
#		# Drop privileges before you start the event loop
#		Fugu::Privdrop->drop_privileges(user => '_myapp');
#
#		# The process now runs as _myapp
#		$server->run;
sub drop_privileges ( $class, %args )
{
	my $user = $args{user}
	    or die 'user parameter required for drop_privileges';
	my $keep_groups = $args{keep_groups} // 0;

	# The guard reads both user ids. A process that was never
	# root gets 0, so a caller can tell the no-op from a drop. A
	# process with exactly one root id can call seteuid(2) and get
	# root back, and the module cannot guess which id the caller
	# wants, so that state is a hard error.
	return 0 if $< != 0 && $> != 0;
	if ( $< != 0 || $> != 0 ) {
		die 'Cannot drop privileges from a mixed root state: '
		    . "real $<, effective $>";
	}

	my ( $uid, $gid ) = $class->_resolve( $user, $args{group} );

	# A drop to root is not a drop
	if ( $uid == 0 ) {
		die 'Refusing to drop privileges to uid 0';
	}

	# Drop the group privileges first. Do this before setuid.
	unless ( POSIX::setgid($gid) ) {
		die "Cannot setgid to $gid: $!";
	}
	$REAL_GROUP_ID = $gid;

	# Set the effective GID and the supplementary groups together.
	# Perl calls setgroups(2) only for the entries after the first.
	# Thus "$gid $gid" is the documented way to reduce the list to
	# one group. To keep root's supplementary groups is fail-open,
	# so it is opt-in. The mdnsd socket group is the case that
	# needs it.
	$EFFECTIVE_GROUP_ID = $keep_groups ? "$gid" : "$gid $gid";

	# Drop the user privileges
	unless ( POSIX::setuid($uid) ) {
		die "Cannot setuid to $uid: $!";
	}
	$< = $uid;    # Set the real UID
	$> = $uid;    # Set the effective UID

	# Verify each id against the target. The four assignments
	# above report nothing: Perl performs each syscall and drops
	# the result. The checks run outside an eval on purpose: an
	# eval would swallow the die and report a successful drop for
	# a process that kept a root id.
	$class->_verify_ids( $uid, $gid, $keep_groups );

	# Try to escalate. The attempt must fail. The second
	# verification proves that the attempt changed nothing.
	POSIX::setuid(0);
	$class->_verify_ids( $uid, $gid, $keep_groups );

	return 1;
}

# $class->_verify_ids($uid, $gid, $keep_groups):
#	Verify the group ids and the user ids after the drop. The
#	group checks come first: the group calls run before the user
#	calls, and a wrong group id is the silent failure. $( and $)
#	each hold a space-separated list, so each check splits the
#	value and compares the fields as numbers. The method dies on
#	the first failure. It returns 1 otherwise.
sub _verify_ids ( $, $uid, $gid, $keep_groups )
{
	my ($rgid) = split ' ', $REAL_GROUP_ID;
	if ( $rgid != $gid ) {
		die "Privilege drop failed: real gid is $rgid, wanted $gid";
	}

	my ( $egid, @members ) = split ' ', $EFFECTIVE_GROUP_ID;
	if ( $egid != $gid ) {
		die "Privilege drop failed: effective gid is $egid, "
		    . "wanted $gid";
	}

	# getgroups(2) reports a set, not a sequence, and the set can
	# hold the effective group id. Thus every member must equal
	# $gid, and the length proves nothing. With keep_groups the
	# caller kept a list that root gave the process. The module
	# cannot know that list, so it must not verify it.
	unless ($keep_groups) {
		for my $member (@members) {
			next if $member == $gid;
			die 'Privilege drop failed: the group list '
			    . "holds $member, wanted $gid";
		}
	}

	if ( $< != $uid ) {
		die "Privilege drop failed: real uid is $<, wanted $uid";
	}
	if ( $> != $uid ) {
		die "Privilege drop failed: effective uid is $>, "
		    . "wanted $uid";
	}

	return 1;
}

# $class->_resolve($user, $group):
#	Map the names to numbers. An unknown name is a configuration
#	error that the caller cannot recover from, so it dies.
sub _resolve ( $, $user, $group )
{
	my ( $uid, $gid ) = ( getpwnam($user) )[ 2, 3 ];
	unless ( defined $uid ) {
		die "Cannot get UID for user '$user': $!";
	}

	if ( defined $group ) {
		$gid = getgrnam($group);
		unless ( defined $gid ) {
			die "Cannot get GID for group '$group': $!";
		}
	}

	return ( $uid, $gid );
}

1;
