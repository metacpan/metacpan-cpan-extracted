package Ixchel::Actions::sys_info;

use 5.006;
use strict;
use warnings;
use Ixchel::functions::sys_info;
use TOML qw(to_toml);
use JSON qw(to_json);
use YAML::XS qw(Dump);
use Data::Dumper;

=head1 NAME

Ixchel::Actions::sys_info :: Fetches system info via Rex::Hardware and prints it in various formats.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

Fetches system info via Rex::Hardware and prints it in various formats.

=head1 Switches

=head2 -o <format>

Format to print it in.

Available: json, yaml, toml

Default: toml

=cut

sub new {
	my ( $empty, %opts ) = @_;

	my $self = { config => undef, opts => {}, ixchel=>$opts{ixchel} };
	bless $self;

	if ( defined( $opts{opts} ) ) {
		$self->{opts} = \%{ $opts{opts} };
	}

	return $self;
} ## end sub new

sub action {
	my $self = $_[0];

	if ( !defined( $self->{opts}->{o} ) ) {
		$self->{opts}->{o} = 'toml';
	}

	if (   $self->{opts}->{o} ne 'toml'
		&& $self->{opts}->{o} ne 'json'
		&& $self->{opts}->{o} ne 'dumper'
		&& $self->{opts}->{o} ne 'yaml' )
	{
		$self->{ixchel}{errors_count}++;
		die( '-o is set to "' . $self->{opts}->{o} . '" which is not a understood setting' );
	}

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
	if ( $self->{opts}->{o} eq 'toml' ) {
		$string = to_toml($sys_info) . "\n";
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

	return $string;
} ## end sub action

sub help {
	return 'Prints data from the sys_info function.

-o <format>     Format to print it in.
                Available: json, yaml, toml
                Default: toml
';
}

sub short {
	return 'Prints data from the sys_info function.';
}

sub opts_data {
	return 'o=s';
}

1;
