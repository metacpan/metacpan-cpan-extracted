package Ixchel::Actions::sagan_base;

use 5.006;
use strict;
use warnings;
use File::Slurp;
use YAML::XS qw(Dump Load);
use Ixchel::functions::file_get;
use utf8;

=head1 NAME

Ixchel::Actions::sagan_base :: Generates the base config for a sagan instance.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    use Data::Dumper;

    my $results=$ixchel->action(action=>'sagan_base', opts=>{np=>1, w=>1, });

    print Dumper($results);

The following keys are removed from the file.

    .rules-files
    .processors
    .outputs

.sagan.base_config is used as the URL for the config to use and needs to be something
understood by L<Ixchel::functions::file_get>. By default
'https://raw.githubusercontent.com/quadrantsec/sagan/main/etc/sagan.yaml' is used.

.include is set to .sagan.config_base.'/sagan-include.yaml' in the case of single
instance setups if .sagan.multi_instance is set to 1 then
.sagan.config_base."/sagan-include-$instance.yaml"

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

	my $config_base = $self->{config}{sagan}{config_base};

	my $fetched_raw_yaml;
	my $yaml;
	my $have_config = 0;
	eval {
		$fetched_raw_yaml = file_get( url => $self->{config}{sagan}{base_config} );
		if ( !defined($fetched_raw_yaml) ) {
			die('file_get returned undef');
		}
		utf8::encode($fetched_raw_yaml);
		$yaml = Load($fetched_raw_yaml);
		if ( !defined($yaml) ) {
			die('Attempting to parse the returned data as YAML failed');
		}

		delete( $yaml->{'rules-files'} );
		delete( $yaml->{'processors'} );
		delete( $yaml->{'outputs'} );

		$have_config = 1;
	};
	if ($@) {
		my $error = 'Fetching ' . $self->{config}{sagan}{base_config} . ' failed... ' . $@;
		push( @{ $results->{errors} }, $error );
		$results->{status_text} = '# ' . $error . "\n";
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
				$yaml->{include} = $self->{config}{sagan}{config_base} . '/sagan-include-' . $instance . '.yaml';
				my $config_file = $self->{config}{sagan}{config_base} . '/sagan-' . $instance . '.yaml';
				my $raw_yaml;
				eval {
					$raw_yaml = '%YAML 1.1' . "\n" . Dump($yaml);

					if ( $self->{opts}{w} ) {
						write_file( $config_file, $raw_yaml );
					}

					$results->{status_text}
						= $results->{status_text}
						. '-----[ Instance '
						. $instance
						. ' ]-------------------------------------' . "\n"
						. $raw_yaml . "\n";
				};
				if ($@) {
					$results->{status_text}
						= $results->{status_text}
						. '-----[ Error: Instance '
						. $instance
						. ' ]-------------------------------------' . "\n";

					my $error = 'Writing ' . $config_file . ' failed... ' . $@;
					push( @{ $results->{errors} }, $error );
					$results->{status_text} = $results->{status_text} . '# ' . $error . "\n";
					$self->{ixchel}{errors_count}++;
				} ## end if ($@)
			} ## end foreach my $instance (@instances)
		} else {
			my $config_file = $self->{config}{sagan}{config_base} . '/sagan.yaml';
			$yaml->{include} = $self->{config}{sagan}{config_base} . '/sagan-include.yaml';
			my $raw_yaml;
			eval {
				$raw_yaml = '%YAML 1.1' . "\n" . Dump($yaml);

				if ( $self->{opts}{w} ) {
					write_file( $config_file, $raw_yaml );
				}

				$results->{status_text} = $results->{status_text} . $raw_yaml;
			};
			if ($@) {
				my $error = 'Writing ' . $config_file . ' failed... ' . $@;
				push( @{ $results->{errors} }, $error );
				$results->{status_text} = $results->{status_text} . '# ' . $error . "\n";
				$self->{ixchel}{errors_count}++;
			}
		} ## end else [ if ( $self->{config}{sagan}{multi_instance...})]
	} ## end if ($have_config)

	if ( !$self->{opts}{np} ) {
		print $results->{status_text};
	}

	if ( !defined( $results->{errors}[0] ) ) {
		$results->{ok} = 1;
	}

	return $results;
} ## end sub action

sub help {
	return 'Generates the base config for a sagan instance.

--np          Do not print the status of it.

-w            Write the generated includes out.

-i <instance> A instance to operate on.

';
} ## end sub help

sub short {
	return 'Generates the base config for a sagan instance.';
}

sub opts_data {
	return 'i=s
np
w
';
}

1;
