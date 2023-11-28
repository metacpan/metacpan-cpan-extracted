package Ixchel::Actions::suricata_outputs;

use 5.006;
use strict;
use warnings;
use File::Slurp;
use String::ShellQuote;

=head1 NAME

Ixchel::Actions::suricata_ouputs :: Generate a outputs include for suricata.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    use Data::Dumper;

    my $results=$ixchel->action(action=>'suricata_outputs', opts=>{np=>1, w=>1, });

    print Dumper($results);

The template used is 'suricata_outputs'.

    .suricata.enable_fastlog :: Perl boolean if to enable fastlog output.
        Default ::
        Map To :: .vars.enable_fastlog

    .suricata.enable_syslog :: Perl boolean if to enable syslog output.
        Default :: 0
        Map To :: .vars.enable_syslog

    .suricata.filestore_enable :: Perl boolean if to enable the filestore.
        Default :: 0
        Map To :: .vars.filestore_enable

    .suricata.dhcp_in_alert_eve :: Perl boolean if DHCP type items should be in the alert eve.
        Default :: 0
        Map To :: .vars.dhcp_in_alert_eve

    .suricata.config_base :: The variable used for controlling where the outputs.yaml
            file is created.

    .suricata.enable_pcap_log :: Enable PCAP logging.
        Default :: 0
        Map To :: .vars.enable_pcap_log

The logging options are as below.

    .suricata.logging.in_outputs :: Put the .logging section in the outputs include.
        Default :: 1
        Map To :: .vars.logging.in_outputs

    .suricata.logging.level :: Value for .logging.default-log-level .
        Default :: notice
        Map To :: .vars.logging.level

    .suricata.logging.console :: If enabled should be yes or no for the syslog console output.
        Default :: no
        Map To :: .vars.logging.console

    .suricata.logging.file :: If enabled should be yes or no for the file logging output.
        Default :: yes
        Map To :: .vars.logging.file

    .suricata.logging.file_level :: Value for level for the file output.
        Default :: info
        Map To :: .vars.logging.file_level

    .suricata.logging.syslog :: If enabled should be yes or no for the syslog logging output.
        Default :: no
        Map To :: .vars.logging.syslog

    .suricata.logging.syslog_facility :: Value for facility for syslog logging output.
        Default :: local5
        Map To :: .vars.logging.syslog_facility

    .suricata.logging.syslog_format :: Value for format for syslog logging output.
        Default :: "[%i] <%d> -- "
        Map To :: .vars.logging.syslog_format

Multiinstance handling. Ixchel supports multiple Suricata instances on Linux.
If .suricata.multi_instace is set to 1, then the following is done.

    1: Instance vars are generated via first copying the ones above and then
       overwriting them with .suricata.instances.$instance.$var .

    2: .vars.instance_part is set to "-$instance". If instances are not in use
       this value is ''.

    3: .vars.instance_part2 is set to "$instance.". If instances are not in use
       this value is ''.

    4: The output file is named  "outputs-$instance.yaml".

=head1 FLAGS

=head2 --np

Do not print the status of it.

=head2 -w

Write the generated services to service files.

=head2 -i instance

A instance to operate on.

=head1 RESULT HASH REF

    .errors :: A array of errors encountered.
    .status_text :: A string description of what was done and the results.
    .ok :: Set to zero if any of the above errored.

=cut

sub new {
	my ( $empty, %opts ) = @_;

	my $self = {
		config => {},
		vars   => {},
		arggv  => [],
		opts   => {},
	};
	bless $self;

	if ( defined( $opts{config} ) ) {
		$self->{config} = $opts{config};
	}

	if ( defined( $opts{t} ) ) {
		$self->{t} = $opts{t};
	} else {
		die('$opts{t} is undef');
	}

	if ( defined( $opts{share_dir} ) ) {
		$self->{share_dir} = $opts{share_dir};
	}

	if ( defined( $opts{opts} ) ) {
		$self->{opts} = \%{ $opts{opts} };
	}

	if ( defined( $opts{argv} ) ) {
		$self->{argv} = $opts{argv};
	}

	if ( defined( $opts{vars} ) ) {
		$self->{vars} = $opts{vars};
	}

	if ( defined( $opts{ixchel} ) ) {
		$self->{ixchel} = $opts{ixchel};
	}

	return $self;
} ## end sub new

