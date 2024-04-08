package Ixchel::Actions::sys_info;

use 5.006;
use strict;
use warnings;
use Ixchel::functions::sys_info;
use JSON     qw(to_json);
use YAML::XS qw(Dump);
use Data::Dumper;
use base 'Ixchel::Actions::base';

=head1 NAME

Ixchel::Actions::sys_info - Fetches system info via Rex::Hardware and prints it in various formats.

=head1 VERSION

Version 0.3.0

=cut

our $VERSION = '0.3.0';

=head1 CLI SYNOPSIS

ixchel -a sys_info [B<-o> <format>]

=head1 CODE SYNOPSIS

Fetches system info via Rex::Hardware and prints it in various formats.

=head1 Switches

=head2 -o <format>

Format to print it in.

Available: json, yaml, toml, dumper

Default: toml

=cut

sub new_extra { }

sub action_extra {
	my $self = $_[0];

	if ( !defined( $self->{opts}->{o} ) ) {
		$self->{opts}->{o} = 'toml';
	}

	if (   $self->{opts}->{o} ne 'toml'
		&& $self->{opts}->{o} ne 'json'
		&& $self->{opts}->{o} ne 'dumper'
		&& $self->{opts}->{o} ne 'yaml' )
	{
		$self->status_add(
			status => '-o is set to "' . $self->{opts}->{o} . '" which is not a understood setting',
			error  => 1,
		);
		return undef;
	} ## end if ( $self->{opts}->{o} ne 'toml' && $self...)

	my $sys_info = sys_info;

	my @net_ifs = keys( %{ $sys_info->{Network}{networkconfiguration} } );
	foreach my $net_if (@net_ifs) {
		my @net_if_args = keys( %{ $sys_info->{Network}{networkconfiguration}{$net_if} } );
		foreach my $net_if_arg (@net_if_args) {
			if ( !defined( $sys_info->{Network}{networkconfiguration}{$net_if}{$net_if_arg} ) ) {
				$sys_info->{Network}{networkconfiguration}{$net_if}{$net_if_arg} = '';
			}
		}
	}

	my $string;
	eval {
		if ( $self->{opts}->{o} eq 'toml' ) {
			my $to_eval = 'use TOML::Tiny qw(to_toml); $string = to_toml($sys_info) . "\n";';
			eval($to_eval);
			print $string;
		} elsif ( $self->{opts}->{o} eq 'json' ) {
			my $json = JSON->new;
			$json->canonical(1);
			$json->pretty(1);
			$string = $json->encode($sys_info);
			print $string;
		} elsif ( $self->{opts}->{o} eq 'yaml' ) {
			$string = Dump($sys_info);
			print $string;
		}
	};
	if ($@) {
		$self->status_add(
			error  => 1,
			status => $@,
		);
	} else {
		$self->{results}{status_text} = $string;
	}

	return undef;
} ## end sub action_extra

sub short {
	return 'Prints data from the sys_info function.';
}

sub opts_data {
	return 'o=s';
}

1;
