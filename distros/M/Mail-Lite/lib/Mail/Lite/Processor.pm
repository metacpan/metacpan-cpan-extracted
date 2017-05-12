#===============================================================================
#
#         FILE:  Processor.pm
#
#  DESCRIPTION:  Processor -- processor based on rules chain
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Pavel Boldin (), <davinchi@cpan.org>
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  14.09.2008 14:27:25 MSD
#     REVISION:  ---
#===============================================================================

package Mail::Lite::Processor;

use strict;
use warnings;

use UNIVERSAL::require;
use Mail::Lite::Constants;

use Clone qw/clone/;

use Smart::Comments -ENV;

use Mail::Lite::Message;


my $_processors_cache;

sub new {
    my $self = shift;

    $self = bless {}, $self;
    $self->_init( @_ );

    return $self;
}

sub _init {
    my $self = shift;
    my %param = @_;

    $self->{rules} = $param{rules} || [];
    $self->{handler} = $param{handler};
    $self->{debug} = $param{debug};

    if ( @{ $self->{rules} } ) {
	my @common_rules = grep { $_->{id} =~ m/^_common\./ }
				@{ $self->{rules} };

	# for debuggin -- if there some missing common rules
	my %common_rules = map { $_->{id} => $_ } @common_rules;
	$self->{common_rules} = \%common_rules;
	$self->_replace_common_rules;
    }

    #use Data::Dumper;
    #die Dumper $self->{rules};
}

sub _replace_common_rules {
    my $self	     = shift;

    my $common_rules = $self->{common_rules };
    my $rules	     = $self->{rules	    };

    foreach my $rule (@$rules) {
	if ( not exists $rule->{match} ) {
	    next;
	}

	$self->_replace_common_rules_in_hash(
	    \$rule->{match},
	);
    }
}

sub _replace_common_rules_in_hash {
    my $self = shift;
    my $ref = shift;

    if ( ref $ref eq 'REF' ) {
	$ref = $$ref;
    }

    if ( ref $ref eq 'ARRAY' ) {
	$self->_replace_common_rules_in_hash( \$_ ) foreach @$ref;
    }
    elsif ( ref $ref eq 'HASH' ) {
	$self->_replace_common_rules_in_hash( \$_ ) foreach values %$ref;
    } 
    elsif ( ref $ref eq 'SCALAR' ) {
	if ( ${ $ref } && ${ $ref } =~ m/^_common\./ ) {
	    my $common_rule_name = ${ $ref };

	    if ( ! exists $self->{common_rules}{ $common_rule_name } ) {
		die "Cannot find common rule $common_rule_name";
	    }

	    ${ $ref } = $self->{common_rules}{ $common_rule_name }->{ match };
	    ${ $ref }
		or die "Cannot find match hash in $common_rule_name";
	}
    }
    else {
	die "Unknown reference type given ", ref $ref;
    }
}


# Process message
# INS: $self, %param
# %param: message, handler, rules
sub process {
    my ($self, %param) = @_;

    if ( not ref $self ) {
	$self = $self->new( %param );
    }
    
    my $message = ((ref $param{message}) =~ /::/)
	? $param{message} # Это уже объект
	: Mail::Lite::Message->new( $param{message} ); # Ещё не объект

    # Ok, make that probaby, we should use some caching there
    $self->_process_by_rule_chain( $message, $param{handler} );
}

# Check if message match some rule
# IN: message (Mail::Lite::Message object), handler, recursive
sub _process_by_rule_chain {
    my ($self, $message, $handler, $recursive) = @_;

    $handler ||= $self->{handler};

    my @rules = grep { not $_->{id} =~ /^_/; } @{ $self->{rules} };

    @rules = sort { 
	($a->{weight} || 0) <=> ($b->{weight} || 0) 
    } @rules;

    RULE:
    foreach my $rule ( @rules ) {
	### $rule
	my $processors = $rule->{processors};

	unless ( $processors ) {
	    $processors = [
		{
		    processor => 'Stub',
		}
	    ]
	    #die "no processors given for $rule->{id}";
	}

	my $match_processor = {
	    processor => 'match',
	    match_rules => $rule->{match}
	};

	my $input = $message;
	my $output;

	PROCESSOR:
	foreach my $processor ($match_processor, @$processors) {

	    $input  = defined $output ? $output : $input;

	    my $processor_sub = 
		    _get_processor_method( $processor->{processor} );

	    my $result = $processor_sub->(
		{
		    processor	=> $processor	 ,
		    input	=> $input	 ,
		    output	=> \$output	 ,
		    rule	=> $rule	 ,
		    rules	=> $self->{rules},
		}
	    );

	    if ( OK eq $result ) {
		next PROCESSOR;
	    } 
	    elsif ( STOP eq $result ) {
		last PROCESSOR;
	    }
	    elsif ( NEXT_RULE eq $result ) {
		next RULE;
	    }
	    elsif ( STOP_RULE eq $result ) {
		$handler->( $rule->{id}, $output );
		last RULE;
	    }
	    elsif ( ERROR eq $result ) {
		die "ERROR in $rule->{id}'s $processor->{processor}";
	    }

	}

	# ok, call handler
	$handler->( $rule->{id}, $output );
    }
}


sub _get_processor_method {
    my $processor = shift;

    return $processor if ref $processor eq 'CODE';

    if ( exists $_processors_cache->{ $processor } ) {
	return $_processors_cache->{ $processor };
    }

    unless ( $processor =~ s/^\+// ) {
	no strict 'refs';

	my $pkgname = join '', map { ucfirst $_ } split /[_ ]/, $processor;

	$pkgname = 'Mail::Lite::Processor::'.$pkgname;

	if ( not $pkgname->require ) {
	    die "cannot find processors $processor: $@";
	}
	        
	my $c = $pkgname->can('process')
	    or die "cannot use processor $processor";

	return $_processors_cache->{ $processor } = $c;
    }

    die "not yet implemented";
}

1;
