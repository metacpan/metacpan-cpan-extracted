package Ixchel::Actions::dump_config;

use 5.006;
use strict;
use warnings;
use Ixchel::functions::sys_info;
use TOML qw(to_toml);
use JSON qw(to_json);
use YAML::XS qw(Dump);
use Data::Dumper;
use JSON::Path;

=head1 NAME

Ixchel::Actions::sys_info :: Prints out the config.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    $ixchel->action(action=>'dump_config', opts=>{ o=>'toml' });

Prints out the config.

=head1 Switches

=head2 -o <format>

Format to print it in.

Available: json, yaml, toml

Default: toml

=head2 -s <section>

A JSON style path used for fetching a sub section of the
config via L<JSON::Path>.

Default: undef

=cut

sub new {
	my ( $empty, %opts ) = @_;



	if (!defined($opts{config})) {
		die('$opts{config} is undef');
	}

	my $self = { config => $opts{config}, opts => {}, ixchel=>$opts{ixchel} };
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
		die( '-o is set to "' . $self->{opts}->{o} . '" which is not a understood setting' );
		$self->{ixchel}{errors_count}++;
	}

	my $config;
	if (defined($self->{opts}{s})) {
		my $jpath   = JSON::Path->new($self->{opts}{s});
		$config=$jpath->get($self->{config});
	}else {
		$config=$self->{config};
	}

	my $string;
	if ( $self->{opts}->{o} eq 'toml' ) {
		$string = to_toml( $config ) . "\n";
		print $string;
	} elsif ( $self->{opts}->{o} eq 'json' ) {
		my $json = JSON->new;
		$json->canonical(1);
		$json->pretty(1);
		$string = $json->encode($config);
		print $string;
	} elsif ( $self->{opts}->{o} eq 'yaml' ) {
		$string = Dump($config);
		print $string;
	}

	return $string;
} ## end sub action

sub help {
	return 'Prints data from the sys_info function.

-o <format>     Format to print it in.
                Available: json, yaml, toml
                Default: toml

-s <section>    A JSON Path style variable used for selecting a sub
                section of the config to return.
';
}

sub short {
	return 'Dumps the config to to JSON, YAML, or TOML(default)';
}

sub opts_data {
	return 'o=s
s=s';
}

1;
