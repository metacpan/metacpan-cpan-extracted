# -*- perl -*-

#
# Author: Slaven Rezic
#
# Copyright (C) 2019 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: slaven@rezic.de
# WWW:  http://www.rezic.de/eserte/
#

package Doit::Bootstrap;

use strict;
use warnings;
our $VERSION = '0.01';

use Doit::Log;

sub _bootstrap_perl {
    my($doit_ssh, %opts) = @_;
    my $dry_run = delete $opts{dry_run};
    die 'Unhandled options: ' . join(' ', %opts) if %opts;

    my $ssh = $doit_ssh->ssh;

    if ($ssh->test('which perl > /dev/null')) {
	return 1;
    }
    error "Running remote command 'which perl' failed: " . $ssh->error
	if $ssh->error;

    chomp(my $uname = $ssh->capture('uname'));

    my $installer;
    if ($uname eq 'Linux') {
	my @distro_tokens;
	for my $line ($ssh->capture('cat /etc/os-release')) {
	    if ($line =~ m{^ID(?:_LIKE)=\"(.*)\"}) {
		push @distro_tokens, split /\s+/, $1;
	    }
	}
	for my $distro_token (@distro_tokens) {
	    if ($distro_token =~ m{^(centos|rhel|fedora)$}) {
		$installer = 'yum';
	    } elsif ($distro_token =~ m{^(debian|ubuntu)$}) {
		$installer = 'apt-get';
	    }
	    last if $installer;
	}
    } else {
	if (($uname||'') eq '') {
	    error "Cannot detect remote operating system --- no 'uname' installed?";
	} else {
	    error "No bootstrapping implementation for '$uname' --- please install perl manually";
	}
    }

    if (!$installer) {
	error "Cannot find a suitable installer --- please install perl manually";
    }

    my @cmds;
    if ($installer eq 'yum') {
	push @cmds, ['yum', 'install', '-y', 'perl'];
    } elsif ($installer eq 'apt-get') {
	push @cmds, (
		     ['apt-get', 'update', '-y'],
		     ['apt-get', 'install', '-y', 'perl'],
		    );
    } else {
	error "No support for installer '$installer'";
    }

    for my $cmd (@cmds) {
	if ($dry_run) {
	    info "@$cmd (dry-run)";
	} else {
	    info "@$cmd";
	    $ssh->system(@$cmd);
	}
    }

    if ($dry_run) {
	info "perl not installed (dry-run), subsequent execution will likely fail";
    } else {
	if ($ssh->test('which perl > /dev/null')) {
	    return 1;
	}
	error "perl installation failed";
    }
}

1;

__END__
