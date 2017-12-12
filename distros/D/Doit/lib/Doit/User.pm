# -*- perl -*-

#
# Author: Slaven Rezic
#
# Copyright (C) 2017 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: slaven@rezic.de
# WWW:  http://www.rezic.de/eserte/
#

package Doit::User;

use strict;
use warnings;
our $VERSION = '0.031';

use Exporter 'import';
our @EXPORT_OK = qw(as_user);

use Doit::Log;

{
    my(%uid_cache, %gid_cache, %homedir_cache);

    sub as_user (&$;@) {
	my($code, $user, %opts) = @_;
	my $cache = exists $opts{cache} ? delete $opts{cache} : 1;
	error "Unhandled options: " . join(" ", %opts) if %opts;

	if ($> != 0) {
	    error "as_user works only for root";
	}

	my($uid, $gid, $homedir);
	if ($cache) {
	    ($uid, $gid, $homedir) = ($uid_cache{$user}, $gid_cache{$user}, $homedir_cache{$user});
	}
	if (!defined $uid || !defined $gid || !defined $homedir) {
	    ($uid, $gid, $homedir) = ((getpwnam $user)[2,3,7]);
	    if (!defined $uid) {
		error "Cannot get uid of user '$user'";
	    }
	    ($gid) = $gid =~ m{^(\d+)}; # only the first one
	    if ($cache) {
		$uid_cache{$user}     = $uid;
		$gid_cache{$user}     = $gid;
		$homedir_cache{$user} = $homedir;
	    }
	}

	local $( = $gid; # change first the gid, then the uid!
	local $) = $gid;
	local $< = $uid;
	local $> = $uid;
	local $ENV{HOME} = $homedir;
	local $ENV{USER} = $user;
	local $ENV{LOGNAME} = $user;

	$code->();
    }
}

sub new { bless {}, shift }
sub functions { qw(user_account user_add_user_to_group) }

