#!/usr/bin/env perl

use strict;
use warnings;

# This file is used 
# to generate and test
# a Build file

my $cpanm = get_cpanm() or die "Didn't find cpanm.\n";


### Write to Build file.
my $file = "./Build";
open(my $fh, ">", $file) or die $!;
print $fh  "#!/bin/sh\n";

my $dzil = get_dzil($fh, $cpanm);

### By now, cpanm and dzil should both be installed.
print $fh "$dzil authordeps | $cpanm\n";
print $fh "$dzil listdeps | $cpanm\n";
print $fh "$dzil install\n";
close($fh);
chmod (0755, $file) or die "Error while chmodding.\n";

#####################################################################

sub get_cpanm {
    my $cpanm = which('cpanm');
    if ( $cpanm ) {
	### Found cpanm already installed.
	print "Found cpanm at [$cpanm]\n";
    } else {
	print qq{No cpanm found!\n};
	### Install it.
	my $cpanm = install_cpanm();
	if ( $cpanm ) {
	    print "Found cpanm: [$cpanm]\n";
	} else {
	    my $curl = which('curl');
	    if ( $curl ) {
		print "Giving up......\n";
		exit(1);
	    } else {
		print qq{Missing curl. Install "curl" and try again.\n};
		print qq{Stopping now.\n};
		exit(1);
	    }
	}
    }

    return $cpanm;
}

#####################################################################

sub which {
    my $file = $_[0];
    my $command = qx( which $file );
    chomp $command;
    return $command;
}

#####################################################################

sub install_cpanm {
    my $install = qx( curl -L https://cpanmin.us | perl - App::cpanminus );
    my $cpanm = which('cpanm');
    return $cpanm;
}

#####################################################################

sub get_dzil {

    my ( $fh, $cpanm ) = @_;

    my $dzil = which('dzil');
    return $dzil if $dzil; ## Found it.

    ### Install dzil.
    print $fh  $cpanm, " Dist::Zilla\n";
    $dzil = 'dzil';

    print $fh <<"INSTALL_DZIL";
if [ -x "$dzil" ]; then
    echo "dzil found. install succeeded."
else
    echo "dzil not found. Installing with --force."
    $cpanm --force Dist::Zilla
    if [ -x "$dzil" ]; then
        echo "dzil install succeeded with --force"
    else
        echo "dzil install failed even with --force"
        echo "SEE: https://github.com/ownlifeful/Graph-Undirected-Hamiltonicity#installation"
        exit 1
    fi
fi
INSTALL_DZIL

    return $dzil;
}

1;
