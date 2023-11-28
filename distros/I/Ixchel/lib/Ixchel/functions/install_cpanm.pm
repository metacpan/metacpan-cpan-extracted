package Ixchel::functions::install_cpanm;

use 5.006;
use strict;
use warnings;
use Exporter 'import';
our @EXPORT = qw(install_cpanm);
use Rex -feature => [qw/1.4/];
use Rex::Commands::Gather;
use Rex::Commands::Pkg;

# prevents Rex from printing out rex is exiting after the script ends
$::QUIET = 2;

=head1 NAME

Ixchel::functions::install_cpanm - Installs cpanm

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    use Ixchel::functions::install_cpanm;
    use Data::Dumper;

    eval{ install_cpanm };
    if ($@) {
        print 'Failed to install cpanm...'.$@."\n";
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

=head2 install_cpanm

Installs cpanm for the OS.

    eval{ install_cpanm };
    if ($@) {
        print 'Failed to install cpanm ...'.$@;
    }

=cut

sub install_cpanm {
	my (%opts) = @_;

	if ( is_freebsd || is_netbsd || is_freebsd ) {
		pkg( "p5-App-cpanminus", ensure => "present" );
	} elsif ( is_debian || is_arch || is_mageia || is_void ) {
		pkg( "cpanminus", ensure => "present" );
	} elsif (is_redhat || is_suse || is_alt ) {
		pkg( "perl-App-cpanminus", ensure => "present" );
	}

} ## end sub perl_module_via_pkg

1;