sub user_account {
    my($self, %opts) = @_;

    error "Only supported for linux and freebsd" if $^O !~ /^(linux|freebsd)$/;

    my $username = delete $opts{username};
    if (!defined $username) { error "'username' is mandatory" }
    my $ensure   = delete $opts{ensure} || 'present';
    my $uid      = delete $opts{uid};
    my @groups   = @{ delete $opts{groups} || [] };
    my $home     = delete $opts{home};
    my $shell    = delete $opts{shell};
    my @ssh_keys = @{ delete $opts{ssh_keys} || [] };
    ## XXX maybe support some day (taken from Rex):
    # expire - Date when the account will expire. Format: YYYY-MM-DD
    # password - Cleartext password for the user.
    # crypt_password - Crypted password for the user. Available on Linux, OpenBSD and NetBSD.
    # system - Create a system user.
    # create_home - If the home directory should be created. Valid parameters are TRUE, FALSE.
    # comment
    error "Unhandled options: " . join(" ", %opts) if %opts;

    my($got_username, $got_passwd, $got_uid, $got_gid, $got_quota,
       $got_comment, $got_gcos, $got_home, $got_shell, $got_expire) = getpwnam($username);

    if ($ensure eq 'absent') {
	if (defined $got_username) {
	    my $sys_userdel =
		(    $^O eq 'linux'   ? sub { $self->system('userdel', $username) } # XXX what about --remove?
		   : $^O eq 'freebsd' ? sub { $self->system('pw', 'userdel', $username) } # XXX what about -r?
		   :                    sub { error "userdel NYI for $^O" }
		);
	    $sys_userdel->();
	}
    } elsif ($ensure ne 'present') {
	error "Valid values for 'ensure': 'absent', 'present' (got: '$ensure')\n";
    } else {
	my($cmd, @args);
	if (defined $got_username) {
	    $cmd = 'usermod';
	} else {
	    $cmd = 'useradd';
	}
	if (defined $uid &&
	    (
	        (defined $got_uid && $got_uid != $uid)
	     || (!defined $got_uid)
	    )
	   ) {
	    push @args, ($^O eq 'linux' ? '--uid' : $^O eq 'freebsd' ? '-u' : error "NYI"), $uid;
	}
	if ($cmd eq 'useradd') {
	    if ($^O eq 'linux') {
		push @args, '--user-group';
	    } elsif ($^O eq 'freebsd') {
		# done automatically
	    }
	}
	## XXX?
	#if (defined $uid &&
	#    (
	#        (defined $got_gid && $got_gid != $uid)
	#     || (!defined $got_gid)
	#    )
	#   ) {
	#    push @args, '--gid', $uid; # XXX what if uid should be != gid?
	#}
	if (defined $home &&
	    (
	        (defined $got_home && $got_home ne $home)
	     || (!defined $got_home)
	    )
	   ) {
	    push @args, ($^O eq 'linux'   ? ('--home', $home, ($cmd eq 'usermod' ? '--move-home' : '--create-home')) :
			 $^O eq 'freebsd' ? ('-d',     $home, '-m') :
			 error "NYI");
	} elsif ($cmd eq 'useradd') {
	    push @args, ($^O eq 'linux'   ? ($cmd eq 'usermod' ? '--move-home' : '--create-home') :
			 $^O eq 'freebsd' ? ('-m') :
			 error "NYI");
	}
	if (defined $shell &&
	    (
	        (defined $got_shell && $got_shell ne $shell)
	     || (!defined $got_shell)
	    )
	   ) {
	    push @args, ($^O eq 'linux'   ? '--shell' :
			 $^O eq 'freebsd' ? '-s' :
			 error "NYI"), $shell;
	}
	if (@groups) {
	    my @got_groups = sort _get_user_groups($username);
	    my @want_groups = sort @groups;
	    if ("@want_groups" ne "@got_groups") {
		push @args, ($^O eq 'linux'   ? '--groups' :
			     $^O eq 'freebsd' ? '-G' :
			     error "NYI"), join(",", @groups);
	    }
	}
	if ($cmd eq 'useradd' || @args) {
	    local $ENV{PATH} = "/usr/sbin:$ENV{PATH}";
	    if      ($^O eq 'linux') {
		$self->system($cmd, @args, $username);
	    } elsif ($^O eq 'freebsd') {
		$self->system('pw', $cmd, @args, '-n', $username);
	    }
	}

	if (!$self->is_dry_run) {
	    ($got_username, $got_passwd, $got_uid, $got_gid, $got_quota,
	     $got_comment, $got_gcos, $got_home, $got_shell, $got_expire) = getpwnam($username);
	    if (!defined $got_username) {
		error "Something went wrong: $cmd did not fail, but user '$username' does not exist";
	    }
	} else {
	    if (defined $home) {
		$got_home = $home;
	    } else {
		$got_home = "/home/$username";
	    }
	}

	if (@ssh_keys) {
	    $self->mkdir("$got_home/.ssh");
	    $self->chmod(0700, "$got_home/.ssh");
	    $self->chown($username, $username, "$got_home/.ssh");
	    $self->create_file_if_nonexisting("$got_home/.ssh/authorized_keys");
	    $self->chmod(0600, "$got_home/.ssh/authorized_keys");
	    $self->chown($username, $username, "$got_home/.ssh/authorized_keys");
	    $self->change_file("$got_home/.ssh/authorized_keys",
			       (map { +{ add_if_missing => $_ } } @ssh_keys),
			      );
	}
    }
}

sub user_add_user_to_group {
    my($self, %opts) = @_;
    my $username = delete $opts{username};
    if (!defined $username) { error "username is mandatory" }
    my $group = delete $opts{group};
    if (!defined $group) { error "group is mandatory" }
    my %user_groups = map{($_,1)} _get_user_groups($username);
    my $changes = 0;
    if (!$user_groups{$group}) {
	if      ($^O eq 'linux') {
	    $self->system('usermod', '--append', '--groups', $group, $username);
	    $changes = 1;
	} elsif ($^O eq 'freebsd') {
	    $self->system('pw', 'groupmod', '-m', $username, '-n', $group);
	    $changes = 1;
	} else {
	    error "user_add_user_to_group NYI for $^O";
	}
    }
    $changes;
}

sub _get_user_groups {
    my $username = shift;
    my @groups;
    require POSIX;
    require List::Util;
    while (my($gname,undef,undef,$members) = getgrent) {
	next if $gname eq $username; # don't deal with primary groups
	if (List::Util::first(sub { $_ eq $username }, split /\s+/, $members)) {
	    push @groups, $gname;
	}
    }
    endgrent;
    @groups;
}

1;

__END__
