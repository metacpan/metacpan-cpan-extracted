package Ixchel::Actions::lilith_config;

use 5.006;
use strict;
use warnings;
use File::Slurp;
use base 'Ixchel::Actions::base';
use Sys::Hostname;

=head1 NAME

Ixchel::Actions::lilith_config - Generates the config for Lilith.

=head1 VERSION

Version 0.2.0

=cut

our $VERSION = '0.2.0';

=head1 CLI SYNOPSIS

ixchel -a lilith_config [B<-w>] [B<-o> <outfile>]

=head1 CODE SYNOPSIS

    use Data::Dumper;

    my $results=$ixchel->action(action=>'lilith_config', opts=>{});

    if ($results->{ok}) {
        print $results->{config};
    }else{
        die('Action errored... '.joined("\n", @{$results->{errors}}));
    }

=head1 FLAGS

=head2 -w

Write it out.

=head2 -o <outfile>

The file to write it out to.

Default :: /usr/local/etc/lilith.toml

=head1 CONFIG

.lilith.config is used for generating the config.

=head2 AUTO CONFIG

If .lilith.auto_config.enabled=1 is set, then it it will automatically fill out the
monitored instances.

For single instances setups it is done as below.

    Suricata -> $hostname-pie      -> /var/log/suricata/alert.json
    Sagan    -> $hostname-lae      -> /var/log/sagan/alert.json
    CAPEv2   -> $hostname-malware  -> /opt/CAPEv2/log/eve.json

For multi-instance it is done as below.

    Suricata -> $hostname-$instance -> /var/log/suricata/alert-$instance.json
    Sagan    -> $hostname-$instance -> /var/log/sagan/alert-$instance.json
    CAPEv2   -> $hostname-malware   -> /opt/CAPEv2/log/eve.json (or wherever .cape.eve set to)

For hostname .lilith.auto_config.full=1 is set, then the full hostname is used.
Otherwise it will use the shorthostname via removing everything after the first /\./
via s/\.+$//.

The variables used for checking which should be enabled are the usual enable ones as below.

    .suricata.enable
    .sagan.enable
    .cape.enable

This expects that the instane naming scheme does not overlap and will error if any of them
do overlap, including if they are already defined in .lilith.config .

=head1 RESULT HASH REF

    .errors :: A array of errors encountered.
    .status_text :: A string description of what was done and the results.
    .ok :: Set to zero if any of the above errored.
    .config :: The generated config.

=cut

sub new_extra {
	my $self = $_[0];

	if ( !defined( $self->{opts}{o} ) ) {
		$self->{opts}{o} = '/usr/local/etc/lilith.toml';
	}
}

