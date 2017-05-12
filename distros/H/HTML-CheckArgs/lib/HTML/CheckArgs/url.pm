package HTML::CheckArgs::url;

use strict;
use warnings;

use base 'HTML::CheckArgs::Object';
use URI::Find;
use LWP::UserAgent;

sub is_valid {
	my $self = shift;
	
	my $value = $self->value;
	my $config = $self->config;

	$self->check_params( required => [], optional => [ qw( verify max_chars ) ], cleanable => 0 );

	# no value passed in
	if ( $config->{required} && !$value ) {
		$self->error_code( 'url_00' ); # required
		$self->error_message( 'Not given.' );
		return;
	} elsif ( !$config->{required} && !$value ) {
		return 1;
	}

	my @urls;
	my $url = $value; ### find_uris modifies $value
	unless ( find_uris( $url, sub { push @urls, shift } ) ) {
		$self->error_code( 'url_01' ); # not valid
		$self->error_message( 'Not valid.' );
		return;
	}

	# check params
	if ( $config->{params}{verify} ) {
		my $ua = LWP::UserAgent->new;
		my $response = $ua->get( $value );
		if ( $response->is_error ) {
			$self->error_code( 'url_02' ); # not reachable
			$self->error_message( 'Not accessible.' );
			return;
		}
	}

	# check length if db field limits are an issue
	my $max_chars = $config->{params}{max_chars};
	if ( $max_chars && ( length( $value ) > $max_chars ) ) {
		$self->error_code( 'url_03' ); # over max chars
		$self->error_message( "Exceeds the maximum allowable length ($max_chars characters)." );
		return;
	}

	return 1;
}

1;
