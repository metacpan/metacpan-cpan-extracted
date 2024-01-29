package Ixchel::Actions::suricata_base;

use 5.006;
use strict;
use warnings;
use File::Slurp;
use YAML::XS qw(Dump);
use Ixchel::functions::file_get;
use YAML::yq::Helper;
use File::Temp qw/ tempfile  /;
use base 'Ixchel::Actions::base';

=head1 NAME

Ixchel::Actions::suricata_base - Reels in the base Suricata config and uses it for generating the base config for each instance.

=head1 VERSION

Version 0.4.0

=cut

our $VERSION = '0.4.0';

=head1 CLI SYNOPSIS

ixchel -a suricata_base [B<-d> <base_dir>]

ixchel -a suricata_base B<-w> [B<-o> <file>] [B<--np>] [B<-d> <base_dir>]

=head1 CODE SYNOPSIS

    use Data::Dumper;

    my $results=$ixchel->action(action=>'suricata_base', opts=>{np=>1, w=>1, });

    print Dumper($results);

=head1 DESCRIPTION

This will fetch the file specied via .suricata.base_config in the config. This is
a URL to the config file to use, by default it is
https://raw.githubusercontent.com/OISF/suricata/master/suricata.yaml.in .

This will be fetched using proxies as defined under .proxy .

The following keys are removed.

   .logging.outputs
   .outputs
   .af-packet
   .pcap
   .include
   .rule-files
   .af-xdp
   .dpdk
   .sensor-name

=head1 FLAGS

=head2 -w

Write the generated services to service files.

=head2 -i instance

A instance to operate on.

=head2 -d <base_dir>

Use this as the base dir instead of .suricata.config_base from the config.

=head1 RESULT HASH REF

    .errors :: A array of errors encountered.
    .status_text :: A string description of what was done and teh results.
    .ok :: Set to zero if any of the above errored.

=cut

sub new_extra { }

