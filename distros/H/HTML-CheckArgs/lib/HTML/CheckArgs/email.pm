package HTML::CheckArgs::email;

use strict;
use warnings;

use base 'HTML::CheckArgs::Object';
use Email::Valid;

sub is_valid {
	my $self = shift;
	
	my $value = $self->value;
	my $config = $self->config;

	$self->check_params( 
		required  => [], 
		optional  => [ qw( no_admin_addr no_gov_addr banned_domains ) ], 
		cleanable => 1,
	);

	# no value passed in
	if ( $config->{required} && !$value ) {
		$self->error_code( 'email_00' ); # required
		$self->error_message( 'Not given.' );
		return;
	} elsif ( !$config->{required} && !$value ) {
		return 1;
	}

	# clean for validation
	$value = lc $value;
	$value =~ s/\s+//g; # rid of white space

	if ( !Email::Valid->address( $value ) ) {
		$self->error_code( 'email_01' ); # not valid
		$self->error_message( 'Not valid.' );
		return;
	}
	
	# sanity check on length
	# not sure if it is strictly illegal to have addresses this long
	if ( length( $value ) > 255 ) {
		$self->error_code( 'email_02' ); # over max length
		$self->error_message( 'Exceeds the maximum allowable length (255 characters).' );
		return;
	}

	# check params
	# legal ones are: no_admin_addr, no_gov_addr, banned_domains
	if ( $config->{params}{no_admin_addr} ) {
		if ( $value =~ m/(^root@|^webmaster@|^postmaster@|^listmaster@|^hostmaster@|^abuse@)/ ) {
			$self->error_code( 'email_03' ); # admin address
			$self->error_message( 'System administrator addresses are prohibited; please use a personal address.' );
			return;
		}
	}
			
	if ( $config->{params}{no_gov_addr} ) {
		if ( $value =~ m/\.gov$/ ) {
			$self->error_code( 'email_04' ); # gov address
			$self->error_message( 'Government addresses are prohibited; please use a personal address.' );
			return;
		}
	}
			
	if ( exists $config->{params}{banned_domains} ) {
		if ( grep { $value =~ m/$_$/ } @{ $config->{params}{banned_domains} } ) {
			$self->error_code( 'email_05' ); # banned domains
			$self->error_message( 'Addresses from this domain are prohibited.' );
			return;
		}
	}
	
	# send back cleaned up value?
	unless ( $config->{noclean} ) {
		$self->value( $value );
	}
	
	return 1;
}

1;
