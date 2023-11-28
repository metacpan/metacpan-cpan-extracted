package Ixchel::Actions::sagan_rules;

use 5.006;
use strict;
use warnings;
use File::Slurp;
use YAML::XS   qw(Dump Load);
use List::Util qw(uniq);
use Ixchel::functions::file_get;
use File::Spec;

=head1 NAME

Ixchel::Actions::sagan_rules :: Generate the rules include for Sagan.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    use Data::Dumper;

    my $results=$ixchel->action(action=>'sagan_rules', opts=>{np=>1, w=>1, });

    print Dumper($results);

Generates the rules include for sagan using the array .sagan.rules and
if .sagan.instances_rules.$instance exists, that will be merged into it.

The resulting array is deduplicated using L<List::Util>->uniq.

Any item that does not match /\// or /\$/ has '$RULE_PATH/' prepended to it.

If told to write it out, .sagan.config_base is used as the base directory to write
to with the file name being 'sagan-rules.yaml' or in the case of multi instance
"sagan-rules-$instance.yaml"

=head1 FLAGS

=head2 --np

Do not print the status of it.

=head2 -w

Write the generated services to service files.

=head2 -i instance

A instance to operate on.

=head2 --no_die_at_end

Don't die if there are errors encounted at the end.

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

	$self->{results} = {
		errors      => [],
		status_text => '',
		ok          => 0,
	};

	my $url = 'https://raw.githubusercontent.com/quadrantsec/sagan-rules/main/rules.yaml';

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
		$self->status_add( status => 'Fetching ' . $url );
		$base_config_raw = file_get( url => $url );
	};
	if ($@) {
		$self->status_add( error => 1, status => 'Fetch Error... ' . $@ );
		return $self->{results};
	}
	$self->{base_config_raw} = $base_config_raw;

	my $base_config;
	eval { $base_config = Load($base_config_raw); };
	if ($@) {
		$self->status_add( error => 1, status => 'Decoding YAML from "' . $url . '" failed... ' . $@ );
		return $self->{results};
	}
	my @base_config_split = split( /\n/, $base_config_raw );
	$self->{base_config_split} = \@base_config_split;

	# make sure the base config looks sane
	if ( !defined( $base_config->{'rules-files'} ) ) {
		$self->status_add( error => 1, status => '.rules-files array is not present in the YAML from "' . $url . '"' );
		return $self->{results};
	} elsif ( ref( $base_config->{'rules-files'} ) ne 'ARRAY' ) {
		$self->status_add( error => 1, status => '.rules-files is not a array in the YAML from "' . $url . '"' );
		return $self->{results};
	} elsif ( !defined( $base_config->{'rules-files'}[0] ) ) {
		$self->status_add( error => 1, status => '.rules-files[0] is undef in the YAML from "' . $url . '"' );
		return $self->{results};
	}

	my $rules = {};
	foreach my $rule ( @{ $base_config->{'rules-files'} } ) {
		$rules->{$rule} = 1;
	}
	$self->{rules} = $rules;

	my $config_base = $self->{config}{sagan}{config_base};

	$self->status_add( status => 'multi_instance = ' . $self->{config}{sagan}{multi_instance} );

	if ( $self->{config}{sagan}{multi_instance} ) {
		#
		#
		#
		# multi instance
		#
		#
		#
		my @instances;

		if ( defined( $self->{opts}{i} ) ) {
			@instances = ( $self->{opts}{i} );
		} else {
			@instances = keys( %{ $self->{config}{sagan}{instances} } );
		}
		foreach my $instance (@instances) {
			my $filled_in;
			eval {
				my $file = File::Spec->canonpath( $config_base . '/sagan-' . $instance . '-rules.yaml' );
				$self->process_file( file => $file );
			};
			if ($@) {
				$self->status_add( status => $@, error => 1 );
			}

		} ## end foreach my $instance (@instances)
	} else {
		#
		#
		#
		# single
		#
		#
		#
		if ( defined( $self->{opts}{i} ) ) {
			die('-i may not be used in single instance mode, .sagan.multi_instance=1, ,');
		}

		my $file = File::Spec->canonpath( $config_base . '/sagan-rules.yaml' );

		my $filled_in;

		eval { $self->process_file( file => $file ); };
		if ($@) {
			$self->status_add( status => $@, error => 1 );
		}
	} ## end else [ if ( $self->{config}{sagan}{multi_instance...})]

	if ( !defined( $self->{results}{errors}[0] ) ) {
		$self->{results}{ok} = 1;
	}

	return $self->{results};
} ## end sub action

