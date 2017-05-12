package HTML::CheckArgs::string;

use strict;
use warnings;

use base 'HTML::CheckArgs::Object';
use HTML::FormatData;

sub is_valid {
	my $self = shift;
	
	my $value = $self->value;
	my $config = $self->config;

	# a subset of the jobs available in HTML::FormatData
	# it makes no sense to call one of these routines and do 'noclean'
	my @jobs = qw(
		strip_html strip_whitespace
		clean_high_ascii clean_encoded_html clean_encoded_text
		clean_whitespace clean_whitespace_keep_full_breaks clean_whitespace_keep_all_breaks
		force_lc force_uc
		truncate truncate_with_ellipses
	);
	
	$self->check_params( 
		required => [], 
		optional => [ @jobs, qw( regex min_chars max_chars min_words max_words ) ], 
		cleanable => 1 );
	
	# format text based on params
	my %format_jobs;
	my $do_format = 0;

	foreach my $job ( @jobs ) {
		if ( $config->{params}{$job} ) {
			$do_format = 1;
			$format_jobs{$job} = $config->{params}{$job};
		}
	}

	$value = HTML::FormatData->new->format_text( $value, %format_jobs ) if $do_format;
	
	# no value passed in
	if ( $config->{required} && !$value ) {
		$self->error_code( 'string_00' ); # required
		$self->error_message( 'Not given.' );
		return;
	} elsif ( !$config->{required} && !$value ) {
		$self->value( $value );
		return 1;
	}

	if ( $config->{params}{regex} ) {
		my $pat = $config->{params}{regex};
		if ( $value !~ m/$pat/ ) {
			$self->error_code( 'string_01' ); # not match regex
			$self->error_message( 'Does not match expected pattern.');
			return;
		}
	}
	
	my ( $min_chars, $max_chars, $min_words, $max_words );
	$min_chars = $config->{params}{min_chars};
	$max_chars = $config->{params}{max_chars};
	$min_words = $config->{params}{min_words};
	$max_words = $config->{params}{max_words};

	if ( $min_chars && ( length( $value ) < $min_chars ) ) {
		$self->error_code( 'string_02' ); # under min chars
		$self->error_message( "Less than the minimum required length ($min_chars characters)." );
		return;
	}

	if ( $max_chars && ( length( $value ) > $max_chars ) ) {
		$self->error_code( 'string_03' ); # over max chars
		$self->error_message( "Exceeds the maximum allowable length ($max_chars characters)." );
		return;
	}

	if ( $min_words ) {
		my @words = split( /\s+/, $value );
		if ( scalar( @words ) < $min_words ) {
			$self->error_code( 'string_04' ); # under min words
			$self->error_message( "Less than the minimum number of words ($min_words)." );
			return;
		}
	}

	if ( $max_words ) {
		my @words = split( /\s+/, $value );
		if ( scalar( @words ) > $max_words ) {
			$self->error_code( 'string_05' ); # over max words
			$self->error_message( "More than the maximum number of words ($max_words)." );
			return;
		}
	}

	# return cleaned value (the 2-letter abbr)?
	unless ( $config->{noclean} ) {
		$self->value( $value );
	}
	
	return 1;
}

1;
