# -*- perl -*-

#
# Author: Slaven Rezic
#
# Copyright (C) 2017,2018 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: slaven@rezic.de
# WWW:  http://www.rezic.de/eserte/
#

package Doit::Fbsdpkg; # Convention: all commands here should be prefixed with 'fbsdpkg_'

use strict;
use warnings;
our $VERSION = '0.011';

sub new { bless {}, shift }
sub functions { qw(fbsdpkg_install_packages fbsdpkg_missing_packages) }

sub fbsdpkg_install_packages {
    my($self, @packages) = @_;
    my @missing_packages = $self->fbsdpkg_missing_packages(@packages);
    if (@missing_packages) {
	$self->system('pkg', 'install', '--yes', @missing_packages);
    }
    @missing_packages;
}

sub fbsdpkg_missing_packages {
    my($self, @_packages) = @_;

    my @missing_packages;

    if (@_packages) {
	my %required_version;
	my @packages;
	for my $package (@_packages) {
	    if (ref $package eq 'ARRAY') {
		my($package_name, $package_version) = @$package;
		$required_version{$package_name} = $package_version;
		push @packages, $package_name;
	    } else {
		push @packages, $package;
	    }
	}

	my %seen_packages;
	my %dummy;
	for my $l (split /\n/, $self->info_qx({quiet=>1,statusref=>\%dummy}, 'pkg', 'query', '%n %v', @packages)) {
	    my($name, $version) = split / /, $l;
	    if ($required_version{$name} && $required_version{$name} ne $version) {
		push @missing_packages, $name;
	    }
	    $seen_packages{$name} = 1;
	}

	for my $package (@packages) {
	    if (!$seen_packages{$package}) {
		push @missing_packages, $package;
	    }
	}
    }
    @missing_packages;
}

1;

__END__
