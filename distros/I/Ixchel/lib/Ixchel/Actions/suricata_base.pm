package Ixchel::Actions::suricata_base;

use 5.006;
use strict;
use warnings;
use File::Slurp;
use YAML::XS qw(Dump);
use Ixchel::functions::file_get;
use YAML::yq::Helper;
use File::Temp qw/ tempfile  /;

=head1 NAME

Ixchel::Actions::suricata_base :: Reels in the base Suricata config and uses it for generating the base config for each instance.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    use Data::Dumper;

    my $results=$ixchel->action(action=>'suricata_base', opts=>{np=>1, w=>1, });

    print Dumper($results);

This will fetch the file specied via .suricata.base_config in the config. This is
a URL to the config file to use, by default it is
https://raw.githubusercontent.com/OISF/suricata/master/suricata.yaml.in .

This will be fetched using proxies as defined under .proxy .

The following keys are removed.

   .logging
   .outputs
   .af-packet
   .pcap
   .include
   .rule-files

=head1 FLAGS

=head2 --np

Do not print the status of it.

=head2 -w

Write the generated services to service files.

=head2 -i instance

A instance to operate on.

=head1 RESULT HASH REF

    .errors :: A array of errors encountered.
    .status_text :: A string description of what was done and teh results.
    .ok :: Set to zero if any of the above errored.

=cut

sub new {
	my ( $empty, %opts ) = @_;

	my $self = {
		config  => {},
		vars    => {},
		arggv   => [],
		opts    => {},
		results => {
			errors => [],
			status => '',
			ok     => 0,
		},
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

	$self->{results} = {
		errors => [],
		status => '',
		ok     => 0,
	};

	my $config_base = $self->{config}{suricata}{config_base};

	my $base_config_url = $self->{config}{suricata}{base_config};

	if ( !defined($base_config_url) ) {
		$self->status_add(
			error  => 1,
			status =>
				'The config value .config.base_config is undef. It should be the value for URL to fetch it from'
		);
		return $self->{results};
	}

	my $base_config_raw;
	eval {
		if ( defined( $self->{config}{proxy}{ftp} ) && $self->{config}{proxy}{ftp} ne '' ) {
			$ENV{FTP_PROXY} = $self->{config}{proxy}{ftp};
			$self->status_add( status => 'FTP_PROXY=' . $self->{config}{proxy}{ftp} );
		}
		if ( defined( $self->{config}{proxy}{http} ) && $self->{config}{proxy}{http} ne '' ) {
			$ENV{HTTP_PROXY} = $self->{config}{proxy}{http};
			$self->status_add( status => 'HTTP_PROXY=' . $self->{config}{proxy}{http} );
		}
		if ( defined( $self->{config}{proxy}{https} ) && $self->{config}{proxy}{https} ne '' ) {
			$ENV{HTTPS_PROXY} = $self->{config}{proxy}{https};
			$self->status_add( status => 'HTTPS_PROXY=' . $self->{config}{proxy}{https} );
		}
		$self->status_add( status => 'Fetching ' . $base_config_url );
		$base_config_raw = file_get( url => $base_config_url );
	};
	if ($@) {
		$self->status_add( error => 1, status => 'Fetch Error... ' . $@ );
		return $self->{results};
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
	my @to_remove = ( '.logging.outputs', '.outputs', '.af-packet', '.pcap', '.include', '.rule-files' );
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
		return $self->{results};
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

		}
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

			$base_config_raw = read_file($tmp_file);
			if ($self->{opts}{w}) {
				write_file( $config_base . '/suricata.yaml', $base_config_raw );
			}
		};
		if ($@) {
			$self->status_add( error => 1, status => 'Errored adding in include paths or writing file out(if asked)... ' . $@ );
			return $self->{results};
		} else {
			$new_status = 'Adding .include finished';
			if ( $self->{opts}{pi} ) {
				$new_status = $new_status . "...\n" . $base_config_raw;
			}
			$self->status_add( status => $new_status );
		}
	} ## end else [ if ( $self->{config}{suricata}{multi_instance...})]

	if ( !defined( $self->{results}{errors}[0] ) ) {
		$self->{results}{ok} = 1;
	}

	return $self->{results};
} ## end sub action

sub help {
	return 'Generates the instance specific include for a suricata instance.

--np          Do not print the status of it.

-w            Write the generated includes out.

-i <instance> A instance to operate on.

-pp           Include the config in the status post initial processing.

-pr           Include the config in the status post paths removal.

-pi           Include the config in the status post adding includes.
';
} ## end sub help

sub short {
	return 'Reels in the base Suricata config and uses it for generating the base config for each instance.';
}

sub opts_data {
	return 'i=s
np
w
pp
pr
pi
';
}

sub status_add {
	my ( $self, %opts ) = @_;

	if ( !defined( $opts{status} ) ) {
		return;
	}

	if ( !defined( $opts{error} ) ) {
		$opts{error} = 0;
	}

	if ( !defined( $opts{type} ) ) {
		$opts{type} = 'suricata_base';
	}

	my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime(time);
	my $timestamp = sprintf( "%04d-%02d-%02dT%02d:%02d:%02d", $year + 1900, $mon + 1, $mday, $hour, $min, $sec );

	my $status = '[' . $timestamp . '] [' . $opts{type} . ', ' . $opts{error} . '] ' . $opts{status};

	print $status. "\n";

	$self->{results}{status} = $self->{results}{status} . $status;

	if ( $opts{error} ) {
		push( @{ $self->{results}{errors} }, $opts{status} );
	}
} ## end sub status_add

1;
