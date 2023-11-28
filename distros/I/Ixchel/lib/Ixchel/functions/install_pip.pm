package Ixchel::functions::install_pip;

use 5.006;
use strict;
use warnings;
use Exporter 'import';
our @EXPORT = qw(install_pip);
use Rex -feature => [qw/1.4/];
use Rex::Commands::Gather;
use Rex::Commands::Pkg;

# prevents Rex from printing out rex is exiting after the script ends
$::QUIET = 2;

=head1 NAME

Ixchel::functions::install_pip - Installs pip for python3

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    use Ixchel::functions::install_pip;
    use Data::Dumper;

    eval{ install_pip };
    if ($@) {
        print 'Failed to install pip...'.$@."\n";
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

=head2 install_pip

Installs pip for the OS.

    eval{ install_cpanm };
    if ($@) {
        print 'Failed to install cpanm ...'.$@;
    }

=cut

sub install_pip {
	my (%opts) = @_;

	if (is_freebsd) {
		pkg( "python3", ensure => "present" );
		my $which_python3 = `which python3 2> /dev/null`;
		chomp($which_python3);
		if ( $which_python3 !~ /python3$/ ) {
			die( 'Unable to locate python3 with PATH=' . $ENV{PATH} );
		}
		my $python_link = readlink($which_python3);
		$python_link =~ s/.*python3\.//;
		my $pkg = 'py3' . $python_link . '-pip';
		pkg( $pkg, ensure => "present" );
	} elsif (is_debian|| is_redhat || is_mageia || is_void) {
		pkg( "python3",     ensure => "present" );
		pkg( "python3-pip", ensure => "present" );
	} elsif (is_arch) {
		pkg( "python",     ensure => "present" );
		pkg( "python-pip", ensure => "present" );
	} elsif (is_suse) {
		pkg( "python311",     ensure => "present" );
		pkg( "python311-pip", ensure => "present" );
	} elsif (is_alt) {
		pkg( "python3", ensure => "present" );
		pkg( "pip",     ensure => "present" );
	} elsif (is_netbsd) {
		pkg( "python311", ensure => "present" );
		pkg( "py311-pip", ensure => "present" );
	} elsif (is_openbsd) {
		pkg( "python311", ensure => "present" );
		pkg( "py311-pip", ensure => "present" );
	}

} ## end sub install_pip

1;
