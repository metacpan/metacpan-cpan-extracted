package Mail::Lite::Processor::Chain;

use strict;
use warnings;

use Mail::Lite::Constants;
use Smart::Comments -ENV;

use Data::Dumper;


sub process {
    my $args_ref = shift;

    my $input_ref	= $args_ref->{input	};
    my $rule_ref	= $args_ref->{rule	};
    my $all_rules	= $args_ref->{rules	};

    my $rule_name	= $rule_ref->{id};

    my $processor_obj	= new Mail::Lite::Processor;

    $processor_obj->{chained} = 1;
    
    my $regexp = qr/^_$rule_name\.(.*)/;
    my @rules;
    
    foreach my $rule (@{ $all_rules }) {
	next unless $rule->{id} =~ $regexp;
	push @rules, { %$rule, id => $rule_name.'.'.$1 };
    }

    $processor_obj->{rules} = \@rules;

    #warn Dumper($processor_obj);

    my @output;

    ref $input_ref eq 'ARRAY'
	or $input_ref = [ $input_ref ];

    foreach my $message (@$input_ref) {
	my $handler_sub = sub { 
	    ### @_ 
	    my $rule_id	= shift;
	    my $result	= shift->[0];

	    my $param = {
		rule_id   => $rule_id,
	    };

	    if ( ref $result eq 'HASH' ) {
		%$param	= (%$result, %$param);
	    }
	    else {
		$param->{result} = $result;
	    }

	    push @output, $param;
	};

	$processor_obj->process(
	    message => $message,
	    handler => $handler_sub,
	);
    }

    ${ $args_ref->{ output } } = \@output;

    return ! exists $rule_ref->{last} || $rule_ref->{last} ? STOP_RULE : OK;
}



1;
