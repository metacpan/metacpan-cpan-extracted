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

package Doit::Deb; # Convention: all commands here should be prefixed with 'deb_'

use strict;
use vars qw($VERSION);
$VERSION = '0.02';

use Doit::Util 'get_sudo_cmd';

sub new { bless {}, shift }
sub functions { qw(deb_install_packages deb_missing_packages deb_install_key) }

sub deb_install_packages {
    my($self, @packages) = @_;
    my @missing_packages = $self->deb_missing_packages(@packages); # XXX cmd vs. info???
    if (@missing_packages) {
	$self->system(get_sudo_cmd(), 'apt-get', '-y', 'install', @missing_packages);
    }
    @missing_packages;
}


sub deb_missing_packages {
    my($self, @packages) = @_;

    my @missing_packages;

    if (@packages) {
	require IPC::Open3;
	require Symbol;

	my %seen_packages;
	my %required_version;
	for my $package (@packages) {
	    if (ref $package eq 'ARRAY') {
		my($package_name, $package_version) = @$package;
		$required_version{$package_name} = $package_version;
		$package = $package_name;
	    }
	}
	my @cmd = ('dpkg-query', '-W', '-f=${Package}\t${Status}\t${Version}\n', @packages);
	my $err = Symbol::gensym();
	my $fh;
	my $pid = IPC::Open3::open3(undef, $fh, $err, @cmd)
	    or die "Error running '@cmd': $!";
	while(<$fh>) {
	    chomp;
	    if (m{^([^\t]+)\t([^\t]+)\t([^\t]*)$}) {
		if ($2 ne 'install ok installed') {
		    push @missing_packages, $1;
		}
		if ($required_version{$1} && $required_version{$1} ne $3) {
		    push @missing_packages, $1;
		}
		$seen_packages{$1} = 1;
	    } else {
		warn "ERROR: cannot parse $_, ignore line...\n";
	    }
	}
	waitpid $pid, 0;
	for my $package (@packages) {
	    if (!$seen_packages{$package}) {
		push @missing_packages, $package;
	    }
	}
    }
    @missing_packages;
}

sub deb_install_key {
    my($self, %opts) = @_;
    my $url       = delete $opts{url};
    my $keyserver = delete $opts{keyserver};
    my $key       = delete $opts{key};
    die "Unhandled options: " . join(" ", %opts) if %opts;

    if (!$url) {
	if (!$keyserver) {
	    die "keyserver is missing";
	}
	if (!$key) {
	    die "key is missing";
	}
    } else {
	if ($keyserver) {
	    die "Don't define both url and keyserver";
	}
    }

    my $found_key;
    if ($key) {
	$key =~ s{\s}{}g; # convenience: strip spaces from key ('apt-key finger' returns them with spaces)
	local $ENV{LC_ALL} = 'C';
	# XXX If run with $sudo, then this will emit warnings in the form
	#   gpg: WARNING: unsafe ownership on configuration file `$HOME/.gnupg/gpg.conf'
	# Annoying, but harmless. Could be workarounded by specifying
	# '--homedir=/root/.gpg', but this would create gpg files under ~root. Similar
	# if using something like
	#   local $ENV{HOME} = (getpwuid($<))[7];
	# Probably better would be to work with privilege escalation and run
	# this command as normal user (to be implemented).
	open my $fh, '-|', 'gpg', '--keyring', '/etc/apt/trusted.gpg', '--list-keys', '--fingerprint', '--with-colons'
	    or die "Running gpg failed: $!";
	while(<$fh>) {
	    if (m{^fpr:::::::::\Q$key\E:$}) {
		$found_key = 1;
		last;
	    }
	}
	close $fh
	    or die "Running gpg failed: $!";
    }

    my $changed = 0;
    if (!$found_key) {
	if ($keyserver) {
	    $self->system(get_sudo_cmd(), 'apt-key', 'adv', '--keyserver', $keyserver, '--recv-keys', $key);
	} elsif ($url) {
	    $self->run(['curl', '-fsSL', $url], '|', [get_sudo_cmd(), 'apt-key', 'add', '-']);
	} else {
	    die "Shouldn't happen";
	}
	$changed = 1;
    }
    $changed;
}


1;

__END__
