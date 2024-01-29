package Ixchel::Actions::dump_config;

use 5.006;
use strict;
use warnings;
use Ixchel::functions::sys_info;
use TOML::Tiny qw(to_toml);
use JSON       qw(to_json);
use YAML::XS   qw(Dump);
use Data::Dumper;
use JSON::Path;
use base 'Ixchel::Actions::base';

=head1 NAME

Ixchel::Actions::dump_config - Prints out the config.

=head1 VERSION

Version 0.2.0

=cut

our $VERSION = '0.2.0';

=head1 CLI SYNOPSIS

ixchel -a <dump_config> [B<-o> <format>] [B<-s> <section>]

=head1 CODE SYNOPSIS

    my $results=$ixchel->action(action=>'apt_proxy', opts=>{w=>1, np=>1});

    if ($results->{ok}) {
        print $results->{raw};
    }else{
        die('Action errored... '.joined("\n", @{$results->{errors}}));
    }

=head1 Switches

=head2 -o <format>

Format to print it in.

Available: json, yaml, toml, dumper

Default: yaml

=head2 -s <section>

A JSON style path used for fetching a sub section of the
config via L<JSON::Path>.

Default: undef

=head1 RESULT HASH REF

    .errors :: A array of errors encountered.
    .status_text :: A string description of what was done and the results.
    .ok :: Set to zero if any of the above errored.
    .raw :: The config in the specified format.
    .config :: The config hash.

=cut

sub new_extra { }

sub action_extra {
	my $self = $_[0];

	if ( !defined( $self->{opts}->{o} ) ) {
		$self->{opts}->{o} = 'yaml';
	}

	if (   $self->{opts}{o} ne 'toml'
		&& $self->{opts}{o} ne 'json'
		&& $self->{opts}{o} ne 'dumper'
		&& $self->{opts}{o} ne 'yaml' )
	{
		self->status_add(
			status => '-o is set to "' . $self->{opts}{o} . '" which is not a understood setting',
			error  => 1
		);
		return undef;
	} ## end if ( $self->{opts}{o} ne 'toml' && $self->...)

	my $config;
	if ( defined( $self->{opts}{s} ) ) {
		eval {
			my $jpath = JSON::Path->new( $self->{opts}{s} );
			$config = $jpath->get( $self->{config} );
		};
		if ($@) {
			$self->status_add( status => 'JSON::Path errored ... ' . $@, error => 1 );
			return undef;
		}
	} else {
		$config = $self->{config};
	}
	$self->{results}{config} = $config;

	my $string;
	if ( $self->{opts}->{o} eq 'toml' ) {
		$string = to_toml($config) . "\n";
		if ( !$self->{opts}{np} ) {
			print $string;
		}
	} elsif ( $self->{opts}->{o} eq 'json' ) {
		my $json = JSON->new;
		$json->canonical(1);
		$json->pretty(1);
		$string = $json->encode($config);
		if ( !$self->{opts}{np} ) {
			print $string;
		}
	} elsif ( $self->{opts}->{o} eq 'yaml' ) {
		$string = Dump($config);
		if ( !$self->{opts}{np} ) {
			print $string;
		}
	}

	return undef;
} ## end sub action

sub short {
	return 'Dumps the config to to JSON, YAML, or TOML(default)';
}

sub opts_data {
	return 'o=s
s=s
np
';
}

1;
