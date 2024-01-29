package Ixchel::Actions::suricata_diff;

use 5.006;
use strict;
use warnings;
use File::Temp qw/ tempfile tempdir /;
use File::Copy;
use YAML::yq::Helper;
use base 'Ixchel::Actions::base';

=head1 NAME

Ixchel::Actions::suricata_diff - Finds the differences between the Ixchel config and current Suricata config.

=head1 VERSION

Version 0.2.0

=cut

our $VERSION = '0.2.0';

=head1 CLI SYNOPSIS

ixchel -a suricata_diff [B<-i> <instance>]

=head1 CODE SYNOPSIS

    use Data::Dumper;

    my $results=$ixchel->action(action=>'suricata_diff', opts=>{np=>1, });

    print Dumper($results);

=head1 DESCRIPTION


=head1 FLAGS

=head2 -i instance

A instance to operate on.

=head1 RESULT HASH REF

    .errors :: A array of errors encountered.
    .status_text :: A string description of what was done and teh results.
    .ok :: Set to zero if any of the above errored.

=cut

sub new_extra { }

sub action_extra {
	my $self = $_[0];

	if ( $self->{config}{suricata}{multi_instance} ) {
		my @instances;

		if ( defined( $self->{opts}{i} ) ) {
			@instances = ( $self->{opts}{i} );
		} else {
			@instances = keys( %{ $self->{config}{suricata}{instances} } );
		}
		foreach my $instance (@instances) {
			eval { $self->process_config( instance => $instance ); };
			if ($@) {
				$self->status_add(
					status => 'Proccessing instance "' . $instance . '" failed ... ' . $@,
					error  => 1
				);
			}
		}
	} else {
		if ( defined( $self->{opts}{i} ) ) {
			$self->status_add(
				status => '-i may not be used in single instance mode, .suricata.multi_instance=1',
				error  => 1
			);
		}

		$self->process_config;
	} ## end else [ if ( $self->{config}{suricata}{multi_instance...})]

	return undef;
} ## end sub action_extra

sub short {
	return 'Finds the differences between the Ixchel config and current Suricata config.';
}

sub opts_data {
	return 'i=s
w
';
}

sub process_config {
	my ( $self, %opts ) = @_;

	my $config_base = $self->{config}{suricata}{config_base};

	my $temp_dir = tempdir( CLEANUP => 1 );

	my $new_dir = $temp_dir . '/new_yamls';

	mkdir($new_dir);

	my $instance_status = '';
	my $instance_part   = '';
	my $instance_part2  = '';
	if ( defined( $opts{instance} ) ) {
		$instance_part   = '-' . $opts{instance};
		$instance_part2  = $opts{instance} . '-';
		$instance_status = 'instance="' . $opts{instance} . '"... ';
	}

	my $old_config_base    = $config_base . '/suricata' . $instance_part . '.yaml';
	my $old_config_include = $config_base . '/' . $instance_part2 . 'include.yaml';
	my $old_config_outputs = $config_base . '/' . $instance_part2 . 'outputs.yaml';

	my $new_config_base    = $new_dir . '/suricata' . $instance_part . '.yaml';
	my $new_config_include = $new_dir . '/' . $instance_part2 . 'include.yaml';
	my $new_config_outputs = $new_dir . '/' . $instance_part2 . 'outputs.yaml';

	if ( !-f $old_config_base ) {
		$self->status_add( status => $instance_part . ' old config base,"' . $old_config_base . '", does exist' );
		return;
	}

	copy( $old_config_base, $temp_dir . '/old.yaml' );
	if ( -f $old_config_include ) {
		copy( $old_config_include, $temp_dir . '/old-include.yaml' );
	}
	if ( -f $old_config_outputs ) {
		copy( $old_config_outputs, $temp_dir . '/old-outputs.yaml' );
	}

	my $yq = YAML::yq::Helper->new( file => $temp_dir . '/old.yaml' );
	if ( -f $temp_dir . '/old-include.yaml' ) {
		$yq->merge_yaml( yaml => $temp_dir . '/old-include.yaml' );
	}
	if ( -f $temp_dir . '/old-outputs.yaml' ) {
		$yq->merge_yaml( yaml => $temp_dir . '/old-outputs.yaml' );
	}
	$yq->delete( var => '.outputs' );
	$yq->delete( var => '.include' );

	my $results = $self->{ixchel}
		->action( action => 'suricata_base', opts => { np => 1, w => 1, i => $opts{instance}, d => $new_dir } );
	$results = $self->{ixchel}
		->action( action => 'suricata_include', opts => { np => 1, w => 1, i => $opts{instance}, d => $new_dir } );
	$results = $self->{ixchel}
		->action( action => 'suricata_outputs', opts => { np => 1, w => 1, i => $opts{instance}, d => $new_dir } );

	my $new_yq = YAML::yq::Helper->new( file => $new_config_base );
	$new_yq->merge_yaml( yaml => $new_config_include );
	$new_yq->merge_yaml( yaml => $new_config_outputs );
	$new_yq->delete( var => '.outputs' );
	$new_yq->delete( var => '.include' );

	move( $new_config_base, $temp_dir . '/new.yaml' );

	my $diff = $yq->yaml_diff( yaml => $temp_dir . '/new.yaml' );

	$self->status_add( status => $instance_part . " diff... \n" . $diff );

	return;
} ## end sub process_config

1;
