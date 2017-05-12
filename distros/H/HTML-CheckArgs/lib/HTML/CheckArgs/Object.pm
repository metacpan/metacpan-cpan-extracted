package HTML::CheckArgs::Object;

use strict;
use warnings;

use Carp qw( croak );

sub new {
	my $class = shift;
	my $config = shift;
	my $field = shift;
	my $value = shift;

	bless { config => $config, field => $field, value => $value }, $class;
}

sub field {
	my $self = shift;
	return $self->{field};
}

sub value {
	my $self = shift;
	$self->{value} = shift if @_;
	return $self->{value};
}

sub error_code {
	my $self = shift;
	$self->{error_code} = shift if @_;
	return $self->{error_code};
}

sub error_message {
	my $self = shift;
	$self->{error_message} = shift if @_;
	return $self->{error_message};
}

sub config {
	my $self = shift;
	return $self->{config};
}

sub check_params {
	my $self = shift;
	my %params = @_;

	my $config = $self->config;

	# check for unknown keys in $config
	foreach my $key ( keys %{ $config } ) {
		next if $key eq 'params' or $key eq 'noclean'; # we check these seperately
		unless ( grep { $key eq $_ } qw( as required label order private ) ) {
			croak( __PACKAGE__ . ": $key not a legal config key" );
		}
	}

	# check for required params
	foreach my $req ( @{ $params{required} } ) {
		unless ( exists $config->{params}{$req} ) {
			croak( __PACKAGE__ . ": required parameter $req not given" );
		}
	}

	# check for legal params
	foreach my $key ( keys %{ $config->{params} } ) {
		unless ( grep { $key eq $_ } @{ $params{required} }, @{ $params{optional} } ) {
			croak( __PACKAGE__ . ": $key not a legal parameter" );
		}
	}

	# check if cleanable
	unless ( $params{cleanable} ) {
		croak( __PACKAGE__ . ' does not support cleaning input' ) if exists $config->{noclean};
	}
}

sub is_valid {
	my $self = shift;

	# each subclassed module should instantiate its own
	# is_valid method

	return 1;
}

1;
