package Mail::Lite::Processor::Regexp;

use strict;
use warnings;

use Mail::Lite::Constants;
use Smart::Comments -ENV;

use Carp;


sub _get_regexpable_text {
    my $message = shift;

    my $text_type = shift;

    if ( $text_type eq 'body' ) {
	return $message->body;
    }

    if ( $text_type ne 'header' ) {
	return $message->header( $text_type );
    }

    my $text = '';

    while( my ($k, $v) = each %{ $message->headers } ) {
	$k =~ tr/-/_/;
	$text .= "$k:$v\n";
    }

    return $text;
}

sub process {
    my $args_ref = shift;
    
    my $message		= $args_ref->{input	};
    my $processor_args	= $args_ref->{processor	};

    my $extracted = {};

    my $regexps = $processor_args->{regexps};

    my $regexpables_texts;

    my @rules = keys %{ $regexps };
   REGEXP_RULE:
    foreach my $rulename ( @rules ) {

	my $rule = $regexps->{ $rulename };

	my ( $rule_var, $rule_on, $no_global ) = 
		( $rulename =~ /^([^=]+)=~([^,]+)(?:\,(once))?$/g );

	my $text  = 
	    $regexpables_texts->{ $rule_on } 
		||= _get_regexpable_text( $message, $rule_on );

	my @matched;

	# parse_rfc822 alike behaviour
	if ( $rule_var eq '$1' ) {
	    while ( $text =~ m/$rule/g ) {
		# $1 is the key $2 is value
		my ($k, $v) = ($1, $2);

		if ( exists $extracted->{ $k } ) {
		    if ( ref $extracted->{ $k } eq 'ARRAY' ) {
			push @{ $extracted->{ $k } }, $v;
		    } else {
			$extracted->{ $k } = [ $extracted->{ $k }, $v ];
		    }
		} else {
		    $extracted->{ $1 } = $2;
		}
	    }
	    next REGEXP_RULE;
	}

	if ( ref $rule eq 'ARRAY' ) {
	  REGEXPS_CHAIN:
	    foreach my $regexp (@$rule) {
		@matched = ($text =~ m/$regexp/mg);

		last REGEXPS_CHAIN unless @matched;

		$text = "@matched";
	    }
	} else {
	    if ( not $no_global ) {
		$text or confess( $rule );
		@matched = ($text =~ m/$rule/mg);
	    } else {
		@matched = ($text =~ m/$rule/m);
	    }
	}

	next REGEXP_RULE unless @matched;

	if ( @matched > 1 ) {
	    $extracted->{ $rule_var } = \@matched;
	}
	else {
	    $extracted->{ $rule_var } = $matched[0];
	}
    }

    ${ $args_ref->{ output } } = [ $extracted ];

    return OK;
}



1;