sub action_extra {
	my $self = $_[0];

	my $config = $self->{config}{lilith}{config};
	if ($@) {
		$self->status_add( error => 1, status => 'Errored generating TOML for config ... ' . $@ );
		return undef;
	}

	##
	##
	## auto config stuff
	##
	##
	$self->status_add( status => '.lilith.auto_config.enable=1 .lilith.auto_config.full='
			. $self->{config}{lilith}{auto_config}{full}, );
	if ( $self->{config}{lilith}{auto_config}{enabled} ) {
		my $hostname = hostname;
		if ( !$self->{config}{lilith}{auto_config}{full} ) {
			$hostname =~ s/\..*$//;
		}
		$self->status_add( status => 'using hostname "' . $hostname . '"', );
		##
		## cape auto config
		##
		if ( $self->{config}{cape}{enable} ) {
			my $instance_name = $hostname . '-malware';
			if ( defined( $config->{$instance_name} ) ) {
				$self->status_add(
					error  => 1,
					status => $instance_name . ' already exists',
				);
			}
			$config->{ $hostname . '-malware' } = {
				instance => $hostname . '-malware',
				type     => 'cape',
				eve      => $self->{caoe}{eve},
			};
			$self->status_add( status => $instance_name . ': type=cape, eve="' . $self->{vape}{eve} . '"', );
		} ## end if ( $self->{config}{cape}{enable} )
		##
		## suricata auto config
		##
		if ( $self->{config}{suricata}{enable} && !$self->{config}{suricata}{multi_instance} ) {
			my $instance_name = $hostname . '-pie';
			if ( defined( $config->{$instance_name} ) ) {
				$self->status_add(
					error  => 1,
					status => $instance_name . ' already exists',
				);
			}
			$config->{$instance_name} = {
				instance => $hostname . '-pie',
				type     => 'suricata',
				eve      => '/var/log/suricata/alert.json',
			};
			$self->status_add( status => $instance_name . ': type=suricata, eve="/var/log/suricata/alert.json"', );
		} elsif ( $self->{config}{suricata}{enable} && $self->{config}{suricata}{multi_instance} ) {
			my @instances = keys( %{ $self->{config}{suricata}{instances} } );
			foreach my $item (@instances) {
				my $instance_name = $hostname . '-' . $item;
				if ( defined( $config->{$instance_name} ) ) {
					$self->status_add(
						error  => 1,
						status => $instance_name . ' already exists',
					);
				}
				$config->{$instance_name} = {
					instance => $instance_name,
					type     => 'suricata',
					eve      => '/var/log/suricata/alert-' . $item . '.json',
				};
				$self->status_add(
					status => $instance_name . ': type=suricata, eve="/var/log/suricata/alert-' . $item . '.json"',
				);
			} ## end foreach my $item (@instances)
		} ## end elsif ( $self->{config}{suricata}{enable} && ...)
		##
		## sagan auto config
		##
		if ( $self->{config}{sagan}{enable} && !$self->{config}{sagan}{multi_instance} ) {
			my $instance_name = $hostname . '-lae';
			if ( defined( $config->{$instance_name} ) ) {
				$self->status_add(
					error  => 1,
					status => $instance_name . ' already exists',
				);
			}
			$config->{ $hostname . '-lae' } = {
				instance => $hostname . '-lae',
				type     => 'sagan',
				eve      => '/var/log/sagan/alert.json',
			};
			$self->status_add( status => $instance_name . ': type=sagan, eve="/var/log/sagan/alert.json"', );
		} elsif ( $self->{config}{sagan}{enable} && $self->{config}{suricatsgan}{multi_instance} ) {
			my @instances = keys( %{ $self->{config}{sagan}{instances} } );
			foreach my $item (@instances) {
				my $instance_name = $hostname . '-' . $item;
				if ( defined( $config->{$instance_name} ) ) {
					$self->status_add(
						error  => 1,
						status => $instance_name . ' already exists',
					);
				}
				$config->{$instance_name} = {
					instance => $instance_name,
					type     => 'suricata',
					eve      => '/var/log/suricata/alert-' . $item . '.json',
				};
				$self->status_add(
					status => $instance_name . ': type=sagan, eve="/var/log/sagan/alert-' . $item . '.json"', );
			} ## end foreach my $item (@instances)
		} ## end elsif ( $self->{config}{sagan}{enable} && $self...)
	} ## end if ( $self->{config}{lilith}{auto_config}{...})

	my $toml;
	my $to_eval = 'use TOML::Tiny qw(to_toml); $toml = to_toml($config);';
	eval $to_eval;
	if ($@) {
		$self->status_add( error => 1, status => 'Errored generating TOML for config... Is TOML::Tiny installed? cpanm TOML::Tiny ?... ' . $@ );
		return undef;
	}

	$self->status_add( status => "Lilith Config ...\n" . $toml );

	if ( $self->{opts}{w} ) {
		eval { write_file( $self->{opts}{o}, $toml ) };
		if ($@) {
			$self->status_add(
				error  => 1,
				status => 'Errored writing TOML out to "' . $self->{opts}{o} . '" ... ' . $@
			);
			return undef;
		}
	} ## end if ( $self->{opts}{w} )

	return undef;
} ## end sub action_extra

sub short {
	return 'Generates the config for Lilith.';
}

sub opts_data {
	return '
np
w
o=s
';
}

1;
