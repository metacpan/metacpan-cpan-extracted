package Ixchel::Actions::sagan_merged;

use 5.006;
use strict;
use warnings;
use File::Slurp;
use YAML::XS qw(Dump Load);
use Ixchel::functions::file_get;
use utf8;
use File::Temp qw/ tempfile tempdir /;
use File::Spec;
use YAML::yq::Helper;
use Hash::Merge;
use File::Copy;
use base 'Ixchel::Actions::base';

=head1 NAME

Ixchel::Actions::sagan_merged - Generated a merged base/include for Sagan.

=head1 VERSION

Version 0.2.0

=cut

our $VERSION = '0.2.0';

=head1 CLI SYNOPSIS

ixchel -a sagan_merged [B<--np>] [B<-w>] [B<-i> <instance>]

=head1 CODE SYNOPSIS

    use Data::Dumper;

    my $results=$ixchel->action(action=>'sagan_base', opts=>{np=>1, w=>1, });

    print Dumper($results);

=head1 DESCRIPTION

.sagan.base_config is used as the URL for the config to use and needs to be something
understood by L<Ixchel::functions::file_get>. By default
https://raw.githubusercontent.com/quadrantsec/sagan/main/etc/sagan.yaml is used.

The following arrays are blanked in the file.

    .rules-files
    .processors
    .outputs

These are removed as they are array based, making it very awkward to deal with with
having them previously defined.

A include is then generated using .sagan.config. If .sagan.multi_instance is set to 1,
then .sagan.instances.$instance is merged on top of it using L<HASH::Merge>
with RIGHT_PRECEDENT as below with arrays being replaced. This is then generated and
merged into the base file file using yq.

.include is set to .sagan.config_base.'/sagan-rules.yaml' in the case of single
instance setups if .sagan.multi_instance is set to 1 then
.sagan.config_base."/sagan-$instance-rules.yaml"

=head1 FLAGS

=head2 -w

Write out the configs.

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

	my $config_base = $self->{config}{sagan}{config_base};

	my $have_config = 0;
	my $tmpdir      = tempdir( CLEANUP => 1 );
	my $tmp_base    = $tmpdir . '/base.yaml';
	eval {
		my $fetched_raw_yaml;
		my $parsed_yaml;
		$fetched_raw_yaml = file_get( url => $self->{config}{sagan}{base_config} );
		if ( !defined($fetched_raw_yaml) ) {
			die('file_get returned undef');
		}
		utf8::encode($fetched_raw_yaml);
		$parsed_yaml = Load($fetched_raw_yaml);
		if ( !defined($parsed_yaml) ) {
			die('Attempting to parse the returned data as YAML failed');
		}

		write_file( $tmp_base, $fetched_raw_yaml );

		my $yq = YAML::yq::Helper->new( file => $tmp_base );
		$yq->delete( var => '.rules-files' );
		$yq->delete( var => '.include' );
		$yq->clear_array( var => '.outputs' );
		$yq->clear_array( var => '.processors' );

		$have_config = 1;
	};
	if ($@) {
		$self->status_add(
			status => 'Fetching and proccessing ' . $self->{config}{sagan}{base_config} . ' failed... ' . $@,
			error  => 1,
		);
		return undef;
	}

	if ($have_config) {
		if ( $self->{config}{sagan}{multi_instance} ) {
			my @instances;

			if ( defined( $self->{opts}{i} ) ) {
				@instances = ( $self->{opts}{i} );
			} else {
				@instances = keys( %{ $self->{config}{sagan}{instances} } );
			}
			foreach my $instance (@instances) {
		  # clean it up so there is less likely of a chance of some one deciding to do that by hand and borking the file
				my $include_path = File::Spec->canonpath(
					$self->{config}{sagan}{config_base} . '/sagan-' . $instance . '-rules.yaml' );

				my $instance_base = $tmpdir . '/base-' . $instance . '.yaml';

				my $config_file = $self->{config}{sagan}{config_base} . '/sagan-' . $instance . '.yaml';

				my $to_be_merged = $tmpdir . '/to_merge.yaml';

				eval {
					copy( $tmp_base, $config_file );

					my $config          = $self->{config}{sagan}{instances}{$instance};
					my $base_config     = $self->{config}{sagan}{config};
					my $merger          = Hash::Merge->new('RIGHT_PRECEDENT');
					my %tmp_config      = %{$config};
					my %tmp_base_config = %{$base_config};
					my $merged          = $merger->merge( \%tmp_base_config, \%tmp_config );
					$merged->{include} = $include_path;

					my $filled_in = '%YAML 1.1' . "\n" . Dump($merged);
					write_file( $to_be_merged, $filled_in );

					my $yq = YAML::yq::Helper->new( file => $instance_base );
					$yq->merge_yaml( yaml => $to_be_merged );

					$filled_in = read_file($instance_base);

					if ( $self->{opts}{w} ) {
						write_file( $config_file, $filled_in );
					}

					$self->status_add( status => '-----[ Instance '
							. $instance
							. ' ]-------------------------------------' . "\n"
							. $filled_in
							. "\n" );
				};
				if ($@) {
					$self->status_add(
						status => '-----[ Error: Instance '
							. $instance
							. " ]-------------------------------------\nCreating merged base/include failed... "
							. $@,
						error => 1,
					);
				}
			} ## end foreach my $instance (@instances)
		} else {
		  # clean it up so there is less likely of a chance of some one deciding to do that by hand and borking the file
			my $include_path = File::Spec->canonpath( $self->{config}{sagan}{config_base} . '/sagan-rules.yaml' );

			my $config_file = $self->{config}{sagan}{config_base} . '/sagan.yaml';

			my $to_merge = $self->{config}{sagan}{config};
			$to_merge->{include} = $include_path;
			my $to_include = '%YAML 1.1' . "\n" . Dump($to_merge);

			my $to_be_merged = $tmpdir . '/to_merge.yaml';
			write_file( $to_be_merged, $to_include );

			my $yq = YAML::yq::Helper->new( file => $tmp_base );
			$yq->merge_yaml( yaml => $to_be_merged );

			my $raw_yaml;
			eval {
				$raw_yaml = read_file($tmp_base);

				$self->status_add( status => "Base... \n" . $raw_yaml );

				if ( $self->{opts}{w} ) {
					write_file( $config_file, $raw_yaml );
				}
			};
			if ($@) {
				$self->status_add(
					status => 'Died... ' . $@,
					error  => 1,
				);

			}
		} ## end else [ if ( $self->{config}{sagan}{multi_instance...})]
	} ## end if ($have_config)

	eval { unlink($tmp_base); };
	if ($@) {
		$self->status_add(
			error  => 1,
			status => 'Unlinking "' . $tmp_base . '" failed ... ' . $@
		);
	}

	return undef;
} ## end sub action_extra

sub short {
	return 'Generated a merged base/include for Sagan.';
}

sub opts_data {
	return 'i=s
w
';
}

1;
