package Ixchel::Actions::sagan_base;

use 5.006;
use strict;
use warnings;
use File::Slurp;
use YAML::XS qw(Dump Load);
use Ixchel::functions::file_get;
use utf8;
use File::Temp qw/ tempfile tempdir /;
use File::Spec;
use base 'Ixchel::Actions::base';

=head1 NAME

Ixchel::Actions::sagan_base - Generates the base config for a sagan instance.

=head1 VERSION

Version 0.2.0

=cut

our $VERSION = '0.2.0';

=head1 CLI SYNOPSIS

ixchel -a sagan_base [B<-w>] [B<-i> <instance>]

=head1 CODE SYNOPSIS

    use Data::Dumper;

    my $results=$ixchel->action(action=>'sagan_base', opts=>{np=>1, w=>1, });

    print Dumper($results);

=head1 DESCRIPTION

The following keys are removed from the file.

    .rules-files
    .processors
    .outputs

These are removed as they are array based, making it very awkward to deal with with having
them previously defined.

.sagan.base_config is used as the URL for the config to use and needs to be something
understood by L<Ixchel::functions::file_get>. By default
https://raw.githubusercontent.com/quadrantsec/sagan/main/etc/sagan.yaml is used.

.include is set to .sagan.config_base.'/sagan-include.yaml' in the case of single
instance setups if .sagan.multi_instance is set to 1 then
.sagan.config_base."/sagan-include-$instance.yaml"

=head1 FLAGS

=head2 -w

Write the generated services to service files.

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
	my ( $tmp_fh, $tmp_file ) = tempfile();
	eval {
		my $fetched_raw_yaml;
		my $parsed_yaml;
		$fetched_raw_yaml = file_get( url => $self->{config}{sagan}{base_config} );
		if ( !defined($fetched_raw_yaml) ) {
			$self->status_add( error => 1, status_add => 'file_get returned undef' );
			return undef;
		}
		utf8::encode($fetched_raw_yaml);
		$parsed_yaml = Load($fetched_raw_yaml);
		if ( !defined($parsed_yaml) ) {
			$self->status_add( error => 1, status_add => 'Attempting to parse the returned data as YAML failed' );
			return undef;
		}

		eval { write_file( $tmp_file, $fetched_raw_yaml ); };
		if ($@) {
			$self->status_add(
				error      => 1,
				status_add => 'Failed to write out tmp file to "' . $tmp_file . '" ...'
			);
			return undef;
		}

		# removes array based items that are problematic to deal with
		my $output = `yq -i  'del(.rules-files)' $tmp_file 2>&1`;
		if ( $? ne 0 ) {
			$self->status_add(
				error      => 1,
				status_add => 'Fetched YAML saved to "'
					. $tmp_file
					. '" and could not be parsed by yq to delete .rules-files ... '
					. $output
			);
			return undef;
		} ## end if ( $? ne 0 )
		$output = `yq -i 'del(.outputs)' $tmp_file 2>&1`;
		if ( $? ne 0 ) {
			$self->status_add(
				error      => 1,
				status_add => 'Fetched YAML saved to "'
					. $tmp_file
					. '" and could not be parsed by yq to delete .outputs ... '
					. $output
			);
			return undef;
		} ## end if ( $? ne 0 )
		$output = `yq -i 'del(.processors)' $tmp_file`;
		if ( $? ne 0 ) {
			$self->status_add(
				error      => 1,
				status_add => 'Fetched YAML saved to "'
					. $tmp_file
					. '" and could not be parsed by yq to delete .processors ... '
					. $output
			);
			return undef;
		} ## end if ( $? ne 0 )

		$have_config = 1;
	};
	if ($@) {
		$self->status_add(
			error      => 1,
			status_add => 'Fetching ' . $self->{config}{sagan}{base_config} . ' failed... ' . $@
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
					$self->{config}{sagan}{config_base} . '/sagan-include-' . $instance . '.yaml' );

				system( 'yq', '-i', '.include="' . $include_path . '"', $tmp_file );

				my $config_file = $self->{config}{sagan}{config_base} . '/sagan-' . $instance . '.yaml';
				my $raw_yaml;
				eval {

					$raw_yaml = read_file($tmp_file);

					if ( $self->{opts}{w} ) {
						write_file( $config_file, $raw_yaml );
					}

					$self->status_add( status_add => '-----[ Instance '
							. $instance
							. ' ]-------------------------------------' . "\n"
							. $raw_yaml
							. "\n" );
				};
				if ($@) {
					$self->status_add(
						error      => 1,
						status_add => '-----[ Error: Instance '
							. $instance
							. ' ]-------------------------------------'
							. "\nWriting "
							. $config_file
							. ' failed... '
							. $@
					);
				} ## end if ($@)
			} ## end foreach my $instance (@instances)
		} else {
		  # clean it up so there is less likely of a chance of some one deciding to do that by hand and borking the file
			my $include_path = File::Spec->canonpath( $self->{config}{sagan}{config_base} . '/sagan-include.yaml' );

			system( 'yq', '-i', '.include="' . $include_path . '"', $tmp_file );

			my $config_file = $self->{config}{sagan}{config_base} . '/sagan.yaml';

			my $raw_yaml;
			eval {
				$raw_yaml = read_file($tmp_file);

				if ( $self->{opts}{w} ) {
					write_file( $config_file, $raw_yaml );
				}

				$self->status_add(
					status_add => "\n" . $raw_yaml

				);
			};
			if ($@) {
				$self->status_add(
					status_add => 'Writing ' . $config_file . ' failed... ' . $@,
					error      => 1,
				);
			}
		} ## end else [ if ( $self->{config}{sagan}{multi_instance...})]
	} ## end if ($have_config)

	eval { unlink($tmp_file); };
	$self->status_add(
		status_add => 'Unlinkg tmp file, "' . $tmp_file . '" failed ... ' . $@,
		error      => 1,
	);

	return undef;
} ## end sub action_extra

sub short {
	return 'Generates the base config for a sagan instance.';
}

sub opts_data {
	return 'i=s
w
';
}

1;
