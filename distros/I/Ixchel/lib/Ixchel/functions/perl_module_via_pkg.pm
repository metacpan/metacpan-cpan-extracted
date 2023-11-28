package Ixchel::functions::perl_module_via_pkg;

use 5.006;
use strict;
use warnings;
use Exporter 'import';
our @EXPORT = qw(perl_module_via_pkg);
use Rex -feature => [qw/1.4/];
use Rex::Commands::Gather;
use Rex::Commands::Pkg;
use Ixchel::functions::status;

# prevents Rex from printing out rex is exiting after the script ends
$::QUIET = 2;

=head1 NAME

Ixchel::functions::perl_module_via_pkg

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    use Ixchel::functions::perl_module_via_pkg;
    use Data::Dumper;

    my $returned;
    eval{
        $returned=perl_module_via_pkg(module=>'Monitoring::Sneck');
    };

    print Dumper($returned);

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

=head1 Functions

=head2 perl_module_via_pkg

The function that makes it so.

    - module :: The name of name of the module to install.

=cut

sub perl_module_via_pkg {
	my (%opts) = @_;

	if ( !defined( $opts{module} ) ) {
		die('Nothing specified for a module to install');
	}

	my $pkg = $opts{module};
	my @pkg_alts;

	my $type = 'perl_module_via_pkg';

	my $status = status(
		type   => $type,
		error  => 0,
		status => 'Trying to install Perl module ' . $opts{module}
	);

	if (is_freebsd || is_netbsd || is_freebsd) {
		$status = $status . status( type => $type, error => 0, status => 'OS Family FreeBSD, NetBSD, or OpenBSD detectected' );
		$pkg =~ s/^/p5\-/;
		$pkg =~ s/\:\:/\-/g;
	} elsif (is_debian) {
		$status = $status . status( type => $type, error => 0, status => 'OS Family Debian detectected' );
		$pkg =~ s/\:\:/\-/g;
		$pkg = 'lib' . lc($pkg) . '-perl';
	} elsif (is_redhat || is_arch || is_suse || is_alt || is_mageia) {
		$status = $status . status( type => $type, error => 0, status => 'OS Family Redhat, Arch, Suse, Alt, or Mageia detectected' );
		$pkg =~ s/\:\:/\-/g;
		$pkg = 'perl-' . $pkg;
	}

	$status = $status . status( type => $type, error => 0, status => 'Ensuring package "' . $pkg . '" is present' );

	eval { pkg( $pkg, ensure => 'present' ); };
	if ($@) {
		die( $status . "\n"
				. status( type => $type, error => 1, status => 'Installing package "' . $pkg . '" failed ... ' . $@ ) );
	}

	$status = $status . status( type => $type, error => 0, status => 'Package "' . $pkg . '" is present' );

	return 1;
} ## end sub perl_module_via_pkg

1;
