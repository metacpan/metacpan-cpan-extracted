package Log::Saftpresse::Config;

use Moose;

# ABSTRACT: configuration option parser for Log::Saftpresse
our $VERSION = '1.6'; # VERSION

use Tie::IxHash;
use Config::General qw(ParseConfig);

sub ordered_hash_ref {
	tie my %hash, 'Tie::IxHash', @_;
	return \%hash;
}

has 'defaults' => (
	is => 'rw', lazy => 1,
	default => sub {
		tie my %defaults, "Tie::IxHash";
		%defaults = (
			'counters' => {
				'flush_interval' => '0',
			},
			'logging' => {
				level => 'INFO',
				file => undef, # log to syslog
			},
			Input => ordered_hash_ref(
				stdin => {
					module => 'Stdin',
				},
			),
			Plugin => ordered_hash_ref(
				syslog => {
					module => 'SyslogFile',
				},
			),
			CounterOutput => ordered_hash_ref (
				dump_counters => {
					module => 'Dump',
				},
			),
			Output => ordered_hash_ref (
				dump_json => {
					module => 'JSON',
				},
			),
		);
		return \%defaults;
	},
);

has 'config' => ( is => 'rw' );

sub load_config {
	my ( $self, $file ) = @_;
	if( ! -f $file ) {
		die('configuration file '.$file.' does not exist!');
	}

	tie my %config_hash, "Tie::IxHash";
	%config_hash = ParseConfig(
		-AllowMultiOptions => 'no',
		-ConfigFile => $file,
		-Tie => "Tie::IxHash"
	);
	$self->config( \%config_hash );

	return;
}

sub _get_hash_node {
	my $hash = shift;
	my @path = @_;
	my $cur = $hash;

	if( ! defined $hash ) { return; }

	while( my $element = shift @path ) {
		if( defined $cur->{$element}
	       			&& ref $cur->{$element} eq 'HASH' ) {
			$cur = $cur->{$element};
		} else { return; }
	}

	return $cur;
}

sub _get_hash_value {
	my $hash = shift;
	my $key = pop;
	my @path = @_;

	my $cur = _get_hash_node( $hash, @path );

	if( defined $cur
			&& defined $cur->{$key}
			&& ! ref($cur->{$key}) ) {
		return $cur->{$key};
	}
	return;
}

sub get_node {
	my $self = shift;
	my $node;
	if( $node = _get_hash_node( $self->config, @_ ) ) {
		return $node;
	}
	if( $node = _get_hash_node( $self->defaults, @_ ) ) {
		return $node;
	}
	return;
}

sub get {
	my $self = shift;
	my $value;

	if( $value = _get_hash_value( $self->config, @_ ) ) {
		return $value;
	}
	if( $value = _get_hash_value( $self->defaults, @_ ) ) {
		return $value;
	}
	return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Saftpresse::Config - configuration option parser for Log::Saftpresse

=head1 VERSION

version 1.6

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 1998 by James S. Seymour, 2015 by Markus Benning.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
