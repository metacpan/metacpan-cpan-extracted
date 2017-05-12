package HTML::CheckArgs::option;

use strict;
use warnings;

use base 'HTML::CheckArgs::Object';

sub is_valid {
	my $self = shift;
	
	my $value = $self->value;
	my $config = $self->config;

	$self->check_params( required => [ qw( options ) ], optional => [], cleanable => 0 );

	# no value passed in
	if ( $config->{required} && !$value ) {
		$self->error_code( 'option_00' ); # required
		$self->error_message( 'Not given.' );
		return;
	} elsif ( !$config->{required} && !$value ) {
		return 1;
	}
	
	# check if valid option
	my @options = @{ $config->{params}{options} };
	unless ( grep { $value eq $_ } @options ) {
		$self->error_code( 'option_01' ); # not valid value
		$self->error_message( 'Not a valid value.' );
		return;
	}
		
	return 1;
}

1;
