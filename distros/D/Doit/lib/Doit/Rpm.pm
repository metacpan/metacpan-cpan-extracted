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

package Doit::Rpm;

use strict;
use vars qw($VERSION);
$VERSION = '0.01';

sub new { bless {}, shift }
sub functions { qw(rpm_install_packages rpm_missing_packages) }

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
	open my $fh, '-|', 'env', 'LC_ALL=C', 'rpm', '--query', @packages
	    or die $!;
	while(<$fh>) {
	    if (m{^package (\S+) is not installed}) {
		push @missing_packages, $1;
	    }
	}
    }

    @missing_packages;
}


1;

__END__
