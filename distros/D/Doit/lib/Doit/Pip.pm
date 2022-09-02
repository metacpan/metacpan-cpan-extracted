# -*- perl -*-

#
# Author: Slaven Rezic
#
# Copyright (C) 2020,2022 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: slaven@rezic.de
# WWW:  https://github.com/eserte/Doit
#

package Doit::Pip; # Convention: all commands here should be prefixed with 'pip_'

use strict;
use warnings;

our $VERSION = '0.012';

use Doit::Log;

sub new { bless {}, shift }
sub functions { qw(pip_install_packages pip_missing_packages can_pip) }

sub can_pip {
    my($self) = @_;
    $self->which('pip3') ? 1 : 0;
}

sub pip_install_packages {
    my($self, @packages) = @_;
    my @missing_packages = $self->pip_missing_packages(@packages);
    if (@missing_packages) {
	$self->system('pip3', 'install', @missing_packages);
    }
    @missing_packages;
}

sub pip_missing_packages {
    my($self, @packages) = @_;
    my @missing_packages;
    if (0) { # XXX this is only possible with newer pip versions --- how new?
	my $stderr;
	eval {
	    $self->info_open3({
		quiet => 1,
		errref => \$stderr,
	    }, 'pip3', 'show', '-q', '--no-color', @packages); # note: --no-color is only available in newer pip versions
	};
	if ($stderr) {
	    if ($stderr =~ m{\QWARNING: Package(s) not found:\E\s+(.+)}) {
		@missing_packages = split /,\s+/, $1;
	    } else {
		error "Unable to parse stderr output of 'pip3 show': '$stderr'";
	    }
	}
    } else {
	if (0) { # XXX this solution would be straightforward --- unfortunately some pip3 versions do not exit with a non-zero status for missing packages
	    for my $package (@packages) {
		if (!eval { $self->info_open3({quiet=>1}, 'pip3', 'show', '-q', $package); 1 }) {
		    push @missing_packages, $package;
		}
	    }
	} else {
	    my %seen_package;
	    for my $line (do { no warnings "uninitialized"; split /\n/, eval { $self->info_open3({quiet=>1}, 'pip3', 'show', @packages) } }) {
		if ($line =~ /^Name:\s+(\S+)/) {
		    $seen_package{$1}++;
		}
	    }
	    for my $package (@packages) {
		if (!$seen_package{$package}) {
		    push @missing_packages, $package;
		}
	    }
	}
    }
    @missing_packages;
}

1;

__END__
