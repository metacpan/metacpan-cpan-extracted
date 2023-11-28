package Ixchel::functions::python_module_via_pkg;

use 5.006;
use strict;
use warnings;
use Exporter 'import';
our @EXPORT = qw(python_module_via_pkg);
use Rex -feature => [qw/1.4/];
use Rex::Commands::Gather;
use Rex::Commands::Pkg;
use Ixchel::functions::status;

# prevents Rex from printing out rex is exiting after the script ends
$::QUIET = 2;

=head1 NAME

Ixchel::functions::python_module_via_pkg - Tries to install a module for python3 via the package manager.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    use Ixchel::functions::python_module_via_pkg;
    use Data::Dumper;

    eval{ python_module_via_pkg(module=>'Pillow') };
    if ($@) {
        print 'Failed to install Pillow...'.$@."\n";
    }

Supported OS families are...

    Alt Linux
    Arch Linux
    Debian Linux
    FreeBSD
    Mageia Linux
    NetBSD
    OpenBSD
    Redhat Linux
    Suse Linux
    Void Linux

=head1 Functions

=head2 python_module_via_pkg

Tries to install a python3 module via packages.

    eval{ python_module_via_pkg(module=>'Pillow') };
    if ($@) {
        print 'Failed to install python module ...'.$@;
    }

=cut

sub python_module_via_pkg {
	my (%opts) = @_;

	if ( !defined( $opts{module} ) ) {
		die('modules is undef');
	}

	my $status = '';
	my $type   = 'python_module_via_pkg';

	$status = $status
		. status(
			type   => $type,
			error  => 0,
			status => 'Trying to install Python module ' . $opts{module}
		);

	my $pkg;
	my $not_tried = 1;
	if (is_freebsd) {
		$not_tried = 0;
		$status    = $status
			. status( type => 'python_module_via_pkg', error => 0, status => 'OS Family FreeBSD detectected' );
		my $which_python3 = `which python3 2> /dev/null`;
		chomp($which_python3);
		$status = $status
			. status(
				type   => $type,
				error  => 0,
				status => 'python3 path is "' . $which_python3 . '"'
			);
		if ( $which_python3 !~ /python3$/ ) {
			die( $status . 'Unable to locate python3 with PATH=' . $ENV{PATH} );
		}
		my $python_link = readlink($which_python3);
		$status = $status
			. status(
				type   => $type,
				error  => 0,
				status => 'python3 linked to "' . $python_link . '"'
			);
		$python_link =~ s/.*python3\.//;
		$pkg    = 'py3' . $python_link . '-' . $opts{module};
		$status = $status
			. status(
				type   => $type,
				error  => 0,
				status => 'Ensuring that package "' . $pkg . '" is present'
			);
		eval { pkg( $pkg, ensure => "present" ); };
		if ($@) {
			$status = $status
				. status(
					type   => $type,
					error  => 1,
					status => 'Failed ensuring that package "' . $pkg . '" is present... ' . $@
				);
			$pkg    = lc($pkg);
			$status = $status
				. status(
					type   => $type,
					error  => 0,
					status => 'Trying ensuring that package "' . $pkg . '" is present'
				);
			eval { pkg( $pkg, ensure => "present" ); };
			if ($@) {
				$status = $status
					. status(
						type   => $type,
						error  => 1,
						status => 'Failed ensuring that package "' . $pkg . '" is present... ' . $@
					);
				die( $status . 'Neither ' . $pkg . ' or ' . lc($pkg) . ' could be installed' );
			}
		} ## end if ($@)
	} elsif (is_debian || is_redhat || is_arch || is_mageia || is_void) {
		$status
			= $status . status( type => 'python_module_via_pkg', error => 0, status => 'OS Family Debian, Redhat, Arch, Mageia, or Void detectected' );
		$pkg = 'python3-' . lc( $opts{module} );
	} elsif (is_suse) {
		$status
			= $status . status( type => 'python_module_via_pkg', error => 0, status => 'OS Family Suse detectected' );
		$pkg = 'python311-' . lc( $opts{module} );
	} elsif (is_alt) {
		$status
			= $status . status( type => 'python_module_via_pkg', error => 0, status => 'OS Family Alt detectected' );
		$pkg = 'python3-module-' . lc( $opts{module} );
	} elsif (is_netbsd || is_openbsd) {
		$status
			= $status . status( type => 'python_module_via_pkg', error => 0, status => 'OS Family NetBSD or OpenBSD detectected' );
		$pkg = 'py311-' . lc( $opts{module} );
	}

	if ($not_tried) {
		$status = $status
			. status(
				type   => $type,
				error  => 0,
				status => 'Ensuring that package "' . $pkg . '" is present'
			);
		eval { pkg( $pkg, ensure => 'present' ); };
		if ($@) {
			$status = $status
				. status(
					type   => $type,
					error  => 1,
					status => 'Failed ensuring that package "' . $pkg . '" is present... ' . $@
				);
			die( $status . 'Neither ' . $pkg . ' or ' . lc($pkg) . ' could be installed' );
		}
	} ## end if ($not_tried)

	$status = $status . status( type => $type, error => 0, status => 'Package "' . $pkg . '" is present' );

	return $status;
} ## end sub python_module_via_pkg

1;