sub action {
	my $self = $_[0];

	my $results = {
		errors      => [],
		status_text => '',
		ok          => 0,
	};

	my $config_base = $self->{config}{suricata}{config_base};

	if ( $self->{config}{suricata}{multi_instance} ) {
		my @instances;

		my @vars_to_migrate = ( 'enable_fastlog', 'enable_syslog', 'filestore_enable', 'dhcp_in_alert_eve' );

		if ( defined( $self->{opts}{i} ) ) {
			@instances = ( $self->{opts}{i} );
		} else {
			@instances = keys( %{ $self->{config}{suricata}{instances} } );
		}
		foreach my $instance (@instances) {
			my $vars = {
				enable_fastlog    => $self->{config}{suricata}{enable_fastlog},
				enable_syslog     => $self->{config}{suricata}{enable_syslog},
				filestore_enable  => $self->{config}{suricata}{filestore_enable},
				dhcp_in_alert_eve => $self->{config}{suricata}{dhcp_in_alert_eve},
				enable_pcap_log   => => $self->{config}{suricata}{enable_pcap_log},
				logging           => $self->{config}{suricata}{logging},
				instance_part     => '-' . $instance,
				instance_part2    => $instance . '.',
			};

			foreach my $to_migrate (@vars_to_migrate) {
				if ( defined( $self->{config}{suricata}{instances}{$instance}{$to_migrate} ) ) {
					$vars->{$to_migrate} = $self->{config}{suricata}{instances}{$instance}{$to_migrate};
				}
			}

			my $filled_in;
			eval {
				$filled_in = $self->{ixchel}->action(
					action => 'template',
					vars   => $vars,
					opts   => {
						np => 1,
						t  => 'suricata_outputs',
					},
				);
				if ( $self->{opts}{w} ) {
					write_file( $config_base . '/outputs-' . $instance . '.yaml', $filled_in );
				}
			};
			if ($@) {
				$results->{status_text}
					= $results->{status_text}
					. '-----[ Errored: '
					. $instance
					. ' ]-------------------------------------' . "\n" . '# '
					. $@ . "\n";
				$self->{ixchel}{errors_count}++;
			} else {
				$results->{status_text}
					= $results->{status_text}
					. '-----[ '
					. $instance
					. ' ]-------------------------------------' . "\n"
					. $filled_in . "\n";
			}
		} ## end foreach my $instance (@instances)
	} else {
		if ( defined( $self->{opts}{i} ) ) {
			die('-i may not be used in single instance mode');
		}

		my $vars = {
			enable_fastlog    => $self->{config}{suricata}{enable_fastlog},
			enable_syslog     => $self->{config}{suricata}{enable_syslog},
			filestore_enable  => $self->{config}{suricata}{filestore_enable},
			dhcp_in_alert_eve => $self->{config}{suricata}{dhcp_in_alert_eve},
			dhcp_in_alert_eve => $self->{config}{suricata}{dhcp_in_alert_eve},
			enable_pcap_log   => $self->{config}{suricata}{enable_pcap_log},
			logging           => $self->{config}{suricata}{logging},
			instance_part     => '',
			instance_part2    => '',
		};

		my $filled_in;
		eval {
			$filled_in = $self->{ixchel}->action(
				action => 'template',
				vars   => $vars,
				opts   => {
					np => 1,
					t  => 'suricata_outputs',
				},
			);

			if ( $self->{opts}{w} ) {
				write_file( $config_base . '/outputs.yaml', $filled_in );
			}
		};
		if ($@) {
			$results->{status_text} = '# ' . $@ . "\n";
			$self->{ixchel}{errors_count}++;
		} else {
			$results->{status_text} = $filled_in;
		}
	} ## end else [ if ( $self->{config}{suricata}{multi_instance...})]

	if ( !$self->{opts}{np} ) {
		print $results->{status_text};
	}

	if ( !defined( $results->{errors}[0] ) ) {
		$results->{ok} = 1;
	}

	return $results;
} ## end sub action

sub help {
	return 'Generate a outputs include for suricata.

--np          Do not print the status of it.

-w            Write the generated services to service files.

-i <instance> A instance to operate on.

';
} ## end sub help

sub short {
	return 'Generate a outputs include for suricata.';
}

sub opts_data {
	return 'i=s
np
w
';
}

1;