sub help {
	return 'Generate the rules include for Sagan.

--np          Do not print the status of it.

-w            Write the generated includes out.

-i <instance> A instance to operate on.

';
} ## end sub help

sub short {
	return 'Generate the rules include for Sagan.';
}

sub opts_data {
	return 'i=s
np
w
no_die_at_end
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
		$opts{type} = 'sagan_rules';
	}

	my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime(time);
	my $timestamp = sprintf( "%04d-%02d-%02dT%02d:%02d:%02d", $year + 1900, $mon + 1, $mday, $hour, $min, $sec );

	my $status = '[' . $timestamp . '] [' . $opts{type} . ', ' . $opts{error} . '] ' . $opts{status};

	print $status. "\n";

	$self->{results}{status_text} = $self->{results}{status_text} . $status;

	if ( $opts{error} ) {
		push( @{ $self->{results}{errors} }, $opts{status} );
	}
} ## end sub status_add

sub process_file {
	my ( $self, %opts ) = @_;

	my $file = $opts{file};
	my $filled_in;

	if ( !-f $file ) {
		$filled_in = $self->{base_config_raw};
		$self->status_add(
			status => '-----[ ' . $file . ' ]-------------------------------------' . "\n" . $filled_in );
	} else {
		# figure out what rules we have
		my $current_config;
		eval {
			my $current_config_raw = read_file($file);
			$current_config = Load($current_config_raw);
		};
		if ($@) {
			$self->status_add( status => $@, error => 1 );
			return $self->{results};
		}

		# get what rules are currently in use
		my $current_rules = {};
		foreach my $rule ( @{ $current_config->{'rules-files'} } ) {
			$current_rules->{$rule} = 1;
		}

		# get a list of custom rules
		my $custom_rules = {};
		foreach my $rule ( keys( %{$current_rules} ) ) {
			if ( !defined( $self->{rules}->{$rule} ) ) {
				$custom_rules->{$rule} = 1;
			}
		}
		my $custom_rules_array = keys( %{$custom_rules} );

		# begin putting it back together
		$filled_in = '';
		my $start = 1;
		foreach my $line ( @{ $self->{base_config_split} } ) {
			my $ignore_line = 0;

			if ( $line =~ /^ *\#/ ) {
				$ignore_line = 1;
			} elsif ( !$start && $line =~ /^rules\-files\:/ ) {
				$start       = 1;
				$ignore_line = 1;
			}    # post start ignore anything that is not a rule line
			elsif ( $start && $line !~ /^\ \ \-\ \$RULE\_PATH/ ) {
				$ignore_line = 1;
			}

			if ($ignore_line) {
				$filled_in = $filled_in . $line . "\n";
			} else {
				# get the rule name
				my $rule = $line;
				$rule =~ s/^\ \ \-\ //;

				# should never be there, but just in case perform some basic cleanup
				$rule =~ s/ *\#.*//;
				$rule =~ s/ *$//;

				# if it is not in the current rule set, comment it out
				if ( !defined( $current_rules->{$rule} ) ) {
					$filled_in = $filled_in . '  #- ' . $rule . "\n";
				} else {
					$filled_in = $filled_in . $line . "\n";
				}
			} ## end else [ if ($ignore_line) ]
		} ## end foreach my $line ( @{ $self->{base_config_split...}})

		$self->status_add(
			status => '-----[ ' . $file . ' ]-------------------------------------' . "\n" . $filled_in );

	} ## end else [ if ( !-f $file ) ]

	if ( $self->{opts}{w} ) {
		$self->status_add( status => 'Writing out to "' . $file . '" ...' );
		write_file( $file, $filled_in );
	}

	return $filled_in;
} ## end sub process_file

1;
