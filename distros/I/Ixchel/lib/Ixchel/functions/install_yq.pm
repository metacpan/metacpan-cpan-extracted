package Ixchel::functions::install_yq;

use 5.006;
use strict;
use warnings;
use Exporter 'import';
our @EXPORT = qw(install_yq);
use Rex -feature => [qw/1.4/];
use Rex::Hardware;
use Rex::Commands::Pkg;
use English;
use Ixchel::functions::github_fetch_release_asset;
use Fcntl qw( :mode );

# prevents Rex from printing out rex is exiting after the script ends
$::QUIET = 2;

=head1 NAME

Ixchel::functions::install_yq - Installs mikefarah/yq.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    use Ixchel::functions::install_yq;
    use Data::Dumper;

    eval{ install_yq };
    if ($@) {
        print 'Failed to install yq... '.$@."\n";
    }

    # install it to /usr/local/bin/yq
    eval{ install_yq(path=>'/usr/local/bin/yq') };
    if ($@) {
        print 'Failed to install yq... '.$@."\n";
    }

The available options are as below.

    - path :: Where to install to if not using a package.
        Default :: /usr/bin/yq

    - no_pkg :: Don't attempt to install via a package.
        Default :: 0

Supported OS as below...

    FreeBSD
    Linux
    NetBSD
    OpenBSD

Package support is available for the OSes below.

    FreeBSD

=cut

sub install_yq {
	my (%opts) = @_;

	if ( $OSNAME eq 'freebsd' && !$opts{no_pkg} ) {
		pkg( "go-yq", ensure => "present" );
		return;
	}

	if ( $OSNAME ne 'linux' && $OSNAME ne 'netbsd' && $OSNAME ne 'openbsd' && $OSNAME ne 'freebsd' ) {
		die( $OSNAME . ' is not a supported OS' );
	}

	if ( !defined( $opts{path} ) ) {
		$opts{path} = '/usr/bin/yq';
	}

	my %hw = Rex::Hardware->get(qw/ Kernel /);

	my $asset = 'yq_' . $OSNAME . '_' . $hw{Kernel}{architecture};

	eval {
		github_fetch_release_asset(
			owner  => 'mikefarah',
			repo   => 'yq',
			asset  => $asset,
			output => $opts{path},
			pre    => 0,
			draft  => 0,
			atomic => 1,
			append => 0,
			return => 0,
		);
	};
	if ($@) {
		die( 'Fetch the latest release of yq failed... ' . $@ );
	}

	system( 'chmod', '0755', $opts{path} );
	if ( $? != 0 ) {
		die( 'Failed to chmod 0755 ' . $opts{path} . ' ... ' . $@ );
	}

} ## end sub install_yq

1;