sub action_extra {
	my $self = $_[0];

	my $config_base;
	if ( !defined( $self->{opts}{d} ) ) {
		$config_base = $self->{config}{suricata}{config_base};
	} else {
		if ( !-d $self->{opts}{d} ) {
			$self->status_add(
				status => '-d, "' . $self->{opts}{d} . '" is not a directory',
				error  => 1
			);

			return undef;
		}
		$config_base = $self->{opts}{d};
	} ## end else [ if ( !defined( $self->{opts}{d} ) ) ]

	my $base_config_url = $self->{config}{suricata}{base_config};

	if ( !defined($base_config_url) ) {
		$self->status_add(
			error  => 1,
			status =>
				'The config value .config.base_config is undef. It should be the value for URL to fetch it from'
		);
		return undef;
	}

	my $base_config_raw;
	eval {
		$self->status_add( status => 'Fetching ' . $base_config_url );
		$base_config_raw = file_get( url => $base_config_url );
	};
	if ($@) {
		$self->status_add( error => 1, status => 'Fetch Error... ' . $@ );
		return undef;
	}

	# rebuild the file
	my @base_config_split = split( /\n/, $base_config_raw );
	$base_config_raw = '';
	foreach my $line (@base_config_split) {
		my $value = $self->{config}{suricata}{base_fill_in}{e_logdir};
		$line =~ s/\@e_logdir\@/$value/;

		$value = $self->{config}{suricata}{base_fill_in}{e_magic_file_comment};
		$line =~ s/\@e_magic_file_comment\@/$value/;

		$value = $self->{config}{suricata}{base_fill_in}{e_magic_file};
		$line =~ s/\@e_magic_file\@/$value/;

		$value = $self->{config}{suricata}{base_fill_in}{e_defaultruledir};
		$line =~ s/\@e_defaultruledir\@/$value/;

		$value = $self->{config}{suricata}{config_base} . '/';
		$value =~ s/\/\/+$/\//;
		$line  =~ s/\@e_sysconfdir\@/$value/;

		# remove anything else as we hit the items we actually care about
		$line =~ s/^.*\@.*\@.*$//;

		$base_config_raw = $base_config_raw . $line . "\n";
	} ## end foreach my $line (@base_config_split)
	my $new_status = 'Base config template processed';
	if ( $self->{opts}{pp} ) {
		$new_status = $new_status . "...\n" . $base_config_raw;
	}
	$self->status_add( status => $new_status );

	#
	#
	# remove unwanted paths
	#
	#
	my @to_remove = (
		'.logging.outputs', '.outputs',     '.af-packet', '.pcap',
		'.include',         '.rule-files',  '.af-xdp',    '.napatech',
		'.dpdk',            '.sensor-name', '.nflog',     '.netmap'
	);
	eval {
		my ( $tnp_fh, $tmp_file ) = tempfile();
		write_file( $tmp_file, $base_config_raw );

		# use yq here to preserve comments
		my $yq = YAML::yq::Helper->new( file => $tmp_file );
		foreach my $rm_path (@to_remove) {
			$self->status_add( status => 'Removing ' . $rm_path . ' via yq...' );
			$yq->delete( var => $rm_path );
		}

		$base_config_raw = read_file($tmp_file);
	};
	if ($@) {
		$self->status_add( error => 1, status => 'Errored removing paths... ' . $@ );
		return undef;
	}
	$new_status = 'Path removal finished';
	if ( $self->{opts}{pr} ) {
		$new_status = $new_status . "...\n" . $base_config_raw;
	}
	$self->status_add( status => $new_status );

	#
	#
	# handle writing the file out
	#
	#
	if ( $self->{config}{suricata}{multi_instance} ) {
		my @instances;

		if ( defined( $self->{opts}{i} ) ) {
			@instances = ( $self->{opts}{i} );
		} else {
			@instances = keys( %{ $self->{config}{suricata}{instances} } );
		}
		foreach my $instance (@instances) {
			eval {
				my ( $tnp_fh, $tmp_file ) = tempfile();
				write_file( $tmp_file, $base_config_raw );

				my @include_paths = (
					$config_base . '/' . $instance . '-include.yaml',
					$config_base . '/' . $instance . '-outputs.yaml',
				);

				my $yq = YAML::yq::Helper->new( file => $tmp_file );
				if ( $yq->is_array( var => '.include' ) ) {
					$yq->set_array( var => '.include', vals => \@include_paths );
				} else {
					$yq->create_array( var => '.include', vals => \@include_paths );
				}

				$self->status_add( status => 'Adding .include finished' );

				$base_config_raw = read_file($tmp_file);
				$self->status_add( status => "Config... \n" . $base_config_raw );
				if ( $self->{opts}{w} ) {
					$self->status_add(
						status => 'Writing out to ' . $config_base . '/suricata-' . $instance . '.yaml' );
					write_file( $config_base . '/suricata-' . $instance . '.yaml', $base_config_raw );
				}

				unlink($tmp_file);
			} ## end eval
		} ## end foreach my $instance (@instances)
	} elsif ( defined( $self->{opts}{i} ) && !$self->{config}{suricata}{multi_instance} ) {
		$self->status_add(
			error  => 1,
			status => '-i may not be used in single instance mode, .suricata.multi_instance=1, ,'
		);
	} else {
		eval {
			my ( $tnp_fh, $tmp_file ) = tempfile();
			write_file( $tmp_file, $base_config_raw );

			my @include_paths = ( $config_base . '/include.yaml', $config_base . '/outputs.yaml', );

			my $yq = YAML::yq::Helper->new( file => $tmp_file );
			if ( $yq->is_array( var => '.include' ) ) {
				$yq->set_array( var => '.include', vals => \@include_paths );
			} else {
				$yq->create_array( var => '.include', vals => \@include_paths );
			}

			$self->status_add( status => 'Adding .include finished' );

			$base_config_raw = read_file($tmp_file);
			$self->status_add( status => "Config... \n" . $base_config_raw );
			if ( $self->{opts}{w} ) {
				$self->status_add( status => 'Writing out to ' . $config_base . '/suricata.yaml' );
				write_file( $config_base . '/suricata.yaml', $base_config_raw );
			}

			unlink($tmp_file);
		};
		if ($@) {
			$self->status_add(
				error  => 1,
				status => 'Errored adding in include paths or writing file out(if asked)... ' . $@
			);
			return undef;
		}
	} ## end else [ if ( $self->{config}{suricata}{multi_instance...})]

	return undef;
} ## end sub action_extra

sub short {
	return 'Reels in the base Suricata config and uses it for generating the base config for each instance.';
}

sub opts_data {
	return 'i=s
w
pp
pr
pi
d=s
';
}

1;
