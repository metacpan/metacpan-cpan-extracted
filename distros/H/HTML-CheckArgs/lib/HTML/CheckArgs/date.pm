package HTML::CheckArgs::date;

use strict;
use warnings;

use base 'HTML::CheckArgs::Object';
use HTML::FormatData;

sub is_valid {
	my $self = shift;
	
	my $value = $self->value;
	my $config = $self->config;

	$self->check_params( required => [ 'format' ], optional => [ 'regex' ], cleanable => 0 );

	# no value passed in
	if ( $config->{required} && !$value ) {
		$self->error_code( 'date_00' ); # required
		$self->error_message( 'Not given.' );
		return;
	} elsif ( !$config->{required} && !$value ) {
		return 1;
	}

	my $f = HTML::FormatData->new;
	unless ( $f->parse_date( $value, $config->{params}{format} ) ) {
		$self->error_code( 'date_01' ); # not valid
		$self->error_message( 'Not a valid date.' );
		return;
	}

	# DateTime doesn't do strict parsing, so unfortunately
	# we need this extra (and not backwards compatible) hack.
	if ( $config->{params}{regex} ) {
		my $pat = $config->{params}{regex};
		if ( $value !~ m/$pat/ ) {
			$self->error_code( 'date_02' ); # not match regex
			$self->error_message( 'Not a valid date.');
			return;
		}
	}
	
	return 1;
}

1;
