# -*- perl -*-

#
# Author: Slaven Rezic
#
# Copyright (C) 2017,2018,2020 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: slaven@rezic.de
# WWW:  http://www.rezic.de/eserte/
#

package Doit::Rpm;

use Doit::Log;

use strict;
use warnings;
our $VERSION = '0.012';

sub new { bless {}, shift }
sub functions { qw(rpm_install_packages rpm_missing_packages rpm_enable_repo) }

sub rpm_install_packages {
    my($self, @packages) = @_;
    my @missing_packages = $self->rpm_missing_packages(@packages);
    if (@missing_packages) {
	$self->system('yum', '-y', 'install', @missing_packages);
    }
    @missing_packages;
}

sub rpm_missing_packages {
    my($self, @packages) = @_;

    my @missing_packages;

    if (@packages) {
	my @cmd = ('env', 'LC_ALL=C', 'rpm', '--query', @packages);
	open my $fh, '-|', @cmd
	    or error "Error running '@cmd': $!";
	while(<$fh>) {
	    if (m{^package (\S+) is not installed}) {
		push @missing_packages, $1;
	    }
	}
    }

    @missing_packages;
}

sub rpm_enable_repo {
    my($self, $repo, %opts) = @_;
    my $do_update = delete $opts{update}; $do_update = 1 if !defined $do_update;
    error "Unhandled options: " . join(" ", %opts) if %opts;

    for my $installed_repo_line (split /\n/, $self->info_qx({quiet=>1}, qw(yum repolist))) {
	my($installed_repo) = split /\s+/, $installed_repo_line, 2;
	if ($installed_repo eq $repo) {
	    return 0;
	}
    }
    my @cm_cmd = (qw(yum config-manager --set-enabled), $repo);
    my $err;
    if (!eval { $self->open3({errref => \$err}, @cm_cmd); 1 }) {
	if ($err =~ /No such command: config-manager/) {
	    $self->system(qw(dnf -y install), 'dnf-command(config-manager)');
	    $self->system(@cm_cmd);
	} else {
	    error $err;
	}
    }
    $self->system(qw(yum update)) if $do_update;
    return 1;
}

1;

__END__
