package File::VirusScan;
use strict;
use warnings;
use Carp;
use 5.008;

use File::VirusScan::Result;
use File::VirusScan::ResultSet;

our $VERSION = '0.103';

# We don't use Module::Pluggable.  Most users of this module will have
# one or two virus scanners, with the other half-dozen or so plugins
# going unused, so there's no sense in finding/loading all plugins.
sub new
{
	my ($class, $conf) = @_;

	if(!exists $conf->{engines} || !scalar keys %{ $conf->{engines} }) {
		croak q{Must supply an 'engines' value to constructor};
	}

	my %backends;

	# Load and initialise our backend engines
	while (my ($moniker, $backend_conf) = each %{ $conf->{engines} }) {

		$moniker =~ s/[^-A-Za-z0-9_:]//;
		my $backclass = $moniker;

		substr($backclass, 0, 1, 'File::VirusScan::Engine::') if substr($backclass, 0, 1) eq '-';

		eval qq{use $backclass;};  ## no critic(StringyEval)
		if($@) {                   ## no critic(PunctuationVars)
			croak "Unable to find class $backclass for backend '$moniker'";
		}

		$backends{$moniker} = $backclass->new($backend_conf);
	}

	my $self = { always_scan => $conf->{always_scan}, };

	if(exists $conf->{order}) {
		$self->{_backends} = [ @backends{ @{ $conf->{order} } } ];
	} else {
		$self->{_backends} = [ values %backends ];
	}

	return bless $self, $class;
}

sub scan
{
	my ($self, $path) = @_;

	my $result = File::VirusScan::ResultSet->new();

	for my $back (@{ $self->{_backends} }) {

		my $scan_result = eval { $back->scan($path) };

		if($@) {
			$result->add(File::VirusScan::Result->error("Error calling ->scan(): $@"));
		} else {
			$result->add($scan_result);
		}

		if(!$self->{always_scan}
			&& $result->has_virus())
		{
			last;
		}
	}

	return $result;
}

sub get_backends
{
	my ($self) = @_;
	return $self->{_backends};
}

1;
__END__

=head1 NAME

File::VirusScan - Unified interface for virus scanning of files/directories

=head1 SYNOPSIS

    my $scanner = File::VirusScan->new({
	engines => {
		'-Daemon::ClamAV::Clamd' => {
			socket_name => '/var/run/clamav/clamd.ctl',
		},
		'-Command::FSecure::FSAV' => {
			path   => '/usr/local/bin/fsav
		},
		'-Daemon::FPROT::V6' => {
			host   => '127.0.0.1',
			port   => 10200,
		}

	},

	order => [ '-Daemon::ClamAV::Clamd', '-Daemon::FPROT::V6', '-Command::FSecure::FSAV' ],

	always_scan => 0,
    });

    my $result = $scanner->scan( "/tmp/uploaded-files" );

    if( $result->all_clean ) {
	return 'Happiness and puppies!';
    } else {
	return 'Oh noes!  You've got ' . join(',' @{ $result->virus_names } );
    }

=head1 DESCRIPTION

This class provides a common API for scanning files or directories with
one or more third party virus scanners.

Virus scanners are supported via pluggable engines under the
L<File::VirusScan::Engine> namespace.  At the time of this release,
the following plugins are shipped with File::VirusScan:

=over 4

=item Clam Antivirus

Scanning daemon via L<File::VirusScan::Engine::Daemon::ClamAV::Clamd>, and
commandline scanner via L<File::VirusScan::Engine::Command::ClamAV::Clamscan>

=item NAI UVScan

L<File::VirusScan::Engine::Command::NAI::Uvscan>

=item F-Secure FSAV

L<File::VirusScan::Engine::Command::FSecure::FSAV>

=item Trend Micro

Scanning daemon via L<File::VirusScan::Engine::Daemon::Trend::Trophie>,
commandline scanning via
L<File::VirusScan::Engine::Command::Trend::Vscan>

=item BitDefender BDC

L<File::VirusScan::Engine::Command::BitDefender::BDC>

=item Command Antivirus

L<File::VirusScan::Engine::Command::Authentium::CommandAntivirus>

=item Norman Antivirus

L<File::VirusScan::Engine::Command::Norman::NVCC>

=item ESET

Scanning via esets_cli with L<File::VirusScan::Engine::Command::ESET::NOD32>

=item Symantec

Scanning via Carrier Scan server with L<File::VirusScan::Engine::Daemon::Symantec::CSS>

=item F-PROT

Scanning daemon via L<File::VirusScan::Engine::Daemon::FPROT::V4> and
L<File::VirusScan::Engine::Daemon::FPROT::V6>, as well as the
commandline scanners via L<File::VirusScan::Engine::Command::FPROT::FPROT> and L<File::VirusScan::Engine::Command::FPROT::Fpscan>

=item Central Command Vexira

L<File::VirusScan::Engine::Command::CentralCommand::Vexira>

=item Sophos

Daemonized scanning using the Sophie daemon with
L<File::VirusScan::Engine::Daemon::Sophos::Sophie>.  Commandline scanning with
L<File::VirusScan::Engine::Command::Sophos::Sweep> or
L<File::VirusScan::Engine::Command::Sophos::Savscan>

=item Kaspersky

Scanning with aveserver using
L<File::VirusScan::Engine::Command::Kaspersky::AVP5>, or with kavscanner using
L<File::VirusScan::Engine::Command::Kaspersky::Kavscanner>

=back

=head1 METHODS

=head2 new ( { config data } )

Creates a new File::VirusScan object, using configuration data in the
provided hashref.

Required configuration options are:

=over 4

=item engines

Reference to hash of backend virus scan engines to be used, and their
specific configurations.

Keys must refer to a class that implements the
L<File::VirusScan::Engine> interface, and may be specified as either:

=over 4

=item 1.

A fully-qualified class name.

=item 2.

A name beginning with '-', in which case the '-' is removed and replaced with the L<File::VirusScan::Engine>:: prefix.

=back

Values should be another hash reference containing engine-specific
configuration.  This will vary by backend, but generally requires at
minimum some way of locating (socket path, host/port) or executing
(path to executable) the scanner.

=back

Optional configuration options are:

=over 4

=item order

List reference containing keys provided to B<engines> above, in the
order in which they should be called.

If omitted, backends will be invoked in hash key order.

=item always_scan

By default, File::VirusScan will stop scanning a message after one
backend finds a virus.  If you wish to run all backends anyway, set
this option to a true value.

=back

=head2 scan ( $path )

Invokes the configured scan backends on the path.  The path may be
either a single file, or a directory.

Returns an File::VirusScan::ResultSet object, which can be queried for status.

=head2 get_backends ( )

Returns a reference to the internal array of configured backend instances.

=head1 DEPENDENCIES

L<File::VirusScan::Engine>, L<File::VirusScan::Result>

=head1 AUTHOR

Dave O'Neill (dmo@roaringpenguin.com)

Dianne Skoll  (dfs@roaringpenguin.com>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007 Roaring Penguin Software, Inc.

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License, version 2, or
(at your option) any later version.
